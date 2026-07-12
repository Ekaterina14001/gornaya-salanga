package repository

import (
	"context"
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type BonusRepository struct {
	pool *pgxpool.Pool
}

func NewBonusRepository(pool *pgxpool.Pool) *BonusRepository {
	return &BonusRepository{pool: pool}
}

func (r *BonusRepository) CreateAccount(ctx context.Context, userID string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `INSERT INTO bonus_accounts (user_id) VALUES ($1) ON CONFLICT DO NOTHING`, userID)
	return err
}

func (r *BonusRepository) GetAccount(ctx context.Context, userID string) (*model.BonusAccount, error) {
	if r.pool == nil {
		return &model.BonusAccount{
			ID: "mock", UserID: userID, Balance: 1500, TotalEarned: 3000, TotalSpent: 1500, UpdatedAt: time.Now(),
		}, nil
	}
	var a model.BonusAccount
	err := r.pool.QueryRow(ctx, `
		SELECT id, user_id, balance, total_earned, total_spent, updated_at
		FROM bonus_accounts WHERE user_id = $1
	`, userID).Scan(&a.ID, &a.UserID, &a.Balance, &a.TotalEarned, &a.TotalSpent, &a.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &a, nil
}

func (r *BonusRepository) GetConfig(ctx context.Context) (*model.BonusConfig, error) {
	if r.pool == nil {
		return defaultBonusConfig(), nil
	}
	var c model.BonusConfig
	err := r.pool.QueryRow(ctx, `
		SELECT earn_percentage_global, earn_percentage_shelter, earn_percentage_bars, earn_percentage_rkeeper,
		       max_spend_percentage, bonus_expiry_days, min_receipt_amount, qr_ttl_seconds
		FROM bonus_config LIMIT 1
	`).Scan(&c.EarnPercentageGlobal, &c.EarnPercentageShelter, &c.EarnPercentageBars, &c.EarnPercentageRKeeper,
		&c.MaxSpendPercentage, &c.BonusExpiryDays, &c.MinReceiptAmount, &c.QRTTLSeconds)
	if err != nil {
		return defaultBonusConfig(), err
	}
	return &c, nil
}

func (r *BonusRepository) UpdateConfig(ctx context.Context, c *model.BonusConfig) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE bonus_config SET
			earn_percentage_global = $1, earn_percentage_shelter = $2, earn_percentage_bars = $3,
			earn_percentage_rkeeper = $4, max_spend_percentage = $5, bonus_expiry_days = $6,
			min_receipt_amount = $7, qr_ttl_seconds = $8, updated_at = NOW()
	`, c.EarnPercentageGlobal, c.EarnPercentageShelter, c.EarnPercentageBars, c.EarnPercentageRKeeper,
		c.MaxSpendPercentage, c.BonusExpiryDays, c.MinReceiptAmount, c.QRTTLSeconds)
	return err
}

func (r *BonusRepository) InsertConfigAudit(ctx context.Context, adminID string, changes map[string]any) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `INSERT INTO bonus_config_audit (admin_id, changes) VALUES ($1, $2)`, adminID, changes)
	return err
}

func (r *BonusRepository) ListConfigAudit(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{}, nil
	}
	rows, err := r.pool.Query(ctx, `SELECT id, admin_id, changes, created_at FROM bonus_config_audit ORDER BY created_at DESC LIMIT 50`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []map[string]any
	for rows.Next() {
		var id, adminID string
		var changes map[string]any
		var createdAt time.Time
		if err := rows.Scan(&id, &adminID, &changes, &createdAt); err != nil {
			return nil, err
		}
		items = append(items, map[string]any{"id": id, "adminId": adminID, "changes": changes, "createdAt": createdAt})
	}
	return items, rows.Err()
}

func (r *BonusRepository) Earn(ctx context.Context, userID string, amount float64, source, orderID, description string) (*model.BonusTransaction, error) {
	if r.pool == nil {
		return mockTx(userID, "earn", amount, source), nil
	}
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	id := uuid.NewString()
	_, err = tx.Exec(ctx, `
		INSERT INTO bonus_transactions (id, user_id, type, amount, source, order_id, description)
		VALUES ($1, $2, 'earn', $3, $4, $5, $6)
	`, id, userID, amount, source, orderID, description)
	if err != nil {
		return nil, err
	}
	_, err = tx.Exec(ctx, `
		UPDATE bonus_accounts SET balance = balance + $2, total_earned = total_earned + $2, updated_at = NOW()
		WHERE user_id = $1
	`, userID, amount)
	if err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	now := time.Now()
	src := source
	return &model.BonusTransaction{ID: id, UserID: userID, Type: "earn", Amount: amount, Source: &src, OrderID: &orderID, Description: &description, CreatedAt: now}, nil
}

func (r *BonusRepository) Spend(ctx context.Context, userID string, amount float64, source, orderID, description string) (*model.BonusTransaction, error) {
	if r.pool == nil {
		return mockTx(userID, "spend", amount, source), nil
	}
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var balance float64
	err = tx.QueryRow(ctx, `SELECT balance FROM bonus_accounts WHERE user_id = $1 FOR UPDATE`, userID).Scan(&balance)
	if err != nil {
		return nil, err
	}
	if balance < amount {
		return nil, fmt.Errorf("insufficient balance")
	}

	id := uuid.NewString()
	_, err = tx.Exec(ctx, `
		INSERT INTO bonus_transactions (id, user_id, type, amount, source, order_id, description)
		VALUES ($1, $2, 'spend', $3, $4, $5, $6)
	`, id, userID, amount, source, orderID, description)
	if err != nil {
		return nil, err
	}
	_, err = tx.Exec(ctx, `
		UPDATE bonus_accounts SET balance = balance - $2, total_spent = total_spent + $2, updated_at = NOW()
		WHERE user_id = $1
	`, userID, amount)
	if err != nil {
		return nil, err
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	now := time.Now()
	src := source
	return &model.BonusTransaction{ID: id, UserID: userID, Type: "spend", Amount: amount, Source: &src, OrderID: &orderID, Description: &description, CreatedAt: now}, nil
}

func (r *BonusRepository) ListHistory(ctx context.Context, userID, txType string, page, pageSize int) ([]model.BonusTransaction, int64, error) {
	if r.pool == nil {
		txs := []model.BonusTransaction{*mockTx(userID, "earn", 500, "Shelter")}
		if txType != "" && txs[0].Type != txType {
			return []model.BonusTransaction{}, 0, nil
		}
		return txs, 1, nil
	}
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize
	var total int64
	if err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM bonus_transactions
		WHERE user_id = $1 AND ($2 = '' OR type::text = $2)
	`, userID, txType).Scan(&total); err != nil {
		return nil, 0, err
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, type, amount, source, order_id, description, created_at
		FROM bonus_transactions
		WHERE user_id = $1 AND ($2 = '' OR type::text = $2)
		ORDER BY created_at DESC LIMIT $3 OFFSET $4
	`, userID, txType, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	return scanTransactions(rows, total)
}

func (r *BonusRepository) ListAll(ctx context.Context, userID, txType string, page, pageSize int) ([]model.BonusTransaction, int64, error) {
	if r.pool == nil {
		return []model.BonusTransaction{}, 0, nil
	}
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize
	var total int64
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM bonus_transactions
		WHERE ($1 = '' OR user_id::text = $1) AND ($2 = '' OR type::text = $2)
	`, userID, txType).Scan(&total)
	if err != nil {
		return nil, 0, err
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, type, amount, source, order_id, description, created_at
		FROM bonus_transactions
		WHERE ($1 = '' OR user_id::text = $1) AND ($2 = '' OR type::text = $2)
		ORDER BY created_at DESC LIMIT $3 OFFSET $4
	`, userID, txType, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	return scanTransactions(rows, total)
}

func (r *BonusRepository) TotalBalance(ctx context.Context) (float64, error) {
	if r.pool == nil {
		return 1500, nil
	}
	var total float64
	err := r.pool.QueryRow(ctx, `SELECT COALESCE(SUM(balance), 0) FROM bonus_accounts`).Scan(&total)
	return total, err
}

func (r *BonusRepository) EarnPercentage(source string, cfg *model.BonusConfig) float64 {
	switch source {
	case "Shelter":
		return cfg.EarnPercentageShelter
	case "Bars":
		return cfg.EarnPercentageBars
	case "RKeeper":
		return cfg.EarnPercentageRKeeper
	default:
		return cfg.EarnPercentageGlobal
	}
}

func (r *BonusRepository) CalcEarnAmount(purchaseAmount float64, pct float64) float64 {
	return math.Round(purchaseAmount*pct/100*100) / 100
}

func scanTransactions(rows pgx.Rows, total int64) ([]model.BonusTransaction, int64, error) {
	var items []model.BonusTransaction
	for rows.Next() {
		var t model.BonusTransaction
		if err := rows.Scan(&t.ID, &t.UserID, &t.Type, &t.Amount, &t.Source, &t.OrderID, &t.Description, &t.CreatedAt); err != nil {
			return nil, 0, err
		}
		items = append(items, t)
	}
	return items, total, rows.Err()
}

func defaultBonusConfig() *model.BonusConfig {
	return &model.BonusConfig{
		EarnPercentageGlobal: 5, EarnPercentageShelter: 5, EarnPercentageBars: 3,
		EarnPercentageRKeeper: 4, MaxSpendPercentage: 50, BonusExpiryDays: 365,
		MinReceiptAmount: 100, QRTTLSeconds: 60,
	}
}

func mockTx(userID, txType string, amount float64, source string) *model.BonusTransaction {
	src := source
	return &model.BonusTransaction{
		ID: uuid.NewString(), UserID: userID, Type: txType, Amount: amount,
		Source: &src, CreatedAt: time.Now(),
	}
}
