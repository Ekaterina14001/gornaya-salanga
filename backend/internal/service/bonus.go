package service



import (

	"context"

	"fmt"

	"strings"



	"github.com/gornaya-salanga/backend/internal/config"

	"github.com/gornaya-salanga/backend/internal/model"

	"github.com/gornaya-salanga/backend/internal/repository"

	"github.com/rs/zerolog/log"

)



type BonusService struct {

	bonus *repository.BonusRepository

	users *repository.UserRepository

	cfg   *config.Config

}



func NewBonusService(bonus *repository.BonusRepository, users *repository.UserRepository, cfg *config.Config) *BonusService {

	return &BonusService{bonus: bonus, users: users, cfg: cfg}

}



func (s *BonusService) GetBalance(ctx context.Context, userID string) (*model.BonusAccount, error) {

	return s.bonus.GetAccount(ctx, userID)

}



func (s *BonusService) GetHistory(ctx context.Context, userID, txType string, page, pageSize int) (*model.PaginatedResponse, error) {

	items, total, err := s.bonus.ListHistory(ctx, userID, txType, page, pageSize)

	if err != nil {

		return nil, err

	}

	result := repository.Paginate(items, total, page, pageSize)

	return &result, nil

}



func (s *BonusService) Earn(ctx context.Context, req *model.BonusEarnRequest, system string) (*model.BonusTransaction, error) {

	if err := s.validateUser(ctx, req.UserID); err != nil {

		return nil, err

	}

	if system != "" && req.Source != "" && !strings.EqualFold(system, req.Source) {

		return nil, fmt.Errorf("source mismatch with API key system")

	}

	cfg, err := s.bonus.GetConfig(ctx)

	if err != nil {

		return nil, err

	}

	if req.PurchaseAmount < cfg.MinReceiptAmount {

		return nil, fmt.Errorf("purchase below minimum receipt amount")

	}

	pct := s.bonus.EarnPercentage(req.Source, cfg)

	amount := s.bonus.CalcEarnAmount(req.PurchaseAmount, pct)

	tx, err := s.bonus.Earn(ctx, req.UserID, amount, req.Source, req.OrderID, req.Description)

	if err != nil {

		return nil, err

	}

	log.Info().

		Str("userId", req.UserID).

		Str("type", "earn").

		Float64("amount", amount).

		Str("source", req.Source).

		Str("system", system).

		Msg("bonus operation")

	return tx, nil

}



func (s *BonusService) Spend(ctx context.Context, req *model.BonusSpendRequest, system string) (*model.BonusTransaction, error) {

	if err := s.validateUser(ctx, req.UserID); err != nil {

		return nil, err

	}

	if system != "" && req.Source != "" && !strings.EqualFold(system, req.Source) {

		return nil, fmt.Errorf("source mismatch with API key system")

	}

	cfg, err := s.bonus.GetConfig(ctx)

	if err != nil {

		return nil, err

	}

	maxSpend := req.PurchaseAmount * cfg.MaxSpendPercentage / 100

	if req.Amount > maxSpend {

		return nil, fmt.Errorf("amount exceeds max spend percentage")

	}

	tx, err := s.bonus.Spend(ctx, req.UserID, req.Amount, req.Source, req.OrderID, req.Description)

	if err != nil {

		return nil, err

	}

	log.Info().

		Str("userId", req.UserID).

		Str("type", "spend").

		Float64("amount", req.Amount).

		Str("source", req.Source).

		Str("system", system).

		Msg("bonus operation")

	return tx, nil

}



func (s *BonusService) validateUser(ctx context.Context, userID string) error {

	user, err := s.users.GetByID(ctx, userID)

	if err != nil {

		return fmt.Errorf("user not found")

	}

	if user.Blocked {

		return fmt.Errorf("user is blocked")

	}

	return nil

}


