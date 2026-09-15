package repository

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UDSOperation struct {
	ID             int64
	UserID         string
	System         string
	Nonce          string
	Action         string
	State          string
	Total          float64
	Cash           float64
	Points         float64
	Cashback       float64
	ReceiptNumber  string
	OriginID       *int64
	EarnTxID       *string
	SpendTxID      *string
	CreatedAt      time.Time
}

type UDSRepository struct {
	pool *pgxpool.Pool

	mu           sync.Mutex
	nextPart     int64
	partsByUser  map[string]int64
	userByPart   map[int64]string
	nextOp       int64
	ops          map[int64]*UDSOperation
	opsByNonce   map[string]int64
}

func NewUDSRepository(pool *pgxpool.Pool) *UDSRepository {
	return &UDSRepository{
		pool:        pool,
		nextPart:    1000,
		partsByUser: map[string]int64{},
		userByPart:  map[int64]string{},
		nextOp:      1,
		ops:         map[int64]*UDSOperation{},
		opsByNonce:  map[string]int64{},
	}
}

func (r *UDSRepository) GetOrCreateParticipant(ctx context.Context, userID string) (int64, error) {
	if r.pool == nil {
		r.mu.Lock()
		defer r.mu.Unlock()
		if id, ok := r.partsByUser[userID]; ok {
			return id, nil
		}
		r.nextPart++
		id := r.nextPart
		r.partsByUser[userID] = id
		r.userByPart[id] = userID
		return id, nil
	}
	var id int64
	err := r.pool.QueryRow(ctx, `
		INSERT INTO uds_participants (user_id) VALUES ($1)
		ON CONFLICT (user_id) DO UPDATE SET user_id = EXCLUDED.user_id
		RETURNING id
	`, userID).Scan(&id)
	return id, err
}

func (r *UDSRepository) UserIDByParticipant(ctx context.Context, participantID int64) (string, error) {
	if r.pool == nil {
		r.mu.Lock()
		defer r.mu.Unlock()
		userID, ok := r.userByPart[participantID]
		if !ok {
			return "", ErrNotFound
		}
		return userID, nil
	}
	var userID string
	err := r.pool.QueryRow(ctx, `SELECT user_id FROM uds_participants WHERE id = $1`, participantID).Scan(&userID)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNotFound
	}
	return userID, err
}

func (r *UDSRepository) CreateOperation(ctx context.Context, op *UDSOperation) (*UDSOperation, error) {
	if r.pool == nil {
		r.mu.Lock()
		defer r.mu.Unlock()
		if op.Nonce != "" {
			if id, ok := r.opsByNonce[op.Nonce]; ok {
				copied := *r.ops[id]
				return &copied, nil
			}
		}
		id := r.nextOp
		r.nextOp++
		op.ID = id
		if op.CreatedAt.IsZero() {
			op.CreatedAt = time.Now().UTC()
		}
		cp := *op
		r.ops[id] = &cp
		if op.Nonce != "" {
			r.opsByNonce[op.Nonce] = id
		}
		return &cp, nil
	}
	var origin any
	if op.OriginID != nil {
		origin = *op.OriginID
	}
	err := r.pool.QueryRow(ctx, `
		INSERT INTO uds_operations (
			user_id, system, nonce, action, state, total, cash, points, cashback,
			receipt_number, origin_id, earn_tx_id, spend_tx_id
		) VALUES ($1,$2,NULLIF($3,''),$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
		RETURNING id, created_at
	`, op.UserID, op.System, op.Nonce, op.Action, op.State, op.Total, op.Cash, op.Points, op.Cashback,
		nullIfEmpty(op.ReceiptNumber), origin, op.EarnTxID, op.SpendTxID,
	).Scan(&op.ID, &op.CreatedAt)
	if isUniqueViolation(err) && op.Nonce != "" {
		return r.GetOperationByNonce(ctx, op.Nonce)
	}
	return op, err
}

func (r *UDSRepository) GetOperation(ctx context.Context, id int64) (*UDSOperation, error) {
	if r.pool == nil {
		r.mu.Lock()
		defer r.mu.Unlock()
		op, ok := r.ops[id]
		if !ok {
			return nil, ErrNotFound
		}
		cp := *op
		return &cp, nil
	}
	return scanUDSOperation(r.pool.QueryRow(ctx, `
		SELECT id, user_id, system, COALESCE(nonce, ''), action, state, total, cash, points, cashback,
		       COALESCE(receipt_number, ''), origin_id, earn_tx_id, spend_tx_id, created_at
		FROM uds_operations WHERE id = $1
	`, id))
}

func (r *UDSRepository) GetOperationByNonce(ctx context.Context, nonce string) (*UDSOperation, error) {
	if nonce == "" {
		return nil, ErrNotFound
	}
	if r.pool == nil {
		r.mu.Lock()
		defer r.mu.Unlock()
		id, ok := r.opsByNonce[nonce]
		if !ok {
			return nil, ErrNotFound
		}
		cp := *r.ops[id]
		return &cp, nil
	}
	return scanUDSOperation(r.pool.QueryRow(ctx, `
		SELECT id, user_id, system, COALESCE(nonce, ''), action, state, total, cash, points, cashback,
		       COALESCE(receipt_number, ''), origin_id, earn_tx_id, spend_tx_id, created_at
		FROM uds_operations WHERE nonce = $1
	`, nonce))
}

func (r *UDSRepository) UpdateOperationState(ctx context.Context, id int64, state string) error {
	if r.pool == nil {
		r.mu.Lock()
		defer r.mu.Unlock()
		op, ok := r.ops[id]
		if !ok {
			return ErrNotFound
		}
		op.State = state
		return nil
	}
	tag, err := r.pool.Exec(ctx, `UPDATE uds_operations SET state = $2 WHERE id = $1`, id, state)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (r *UDSRepository) ListOperations(ctx context.Context, limit, offset int) ([]UDSOperation, int64, error) {
	if limit < 1 {
		limit = 10
	}
	if limit > 50 {
		limit = 50
	}
	if offset < 0 {
		offset = 0
	}
	if r.pool == nil {
		r.mu.Lock()
		defer r.mu.Unlock()
		total := int64(len(r.ops))
		ids := make([]int64, 0, len(r.ops))
		for id := range r.ops {
			ids = append(ids, id)
		}
		for i := 0; i < len(ids); i++ {
			for j := i + 1; j < len(ids); j++ {
				if ids[j] > ids[i] {
					ids[i], ids[j] = ids[j], ids[i]
				}
			}
		}
		if offset > len(ids) {
			return []UDSOperation{}, total, nil
		}
		end := offset + limit
		if end > len(ids) {
			end = len(ids)
		}
		out := make([]UDSOperation, 0, end-offset)
		for _, id := range ids[offset:end] {
			out = append(out, *r.ops[id])
		}
		return out, total, nil
	}
	var total int64
	if err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM uds_operations`).Scan(&total); err != nil {
		return nil, 0, err
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, system, COALESCE(nonce, ''), action, state, total, cash, points, cashback,
		       COALESCE(receipt_number, ''), origin_id, earn_tx_id, spend_tx_id, created_at
		FROM uds_operations
		ORDER BY id DESC
		LIMIT $1 OFFSET $2
	`, limit, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	var items []UDSOperation
	for rows.Next() {
		op, err := scanUDSOperation(rows)
		if err != nil {
			return nil, 0, err
		}
		items = append(items, *op)
	}
	return items, total, rows.Err()
}

type udsRow interface {
	Scan(dest ...any) error
}

func scanUDSOperation(row udsRow) (*UDSOperation, error) {
	var op UDSOperation
	err := row.Scan(
		&op.ID, &op.UserID, &op.System, &op.Nonce, &op.Action, &op.State,
		&op.Total, &op.Cash, &op.Points, &op.Cashback, &op.ReceiptNumber,
		&op.OriginID, &op.EarnTxID, &op.SpendTxID, &op.CreatedAt,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &op, nil
}

func nullIfEmpty(s string) any {
	if s == "" {
		return nil
	}
	return s
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
