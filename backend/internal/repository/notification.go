package repository

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/jackc/pgx/v5/pgxpool"
)

type NotificationRepository struct {
	pool *pgxpool.Pool
}

func NewNotificationRepository(pool *pgxpool.Pool) *NotificationRepository {
	return &NotificationRepository{pool: pool}
}

func (r *NotificationRepository) List(ctx context.Context, userID string) ([]model.Notification, error) {
	if r.pool == nil {
		return []model.Notification{}, nil
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, title, body, type, data, read, created_at
		FROM notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 100
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []model.Notification
	for rows.Next() {
		var n model.Notification
		if err := rows.Scan(&n.ID, &n.UserID, &n.Title, &n.Body, &n.Type, &n.Data, &n.Read, &n.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, n)
	}
	return items, rows.Err()
}

func (r *NotificationRepository) MarkRead(ctx context.Context, userID, id string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE notifications SET read = TRUE WHERE id = $1 AND user_id = $2`, id, userID)
	return err
}

func (r *NotificationRepository) Create(ctx context.Context, userID, title, body, notifType string, data map[string]any) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO notifications (id, user_id, title, body, type, data) VALUES ($1, $2, $3, $4, $5, $6)
	`, uuid.NewString(), userID, title, body, notifType, data)
	return err
}

func (r *NotificationRepository) SaveDeviceToken(ctx context.Context, userID, token, platform string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO device_tokens (user_id, token, platform)
		VALUES ($1, $2, $3)
	 ON CONFLICT (user_id, token) DO UPDATE SET platform = $3, updated_at = NOW()
	`, userID, token, platform)
	return err
}

func (r *NotificationRepository) ListDeviceTokens(ctx context.Context, userID string) ([]string, error) {
	if r.pool == nil {
		return nil, nil
	}
	rows, err := r.pool.Query(ctx, `SELECT token FROM device_tokens WHERE user_id = $1`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var tokens []string
	for rows.Next() {
		var token string
		if err := rows.Scan(&token); err != nil {
			return nil, err
		}
		tokens = append(tokens, token)
	}
	return tokens, rows.Err()
}

func (r *NotificationRepository) DeleteDeviceTokens(ctx context.Context, tokens []string) error {
	if r.pool == nil || len(tokens) == 0 {
		return nil
	}
	_, err := r.pool.Exec(ctx, `DELETE FROM device_tokens WHERE token = ANY($1)`, tokens)
	return err
}

func (r *NotificationRepository) ListAudienceUserIDs(ctx context.Context, audience string) ([]string, error) {
	if r.pool == nil {
		return nil, nil
	}
	query := `SELECT id FROM users WHERE blocked = FALSE`
	if audience == "guest" || audience == "guests" {
		query += ` AND role = 'guest'`
	}
	rows, err := r.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, rows.Err()
}

func (r *NotificationRepository) CountSentToday(ctx context.Context) (int64, error) {
	if r.pool == nil {
		return 0, nil
	}
	var n int64
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM notifications WHERE created_at >= CURRENT_DATE
	`).Scan(&n)
	return n, err
}

func (r *NotificationRepository) Broadcast(ctx context.Context, title, body, notifType string, data map[string]any, audience string) (int, error) {
	userIDs, err := r.ListAudienceUserIDs(ctx, audience)
	if err != nil {
		return 0, err
	}
	count := 0
	for _, uid := range userIDs {
		if err := r.Create(ctx, uid, title, body, notifType, data); err != nil {
			return count, err
		}
		count++
	}
	return count, nil
}

type MessageRepository struct {
	pool *pgxpool.Pool
}

func NewMessageRepository(pool *pgxpool.Pool) *MessageRepository {
	return &MessageRepository{pool: pool}
}

func (r *MessageRepository) Create(ctx context.Context, userID, subject, body string) (*model.UserMessage, error) {
	id := uuid.NewString()
	now := time.Now()
	if r.pool == nil {
		return &model.UserMessage{ID: id, UserID: userID, Subject: subject, Body: body, Status: "unread", CreatedAt: now}, nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO user_messages (id, user_id, subject, body) VALUES ($1, $2, $3, $4)
	`, id, userID, subject, body)
	if err != nil {
		return nil, err
	}
	return &model.UserMessage{ID: id, UserID: userID, Subject: subject, Body: body, Status: "unread", CreatedAt: now}, nil
}

func (r *MessageRepository) List(ctx context.Context, status string) ([]model.UserMessage, error) {
	if r.pool == nil {
		return []model.UserMessage{}, nil
	}
	query := `SELECT id, user_id, subject, body, status, admin_reply, replied_at, created_at FROM user_messages`
	args := []any{}
	if status != "" {
		query += ` WHERE status = $1`
		args = append(args, status)
	}
	query += ` ORDER BY created_at DESC LIMIT 100`
	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []model.UserMessage
	for rows.Next() {
		var m model.UserMessage
		if err := rows.Scan(&m.ID, &m.UserID, &m.Subject, &m.Body, &m.Status, &m.AdminReply, &m.RepliedAt, &m.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, m)
	}
	return items, rows.Err()
}

func (r *MessageRepository) ListByUser(ctx context.Context, userID string) ([]model.UserMessage, error) {
	if r.pool == nil {
		return []model.UserMessage{}, nil
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, user_id, subject, body, status, admin_reply, replied_at, created_at
		FROM user_messages WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50
	`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []model.UserMessage
	for rows.Next() {
		var m model.UserMessage
		if err := rows.Scan(&m.ID, &m.UserID, &m.Subject, &m.Body, &m.Status, &m.AdminReply, &m.RepliedAt, &m.CreatedAt); err != nil {
			return nil, err
		}
		items = append(items, m)
	}
	return items, rows.Err()
}

func (r *MessageRepository) ListAdmin(ctx context.Context, status string) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{}, nil
	}
	query := `
		SELECT m.id, m.user_id, m.subject, m.body, m.status, m.admin_reply, m.replied_at, m.created_at,
		       u.email, u.first_name, u.last_name
		FROM user_messages m
		JOIN users u ON u.id = m.user_id
	`
	args := []any{}
	if status != "" {
		query += ` WHERE m.status = $1`
		args = append(args, status)
	}
	query += ` ORDER BY m.created_at DESC LIMIT 100`
	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []map[string]any
	for rows.Next() {
		var id, userID, subject, body, msgStatus, email, firstName, lastName string
		var adminReply *string
		var repliedAt *time.Time
		var createdAt time.Time
		if err := rows.Scan(&id, &userID, &subject, &body, &msgStatus, &adminReply, &repliedAt, &createdAt, &email, &firstName, &lastName); err != nil {
			return nil, err
		}
		item := map[string]any{
			"id":        id,
			"userId":    userID,
			"subject":   subject,
			"body":      body,
			"status":    msgStatus,
			"createdAt": createdAt,
			"userEmail": email,
			"userName":  strings.TrimSpace(firstName + " " + lastName),
		}
		if adminReply != nil {
			item["adminReply"] = *adminReply
		}
		if repliedAt != nil {
			item["repliedAt"] = *repliedAt
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *MessageRepository) Reply(ctx context.Context, id, reply string) (*model.UserMessage, error) {
	now := time.Now()
	if r.pool == nil {
		return &model.UserMessage{ID: id, AdminReply: &reply, Status: "replied", RepliedAt: &now}, nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE user_messages SET admin_reply = $2, status = 'replied', replied_at = $3 WHERE id = $1
	`, id, reply, now)
	if err != nil {
		return nil, err
	}
	var m model.UserMessage
	err = r.pool.QueryRow(ctx, `
		SELECT id, user_id, subject, body, status, admin_reply, replied_at, created_at FROM user_messages WHERE id = $1
	`, id).Scan(&m.ID, &m.UserID, &m.Subject, &m.Body, &m.Status, &m.AdminReply, &m.RepliedAt, &m.CreatedAt)
	return &m, err
}

type POSRepository struct {
	pool *pgxpool.Pool
}

func NewPOSRepository(pool *pgxpool.Pool) *POSRepository {
	return &POSRepository{pool: pool}
}

func (r *POSRepository) ListKeys(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{}, nil
	}
	rows, err := r.pool.Query(ctx, `SELECT id, system, api_key_prefix, active, last_used_at, created_at FROM pos_api_keys WHERE revoked_at IS NULL`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []map[string]any
	for rows.Next() {
		var id, system, prefix string
		var active bool
		var lastUsed, createdAt *time.Time
		if err := rows.Scan(&id, &system, &prefix, &active, &lastUsed, &createdAt); err != nil {
			return nil, err
		}
		items = append(items, map[string]any{
			"id": id, "system": system, "apiKeyPrefix": prefix, "active": active,
			"lastUsedAt": lastUsed, "createdAt": createdAt,
		})
	}
	return items, rows.Err()
}

func (r *POSRepository) CreateKey(ctx context.Context, system, keyHash, prefix string) (map[string]any, error) {
	id := uuid.NewString()
	if r.pool == nil {
		return map[string]any{"id": id, "system": system, "apiKeyPrefix": prefix}, nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO pos_api_keys (id, system, api_key_hash, api_key_prefix) VALUES ($1, $2, $3, $4)
	`, id, system, keyHash, prefix)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id, "system": system, "apiKeyPrefix": prefix}, nil
}

func (r *POSRepository) ValidateAPIKey(ctx context.Context, apiKey string) (string, error) {
	hash := sha256.Sum256([]byte(apiKey))
	hashHex := hex.EncodeToString(hash[:])
	if r.pool == nil {
		return "", ErrNotFound
	}
	var system string
	err := r.pool.QueryRow(ctx, `
		SELECT system FROM pos_api_keys
		WHERE api_key_hash = $1 AND active = TRUE AND revoked_at IS NULL
	`, hashHex).Scan(&system)
	if err != nil {
		return "", ErrNotFound
	}
	_, _ = r.pool.Exec(ctx, `UPDATE pos_api_keys SET last_used_at = NOW() WHERE api_key_hash = $1`, hashHex)
	return system, nil
}

func (r *POSRepository) RevokeKey(ctx context.Context, id string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE pos_api_keys SET active = FALSE, revoked_at = NOW() WHERE id = $1`, id)
	return err
}

func (r *POSRepository) LogRequest(ctx context.Context, system, endpoint string, statusCode int) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO pos_request_logs (system, endpoint, status_code) VALUES ($1, $2, $3)
	`, system, endpoint, statusCode)
	return err
}

func (r *POSRepository) ListLogs(ctx context.Context, page, pageSize int) ([]map[string]any, int64, error) {
	if r.pool == nil {
		return []map[string]any{}, 0, nil
	}
	if page < 1 {
		page = 1
	}
	offset := (page - 1) * pageSize
	var total int64
	if err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM pos_request_logs`).Scan(&total); err != nil {
		return nil, 0, err
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, system, endpoint, status_code, created_at FROM pos_request_logs
		ORDER BY created_at DESC LIMIT $1 OFFSET $2
	`, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	var items []map[string]any
	for rows.Next() {
		var id, system, endpoint string
		var statusCode int
		var createdAt time.Time
		if err := rows.Scan(&id, &system, &endpoint, &statusCode, &createdAt); err != nil {
			return nil, 0, err
		}
		items = append(items, map[string]any{
			"id": id, "system": system, "endpoint": endpoint,
			"statusCode": statusCode, "createdAt": createdAt,
		})
	}
	return items, total, rows.Err()
}
