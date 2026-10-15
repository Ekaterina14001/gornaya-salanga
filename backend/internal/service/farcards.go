package service

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/internal/repository"
	"github.com/jackc/pgx/v5"
	"github.com/rs/zerolog/log"
)

const farCardsSystem = "RKeeper"

type FarCardsService struct {
	bonus *repository.BonusRepository
	users *repository.UserRepository
	uds   *repository.UDSRepository
	auth  *AuthService
	fc    *repository.FarCardsRepository
}

func NewFarCardsService(
	bonus *repository.BonusRepository,
	users *repository.UserRepository,
	uds *repository.UDSRepository,
	auth *AuthService,
	fc *repository.FarCardsRepository,
) *FarCardsService {
	return &FarCardsService{bonus: bonus, users: users, uds: uds, auth: auth, fc: fc}
}

func (s *FarCardsService) ResolveCardCode(ctx context.Context, cardRaw string) (participantID int64, user *model.User, err error) {
	participantID, ok := parseCardInt64(cardRaw)
	if !ok || participantID <= 0 {
		return 0, nil, pgx.ErrNoRows
	}
	userID, err := s.uds.UserIDByParticipant(ctx, participantID)
	if err != nil {
		return 0, nil, err
	}
	user, err = s.users.GetByID(ctx, userID)
	if err != nil {
		return 0, nil, err
	}
	return participantID, user, nil
}

func (s *FarCardsService) FindByQRToken(ctx context.Context, qrToken string) (participantID int64, holder string, err error) {
	qrToken = strings.TrimSpace(qrToken)
	if qrToken == "" {
		return 0, "", pgx.ErrNoRows
	}
	parsed, err := s.auth.VerifyQR(ctx, qrToken)
	if err != nil {
		return 0, "", pgx.ErrNoRows
	}
	user, err := s.users.GetByID(ctx, parsed.UserID)
	if err != nil {
		return 0, "", err
	}
	if user.Blocked {
		return 0, "", pgx.ErrNoRows
	}
	participantID, err = s.uds.GetOrCreateParticipant(ctx, user.ID)
	if err != nil {
		return 0, "", err
	}
	return participantID, displayName(user), nil
}

func (s *FarCardsService) GetCardInfoXML(ctx context.Context, body []byte) (string, error) {
	cardRaw, _, _, err := parseGetCardInfoRequest(body)
	if err != nil {
		return buildGetCardInfoResponse(0, "", 0, 0, true), nil
	}
	participantID, user, err := s.ResolveCardCode(ctx, cardRaw)
	if err != nil {
		return buildGetCardInfoResponse(0, "", 0, 0, true), nil
	}
	if user.Blocked {
		return buildGetCardInfoResponse(0, "", 0, 0, true), nil
	}
	maxPay, balance, err := s.cardLimits(ctx, user.ID, 0)
	if err != nil {
		return buildGetCardInfoResponse(0, "", 0, 0, true), nil
	}
	return buildGetCardInfoResponse(participantID, displayName(user), rublesToKopecks(maxPay), rublesToKopecks(balance), false), nil
}

func (s *FarCardsService) FindByQRXML(ctx context.Context, body []byte) (string, error) {
	kind, text, err := parseFindByQRRequest(body)
	if err != nil || kind != "3" {
		return buildFindByQRResponse(0, "", true), nil
	}
	participantID, holder, err := s.FindByQRToken(ctx, text)
	if err != nil {
		return buildFindByQRResponse(0, "", true), nil
	}
	return buildFindByQRResponse(participantID, holder, false), nil
}

func (s *FarCardsService) TransactionsXML(ctx context.Context, body []byte) (string, error) {
	items, err := parseTransactionsRequest(body)
	if err != nil || len(items) == 0 {
		return buildTransactionsResponse(false, "invalid request"), nil
	}

	cardRaw := strings.TrimSpace(items[0].Card)
	if cardRaw == "" {
		cardRaw = strings.TrimSpace(items[0].Account)
	}
	participantID, user, err := s.ResolveCardCode(ctx, cardRaw)
	if err != nil {
		return buildTransactionsResponse(false, "card not found"), nil
	}
	if user.Blocked {
		return buildTransactionsResponse(false, "card blocked"), nil
	}

	restaurant := strings.TrimSpace(items[0].Restaurant)
	rkUnit := strings.TrimSpace(items[0].RKUnit)
	rkCheck := strings.TrimSpace(items[0].RKCheck)
	if restaurant == "" {
		restaurant = "0"
	}
	if rkUnit == "" {
		rkUnit = "0"
	}
	if rkCheck == "" {
		rkCheck = fmt.Sprintf("fc-%d", participantID)
	}

	if existing, err := s.fc.GetReceipt(ctx, restaurant, rkUnit, rkCheck, participantID); err == nil && existing != nil {
		return buildTransactionsResponse(true, ""), nil
	}

	var spendRub, earnRub, cashRub float64
	for _, tx := range items {
		summa, _ := strconv.ParseInt(strings.TrimSpace(tx.Summa), 10, 64)
		kind := parseKindAttr(tx.Kind)
		switch farCardsTxKind(kind, summa) {
		case "spend":
			spendRub += kopecksToRubles(-abs64(summa))
		case "earn":
			earnRub += kopecksToRubles(abs64(summa))
		case "cash":
			cashRub += kopecksToRubles(abs64(summa))
		}
	}

	orderID := fmt.Sprintf("rk-%s-%s-%s", restaurant, rkUnit, rkCheck)
	cfg, err := s.bonus.GetConfig(ctx)
	if err != nil {
		return buildTransactionsResponse(false, "config error"), err
	}
	earnPct := s.bonus.EarnPercentage(farCardsSystem, cfg)

	if spendRub > 0 {
		if _, err := s.bonus.Spend(ctx, user.ID, spendRub, farCardsSystem, orderID, "FarCards spend"); err != nil {
			log.Warn().Err(err).Str("userId", user.ID).Msg("farcards spend")
			return buildTransactionsResponse(false, "insufficient bonus balance"), nil
		}
	}

	if earnRub <= 0 && cashRub > 0 && earnPct > 0 {
		earnRub = roundMoney(cashRub * earnPct / 100)
	}
	if earnRub > 0 {
		if _, err := s.bonus.Earn(ctx, user.ID, earnRub, farCardsSystem, orderID, "FarCards earn"); err != nil {
			log.Warn().Err(err).Str("userId", user.ID).Msg("farcards earn")
			return buildTransactionsResponse(false, "earn failed"), nil
		}
	}

	_ = s.fc.SaveReceipt(ctx, &repository.FarCardsReceipt{
		Restaurant:   restaurant,
		RKUnit:       rkUnit,
		RKCheck:      rkCheck,
		CardCode:     participantID,
		PointsSpent:  spendRub,
		PointsEarned: earnRub,
	})

	return buildTransactionsResponse(true, ""), nil
}

func (s *FarCardsService) cardLimits(ctx context.Context, userID string, receiptTotal float64) (maxPay, balance float64, err error) {
	account, err := s.bonus.GetAccount(ctx, userID)
	if err != nil {
		return 0, 0, err
	}
	cfg, err := s.bonus.GetConfig(ctx)
	if err != nil {
		return 0, 0, err
	}
	balance = account.Balance
	if receiptTotal <= 0 {
		receiptTotal = cfg.MinReceiptAmount * 10
		if receiptTotal < 1000 {
			receiptTotal = 1000
		}
	}
	calc := CalcUDSPurchase(receiptTotal, 0, 0, 0, account.Balance, 0, cfg.MaxSpendPercentage, cfg.MinReceiptAmount)
	return calc.MaxPoints, balance, nil
}

func displayName(u *model.User) string {
	if u == nil {
		return ""
	}
	name := strings.TrimSpace(u.FirstName + " " + u.LastName)
	if name == "" {
		return u.Phone
	}
	return name
}

func abs64(v int64) int64 {
	if v < 0 {
		return -v
	}
	return v
}
