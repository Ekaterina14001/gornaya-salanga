package repository

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type FarCardsReceipt struct {
	ID           string
	Restaurant   string
	RKUnit       string
	RKCheck      string
	CardCode     int64
	PointsSpent  float64
	PointsEarned float64
}

type FarCardsRepository struct {
	pool *pgxpool.Pool
}

func NewFarCardsRepository(pool *pgxpool.Pool) *FarCardsRepository {
	return &FarCardsRepository{pool: pool}
}

func (r *FarCardsRepository) GetReceipt(ctx context.Context, restaurant, rkUnit, rkCheck string, cardCode int64) (*FarCardsReceipt, error) {
	if r.pool == nil {
		return nil, pgx.ErrNoRows
	}
	var rec FarCardsReceipt
	err := r.pool.QueryRow(ctx, `
		SELECT id::text, restaurant, rk_unit, rk_check, card_code, points_spent, points_earned
		FROM farcards_receipts
		WHERE restaurant = $1 AND rk_unit = $2 AND rk_check = $3 AND card_code = $4
	`, restaurant, rkUnit, rkCheck, cardCode).Scan(
		&rec.ID, &rec.Restaurant, &rec.RKUnit, &rec.RKCheck, &rec.CardCode, &rec.PointsSpent, &rec.PointsEarned,
	)
	if err != nil {
		return nil, err
	}
	return &rec, nil
}

func (r *FarCardsRepository) SaveReceipt(ctx context.Context, rec *FarCardsReceipt) error {
	if r.pool == nil {
		return errors.New("database unavailable")
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO farcards_receipts (restaurant, rk_unit, rk_check, card_code, points_spent, points_earned)
		VALUES ($1, $2, $3, $4, $5, $6)
		ON CONFLICT (restaurant, rk_unit, rk_check, card_code) DO NOTHING
	`, rec.Restaurant, rec.RKUnit, rec.RKCheck, rec.CardCode, rec.PointsSpent, rec.PointsEarned)
	return err
}
