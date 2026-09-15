package service

import (
	"context"
	"errors"
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/internal/repository"
	"github.com/gornaya-salanga/backend/internal/sms"
	"github.com/rs/zerolog/log"
)

type UDSError struct {
	Code    string
	Message string
}

func (e *UDSError) Error() string {
	if e == nil {
		return ""
	}
	return e.Code + ": " + e.Message
}

func udsErr(code, message string) *UDSError {
	return &UDSError{Code: code, Message: message}
}

type UDSService struct {
	bonus *repository.BonusRepository
	users *repository.UserRepository
	uds   *repository.UDSRepository
	auth  *AuthService
	cfg   *config.Config
}

func NewUDSService(
	bonus *repository.BonusRepository,
	users *repository.UserRepository,
	uds *repository.UDSRepository,
	auth *AuthService,
	cfg *config.Config,
) *UDSService {
	return &UDSService{bonus: bonus, users: users, uds: uds, auth: auth, cfg: cfg}
}

type UDSReceipt struct {
	Total             float64 `json:"total"`
	Cash              float64 `json:"cash"`
	Points            float64 `json:"points"`
	Number            string  `json:"number"`
	SkipLoyaltyTotal  float64 `json:"skipLoyaltyTotal"`
	UnredeemableTotal float64 `json:"unredeemableTotal"`
}

type UDSParticipantRef struct {
	UID   string `json:"uid"`
	Phone string `json:"phone"`
}

type UDSCashier struct {
	ExternalID string `json:"externalId"`
	Name       string `json:"name"`
}

type UDSOperationRequest struct {
	Code        string             `json:"code"`
	Participant *UDSParticipantRef `json:"participant"`
	Nonce       string             `json:"nonce"`
	Cashier     *UDSCashier        `json:"cashier"`
	Receipt     UDSReceipt         `json:"receipt"`
}

type PurchaseCalc struct {
	MaxPoints           float64 `json:"maxPoints"`
	Total               float64 `json:"total"`
	SkipLoyaltyTotal    float64 `json:"skipLoyaltyTotal"`
	UnredeemableTotal   float64 `json:"unredeemableTotal"`
	DiscountAmount      float64 `json:"discountAmount"`
	DiscountPercent     float64 `json:"discountPercent"`
	Points              float64 `json:"points"`
	PointsPercent       float64 `json:"pointsPercent"`
	NetDiscount         float64 `json:"netDiscount"`
	NetDiscountPercent  float64 `json:"netDiscountPercent"`
	CertificatePoints   float64 `json:"certificatePoints"`
	Cash                float64 `json:"cash"`
	CashTotal           float64 `json:"cashTotal"`
	CashBack            float64 `json:"cashBack"`
	MaxScoresDiscount   float64 `json:"maxScoresDiscount"`
}

func roundMoney(v float64) float64 {
	return math.Round(v*100) / 100
}

func floorMoney(v float64) float64 {
	return math.Floor(v*100+1e-9) / 100
}

func CalcUDSPurchase(total, skipLoyalty, unredeemable, points, balance, earnPct, maxSpendPct, minReceipt float64) PurchaseCalc {
	total = roundMoney(total)
	skipLoyalty = roundMoney(skipLoyalty)
	unredeemable = roundMoney(unredeemable)
	points = floorMoney(points)
	if points < 0 {
		points = 0
	}

	redeemableBase := roundMoney(math.Max(0, total-unredeemable))
	maxByPercent := floorMoney(redeemableBase * maxSpendPct / 100)
	maxPoints := floorMoney(math.Min(balance, maxByPercent))
	if maxPoints < 0 {
		maxPoints = 0
	}
	if points > maxPoints {
		points = maxPoints
	}

	cash := roundMoney(total - points)
	if cash < 0 {
		cash = 0
		points = total
	}

	cashbackBase := roundMoney(math.Max(0, total-skipLoyalty-points))
	cashBack := 0.0
	if total >= minReceipt && earnPct > 0 && cashbackBase > 0 {
		cashBack = roundMoney(cashbackBase * earnPct / 100)
	}

	pointsPercent := 0.0
	if total > 0 {
		pointsPercent = roundMoney(points / total * 100)
	}
	netDiscountPercent := pointsPercent

	return PurchaseCalc{
		MaxPoints:          maxPoints,
		Total:              total,
		SkipLoyaltyTotal:   skipLoyalty,
		UnredeemableTotal:  unredeemable,
		DiscountAmount:     0,
		DiscountPercent:    0,
		Points:             points,
		PointsPercent:      pointsPercent,
		NetDiscount:        points,
		NetDiscountPercent: netDiscountPercent,
		CertificatePoints:  0,
		Cash:               cash,
		CashTotal:          cash,
		CashBack:           cashBack,
		MaxScoresDiscount:  maxSpendPct,
	}
}

func (s *UDSService) Settings(ctx context.Context, system string) (map[string]any, error) {
	cfg, err := s.bonus.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	rate := s.bonus.EarnPercentage(system, cfg)
	companyID, _ := strconv.Atoi(s.cfg.UDSCompanyID)
	if companyID == 0 {
		companyID = 1
	}
	return map[string]any{
		"id":                 companyID,
		"name":               "Горная Саланга",
		"promoCode":          nil,
		"currency":           "RUB",
		"baseDiscountPolicy": "CHARGE_SCORES",
		"loyaltyProgramSettings": map[string]any{
			"baseMembershipTier": map[string]any{
				"uid":               "base",
				"name":              "Базовый",
				"rate":              rate,
				"maxScoresDiscount": cfg.MaxSpendPercentage,
			},
			"membershipTiers":       []any{},
			"referralCashbackRates": []float64{},
			"cashierAward":          0,
			"referralReward":        0,
			"receiptLimit":          0,
			"deferPointsForDays":    0,
			"firstPurchasePoints":   0,
		},
		"purchaseByPhone": true,
		"usePointsByPhone": true,
		"writeInvoice":    false,
		"slug":            "gornaya-salanga",
	}, nil
}

func (s *UDSService) Find(ctx context.Context, system, code, phone, uid string, total, skipLoyalty, unredeemable float64) (map[string]any, error) {
	user, viaCode, err := s.resolveCustomer(ctx, code, phone, uid)
	if err != nil {
		return nil, err
	}
	purchase, userJSON, err := s.customerPurchase(ctx, system, user, total, skipLoyalty, unredeemable, 0)
	if err != nil {
		return nil, err
	}
	findType := "PHONE"
	if viaCode {
		findType = "PURCHASE"
	} else if strings.TrimSpace(uid) != "" {
		findType = "UID"
	}
	return map[string]any{
		"user":     userJSON,
		"code":     nil,
		"type":     findType,
		"purchase": purchase,
	}, nil
}

func (s *UDSService) GetCustomer(ctx context.Context, system string, participantID int64) (map[string]any, error) {
	userID, err := s.uds.UserIDByParticipant(ctx, participantID)
	if err != nil {
		return nil, udsErr("notFound", "customer not found")
	}
	user, err := s.users.GetByID(ctx, userID)
	if err != nil {
		return nil, udsErr("notFound", "customer not found")
	}
	_, userJSON, err := s.customerPurchase(ctx, system, user, 0, 0, 0, 0)
	if err != nil {
		return nil, err
	}
	return userJSON, nil
}

func (s *UDSService) Calc(ctx context.Context, system string, req *UDSOperationRequest) (map[string]any, error) {
	user, _, err := s.resolveFromRequest(ctx, req)
	if err != nil {
		return nil, err
	}
	purchase, userJSON, err := s.customerPurchase(ctx, system, user, req.Receipt.Total, req.Receipt.SkipLoyaltyTotal, req.Receipt.UnredeemableTotal, req.Receipt.Points)
	if err != nil {
		return nil, err
	}
	return map[string]any{"user": userJSON, "purchase": purchase}, nil
}

func (s *UDSService) Create(ctx context.Context, system string, req *UDSOperationRequest) (map[string]any, error) {
	if req == nil {
		return nil, udsErr("badRequest", "invalid request")
	}
	if req.Nonce != "" {
		if existing, err := s.uds.GetOperationByNonce(ctx, req.Nonce); err == nil {
			return s.operationJSON(ctx, existing)
		}
	}

	user, viaCode, err := s.resolveFromRequest(ctx, req)
	if err != nil {
		return nil, err
	}
	if user.Blocked {
		return nil, udsErr("participantIsBlocked", "customer is blocked")
	}

	cfg, err := s.bonus.GetConfig(ctx)
	if err != nil {
		return nil, err
	}
	account, err := s.ensureAccount(ctx, user.ID)
	if err != nil {
		return nil, err
	}

	earnPct := s.bonus.EarnPercentage(system, cfg)
	wanted := floorMoney(req.Receipt.Points)
	if wanted > 0 && !viaCode {
		// Phone/UID may spend because usePointsByPhone is enabled.
	}

	calc := CalcUDSPurchase(
		req.Receipt.Total, req.Receipt.SkipLoyaltyTotal, req.Receipt.UnredeemableTotal,
		wanted, account.Balance, earnPct, cfg.MaxSpendPercentage, cfg.MinReceiptAmount,
	)
	if wanted > account.Balance+0.001 {
		return nil, udsErr("insufficientFunds", "not enough bonus points")
	}
	if wanted > calc.MaxPoints+0.001 {
		return nil, udsErr("discountLimitExceed", "points exceed allowed share of the receipt")
	}

	expectedCash := roundMoney(req.Receipt.Total - wanted)
	if req.Receipt.Cash != 0 && math.Abs(roundMoney(req.Receipt.Cash)-expectedCash) > 0.011 {
		return nil, udsErr("invalidChecksum", "cash, points and total do not match")
	}

	orderID := strings.TrimSpace(req.Receipt.Number)
	if orderID == "" {
		orderID = strings.TrimSpace(req.Nonce)
	}
	if orderID == "" {
		orderID = fmt.Sprintf("uds-%d", time.Now().UnixNano())
	}

	var spendTxID, earnTxID *string
	if wanted > 0 {
		tx, err := s.bonus.Spend(ctx, user.ID, wanted, system, orderID, "UDS purchase spend")
		if err != nil {
			if strings.Contains(err.Error(), "insufficient") {
				return nil, udsErr("insufficientFunds", "not enough bonus points")
			}
			return nil, err
		}
		spendTxID = &tx.ID
	}
	if calc.CashBack > 0 {
		tx, err := s.bonus.Earn(ctx, user.ID, calc.CashBack, system, orderID, "UDS purchase cashback")
		if err != nil {
			if wanted > 0 {
				_, _ = s.bonus.Earn(ctx, user.ID, wanted, system, orderID, "UDS rollback spend")
			}
			return nil, err
		}
		earnTxID = &tx.ID
	}

	op := &repository.UDSOperation{
		UserID:        user.ID,
		System:        system,
		Nonce:         strings.TrimSpace(req.Nonce),
		Action:        "PURCHASE",
		State:         "NORMAL",
		Total:         roundMoney(req.Receipt.Total),
		Cash:          expectedCash,
		Points:        wanted,
		Cashback:      calc.CashBack,
		ReceiptNumber: strings.TrimSpace(req.Receipt.Number),
		EarnTxID:      earnTxID,
		SpendTxID:     spendTxID,
	}
	created, err := s.uds.CreateOperation(ctx, op)
	if err != nil {
		return nil, err
	}
	log.Info().Int64("udsOp", created.ID).Str("userId", user.ID).Str("system", system).Msg("uds purchase")
	return s.operationJSON(ctx, created)
}

func (s *UDSService) GetOperation(ctx context.Context, id int64) (map[string]any, error) {
	op, err := s.uds.GetOperation(ctx, id)
	if err != nil {
		return nil, udsErr("notFound", "operation not found")
	}
	return s.operationJSON(ctx, op)
}

func (s *UDSService) ListOperations(ctx context.Context, max, offset int) (map[string]any, error) {
	items, total, err := s.uds.ListOperations(ctx, max, offset)
	if err != nil {
		return nil, err
	}
	rows := make([]map[string]any, 0, len(items))
	for i := range items {
		row, err := s.operationJSON(ctx, &items[i])
		if err != nil {
			return nil, err
		}
		rows = append(rows, row)
	}
	return map[string]any{"rows": rows, "cursor": nil, "total": total}, nil
}

func (s *UDSService) Refund(ctx context.Context, id int64, partialAmount *float64) (map[string]any, error) {
	op, err := s.uds.GetOperation(ctx, id)
	if err != nil {
		return nil, udsErr("notFound", "operation not found")
	}
	if op.State == "REVERSAL" {
		return s.operationJSON(ctx, op)
	}
	if op.Action != "PURCHASE" {
		return nil, udsErr("badRequest", "only purchases can be refunded")
	}
	if partialAmount != nil && *partialAmount > 0 && math.Abs(*partialAmount-op.Total) > 0.011 {
		return nil, udsErr("badRequest", "partial refund is not supported")
	}

	orderID := op.ReceiptNumber
	if orderID == "" {
		orderID = fmt.Sprintf("uds-refund-%d", op.ID)
	}
	if op.Cashback > 0 {
		if _, err := s.bonus.Spend(ctx, op.UserID, op.Cashback, op.System, orderID, "UDS refund cashback"); err != nil {
			return nil, udsErr("insufficientFunds", "cannot reverse accrued points")
		}
	}
	if op.Points > 0 {
		if _, err := s.bonus.Earn(ctx, op.UserID, op.Points, op.System, orderID, "UDS refund restore"); err != nil {
			return nil, err
		}
	}
	if err := s.uds.UpdateOperationState(ctx, op.ID, "REVERSAL"); err != nil {
		return nil, err
	}
	op.State = "REVERSAL"
	return s.operationJSON(ctx, op)
}

func (s *UDSService) resolveFromRequest(ctx context.Context, req *UDSOperationRequest) (*model.User, bool, error) {
	if req == nil {
		return nil, false, udsErr("badRequest", "invalid request")
	}
	code := strings.TrimSpace(req.Code)
	uid, phone := "", ""
	if req.Participant != nil {
		uid = strings.TrimSpace(req.Participant.UID)
		phone = strings.TrimSpace(req.Participant.Phone)
	}
	return s.resolveCustomer(ctx, code, phone, uid)
}

func (s *UDSService) resolveCustomer(ctx context.Context, code, phone, uid string) (*model.User, bool, error) {
	code = strings.TrimSpace(code)
	phone = strings.TrimSpace(phone)
	uid = strings.TrimSpace(uid)

	n := 0
	if code != "" {
		n++
	}
	if phone != "" {
		n++
	}
	if uid != "" {
		n++
	}
	if n == 0 {
		return nil, false, udsErr("badRequest", "code, phone or uid is required")
	}
	if n > 1 {
		return nil, false, udsErr("badRequest", "only one of code, phone or uid must be set")
	}

	if code != "" {
		user, err := s.userFromCode(ctx, code)
		if err != nil {
			return nil, true, err
		}
		return user, true, nil
	}
	if uid != "" {
		user, err := s.users.GetByID(ctx, uid)
		if err != nil {
			return nil, false, udsErr("notFound", "customer not found")
		}
		return user, false, nil
	}

	user, err := s.users.FindByPhone(ctx, phone)
	if err != nil {
		return nil, false, udsErr("notFound", "customer not found")
	}
	return user, false, nil
}

func (s *UDSService) userFromCode(ctx context.Context, code string) (*model.User, error) {
	if s.auth != nil {
		if qr, err := s.auth.VerifyQR(ctx, code); err == nil && qr != nil {
			user, err := s.users.GetByID(ctx, qr.UserID)
			if err != nil {
				return nil, udsErr("notFound", "customer not found")
			}
			return user, nil
		}
	}
	if _, err := sms.FormatPhoneE164(code); err == nil {
		user, err := s.users.FindByPhone(ctx, code)
		if err != nil {
			return nil, udsErr("notFound", "customer not found")
		}
		return user, nil
	}
	if len(code) == 36 {
		user, err := s.users.GetByID(ctx, code)
		if err != nil {
			return nil, udsErr("notFound", "customer not found")
		}
		return user, nil
	}
	return nil, udsErr("notFound", "customer not found")
}

func (s *UDSService) ensureAccount(ctx context.Context, userID string) (*model.BonusAccount, error) {
	account, err := s.bonus.GetAccount(ctx, userID)
	if err == nil {
		return account, nil
	}
	if !errors.Is(err, repository.ErrNotFound) {
		return nil, err
	}
	if err := s.bonus.CreateAccount(ctx, userID); err != nil {
		return nil, err
	}
	return s.bonus.GetAccount(ctx, userID)
}

func (s *UDSService) customerPurchase(ctx context.Context, system string, user *model.User, total, skipLoyalty, unredeemable, points float64) (PurchaseCalc, map[string]any, error) {
	if user.Blocked {
		return PurchaseCalc{}, nil, udsErr("participantIsBlocked", "customer is blocked")
	}
	cfg, err := s.bonus.GetConfig(ctx)
	if err != nil {
		return PurchaseCalc{}, nil, err
	}
	account, err := s.ensureAccount(ctx, user.ID)
	if err != nil {
		return PurchaseCalc{}, nil, err
	}
	participantID, err := s.uds.GetOrCreateParticipant(ctx, user.ID)
	if err != nil {
		return PurchaseCalc{}, nil, err
	}
	earnPct := s.bonus.EarnPercentage(system, cfg)
	calc := CalcUDSPurchase(total, skipLoyalty, unredeemable, points, account.Balance, earnPct, cfg.MaxSpendPercentage, cfg.MinReceiptAmount)
	display := strings.TrimSpace(user.FirstName + " " + user.LastName)
	userJSON := map[string]any{
		"uid":         user.ID,
		"displayName": display,
		"gender":      nil,
		"phone":       user.Phone,
		"participant": map[string]any{
			"id":                 participantID,
			"points":             account.Balance,
			"discountRate":       0,
			"cashbackRate":       earnPct,
			"cashSpent":          0,
			"membershipTier":     map[string]any{"uid": "base", "name": "Базовый", "rate": earnPct, "maxScoresDiscount": cfg.MaxSpendPercentage},
			"dateCreated":        user.CreatedAt.UTC().Format("2006-01-02T15:04:05.000Z"),
			"lastTransactionTime": nil,
		},
		"tags": []any{},
	}
	return calc, userJSON, nil
}

func (s *UDSService) operationJSON(ctx context.Context, op *repository.UDSOperation) (map[string]any, error) {
	user, err := s.users.GetByID(ctx, op.UserID)
	if err != nil {
		user = &model.User{ID: op.UserID, FirstName: "Гость"}
	}
	participantID, _ := s.uds.GetOrCreateParticipant(ctx, op.UserID)
	cfg, _ := s.bonus.GetConfig(ctx)
	rate := 0.0
	if cfg != nil {
		rate = s.bonus.EarnPercentage(op.System, cfg)
	}
	netPoints := roundMoney(op.Cashback - op.Points)
	body := map[string]any{
		"id":          op.ID,
		"dateCreated": op.CreatedAt.UTC().Format("2006-01-02T15:04:05.000Z"),
		"action":      op.Action,
		"state":       op.State,
		"customer": map[string]any{
			"id":          participantID,
			"uid":         user.ID,
			"displayName": strings.TrimSpace(user.FirstName + " " + user.LastName),
			"membershipTier": map[string]any{
				"uid":  "base",
				"name": "Базовый",
				"rate": rate,
			},
		},
		"cashier":           nil,
		"branch":            nil,
		"points":            netPoints,
		"certificatePoints": 0,
		"cash":              op.Cash,
		"total":             op.Total,
		"receiptNumber":     nilIfEmpty(op.ReceiptNumber),
		"origin":            nil,
	}
	if op.OriginID != nil {
		body["origin"] = map[string]any{"id": *op.OriginID}
	}
	return body, nil
}

func nilIfEmpty(s string) any {
	if s == "" {
		return nil
	}
	return s
}
