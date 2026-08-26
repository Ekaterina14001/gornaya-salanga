package repository

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/internal/sms"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"golang.org/x/crypto/bcrypt"
)

var ErrNotFound = errors.New("not found")

type UserRepository struct {
	pool *pgxpool.Pool
}

func NewUserRepository(pool *pgxpool.Pool) *UserRepository {
	return &UserRepository{pool: pool}
}

func (r *UserRepository) Create(ctx context.Context, req *model.RegisterRequest, passwordHash string) (*model.User, error) {
	if r.pool == nil {
		return mockGuest(), nil
	}
	phone, err := sms.FormatPhoneE164(req.Phone)
	if err != nil {
		return nil, err
	}
	id := uuid.NewString()
	row := r.pool.QueryRow(ctx, `
		INSERT INTO users (id, first_name, last_name, phone, email, password_hash, role)
		VALUES ($1, $2, $3, $4, $5, $6, 'guest')
		RETURNING id, first_name, last_name, phone, email, role, phone_verified, email_verified, blocked, last_activity_at, created_at, updated_at
	`, id, req.FirstName, req.LastName, phone, req.Email, passwordHash)
	user, err := scanUser(row)
	if err != nil {
		return nil, mapUniqueViolation(err)
	}
	return user, nil
}

func (r *UserRepository) FindByPhone(ctx context.Context, phone string) (*model.User, error) {
	if r.pool == nil {
		return nil, ErrNotFound
	}
	formatted, err := sms.FormatPhoneE164(phone)
	if err != nil {
		return nil, err
	}
	digits, err := sms.NormalizePhone(phone)
	if err != nil {
		return nil, err
	}
	row := r.pool.QueryRow(ctx, `
		SELECT id, first_name, last_name, phone, email, role, phone_verified, email_verified, blocked, last_activity_at, created_at, updated_at
		FROM users
		WHERE phone = $1 OR phone = $2 OR phone = $3
	`, formatted, digits, "8"+digits[1:])
	user, err := scanUser(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return user, nil
}

func (r *UserRepository) UpdateUnverifiedGuest(ctx context.Context, userID string, req *model.RegisterRequest, passwordHash string) (*model.User, error) {
	if r.pool == nil {
		return mockGuest(), nil
	}
	phone, err := sms.FormatPhoneE164(req.Phone)
	if err != nil {
		return nil, err
	}
	row := r.pool.QueryRow(ctx, `
		UPDATE users
		SET first_name = $2, last_name = $3, phone = $4, email = $5, password_hash = $6, updated_at = NOW()
		WHERE id = $1 AND phone_verified = FALSE
		RETURNING id, first_name, last_name, phone, email, role, phone_verified, email_verified, blocked, last_activity_at, created_at, updated_at
	`, userID, req.FirstName, req.LastName, phone, req.Email, passwordHash)
	user, err := scanUser(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, mapUniqueViolation(err)
	}
	return user, nil
}

func (r *UserRepository) FindByLogin(ctx context.Context, login string) (*model.User, string, error) {
	if r.pool == nil {
		if login == "admin@gornayasalanga.ru" {
			hash, _ := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
			return mockAdmin(), string(hash), nil
		}
		hash, _ := bcrypt.GenerateFromPassword([]byte("guest123"), bcrypt.DefaultCost)
		return mockGuest(), string(hash), nil
	}
	login = strings.TrimSpace(login)
	row := r.pool.QueryRow(ctx, `
		SELECT id, first_name, last_name, phone, email, role, phone_verified, email_verified, blocked, last_activity_at, created_at, updated_at, password_hash, device_secret
		FROM users WHERE email = $1 OR phone = $1
	`, login)
	var u model.User
	var pwHash string
	var deviceSecret *string
	err := row.Scan(&u.ID, &u.FirstName, &u.LastName, &u.Phone, &u.Email, &u.Role, &u.PhoneVerified, &u.EmailVerified, &u.Blocked, &u.LastActivity, &u.CreatedAt, &u.UpdatedAt, &pwHash, &deviceSecret)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, "", ErrNotFound
		}
		return nil, "", err
	}
	return &u, pwHash, nil
}

func (r *UserRepository) GetByID(ctx context.Context, id string) (*model.User, error) {
	if r.pool == nil {
		if id == "11111111-1111-1111-1111-111111111111" {
			return mockAdmin(), nil
		}
		return mockGuest(), nil
	}
	row := r.pool.QueryRow(ctx, `
		SELECT id, first_name, last_name, phone, email, role, phone_verified, email_verified, blocked, last_activity_at, created_at, updated_at
		FROM users WHERE id = $1
	`, id)
	return scanUser(row)
}

func (r *UserRepository) GetDeviceSecret(ctx context.Context, userID string) (string, error) {
	if r.pool == nil {
		return "dev-device-secret-guest-12345678901234567890123456789012", nil
	}
	var secret *string
	err := r.pool.QueryRow(ctx, `SELECT device_secret FROM users WHERE id = $1`, userID).Scan(&secret)
	if err != nil {
		return "", err
	}
	if secret == nil || *secret == "" {
		return "", errors.New("no device secret")
	}
	return *secret, nil
}

func (r *UserRepository) SetDeviceSecret(ctx context.Context, userID, secret string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE users SET device_secret = $2, updated_at = NOW() WHERE id = $1`, userID, secret)
	return err
}

func (r *UserRepository) Update(ctx context.Context, id string, req *model.UpdateProfileRequest) (*model.User, error) {
	if r.pool == nil {
		return mockGuest(), nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE users SET
			first_name = COALESCE($2, first_name),
			last_name = COALESCE($3, last_name),
			email = COALESCE($4, email),
			updated_at = NOW()
		WHERE id = $1
	`, id, req.FirstName, req.LastName, req.Email)
	if err != nil {
		return nil, err
	}
	return r.GetByID(ctx, id)
}

func (r *UserRepository) SetBlocked(ctx context.Context, id string, blocked bool) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE users SET blocked = $2, updated_at = NOW() WHERE id = $1`, id, blocked)
	return err
}

func (r *UserRepository) List(ctx context.Context, q string, page, pageSize int) ([]model.User, int64, error) {
	if r.pool == nil {
		return []model.User{*mockAdmin(), *mockGuest()}, 2, nil
	}
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize
	pattern := "%" + q + "%"
	var total int64
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM users
		WHERE $1 = '' OR first_name ILIKE $2 OR last_name ILIKE $2 OR email ILIKE $2 OR phone ILIKE $2
	`, q, pattern).Scan(&total)
	if err != nil {
		return nil, 0, err
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, first_name, last_name, phone, email, role, phone_verified, email_verified, blocked, last_activity_at, created_at, updated_at
		FROM users
		WHERE $1 = '' OR first_name ILIKE $2 OR last_name ILIKE $2 OR email ILIKE $2 OR phone ILIKE $2
		ORDER BY created_at DESC LIMIT $3 OFFSET $4
	`, q, pattern, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()
	var users []model.User
	for rows.Next() {
		var u model.User
		if err := rows.Scan(&u.ID, &u.FirstName, &u.LastName, &u.Phone, &u.Email, &u.Role, &u.PhoneVerified, &u.EmailVerified, &u.Blocked, &u.LastActivity, &u.CreatedAt, &u.UpdatedAt); err != nil {
			return nil, 0, err
		}
		users = append(users, u)
	}
	return users, total, rows.Err()
}

func (r *UserRepository) Count(ctx context.Context) (int64, error) {
	if r.pool == nil {
		return 2, nil
	}
	var n int64
	err := r.pool.QueryRow(ctx, `SELECT COUNT(*) FROM users`).Scan(&n)
	return n, err
}

func (r *UserRepository) SaveRefreshToken(ctx context.Context, userID, tokenHash string, expiresAt time.Time) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)
	`, userID, tokenHash, expiresAt)
	return err
}

func (r *UserRepository) FindRefreshToken(ctx context.Context, tokenHash string) (string, error) {
	if r.pool == nil {
		return "22222222-2222-2222-2222-222222222222", nil
	}
	var userID string
	err := r.pool.QueryRow(ctx, `
		SELECT user_id FROM refresh_tokens WHERE token_hash = $1 AND expires_at > NOW()
	`, tokenHash).Scan(&userID)
	if err != nil {
		return "", ErrNotFound
	}
	return userID, nil
}

func (r *UserRepository) RevokeRefreshToken(ctx context.Context, tokenHash string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `DELETE FROM refresh_tokens WHERE token_hash = $1`, tokenHash)
	return err
}

func (r *UserRepository) SetPhoneVerified(ctx context.Context, phone string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE users SET phone_verified = TRUE, updated_at = NOW() WHERE phone = $1`, phone)
	return err
}

func (r *UserRepository) SetEmailVerified(ctx context.Context, userID string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE users SET email_verified = TRUE, updated_at = NOW() WHERE id = $1`, userID)
	return err
}

func (r *UserRepository) UpdatePassword(ctx context.Context, userID, passwordHash string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE users SET password_hash = $2, updated_at = NOW() WHERE id = $1`, userID, passwordHash)
	return err
}

func (r *UserRepository) FindIDByEmail(ctx context.Context, email string) (string, error) {
	if r.pool == nil {
		return mockGuest().ID, nil
	}
	var id string
	err := r.pool.QueryRow(ctx, `SELECT id FROM users WHERE email = $1`, email).Scan(&id)
	if err != nil {
		return "", ErrNotFound
	}
	return id, nil
}

func (r *UserRepository) TouchLastActivity(ctx context.Context, userID string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE users SET last_activity_at = NOW() WHERE id = $1`, userID)
	return err
}

func (r *UserRepository) CountActiveToday(ctx context.Context) (int64, error) {
	if r.pool == nil {
		return 1, nil
	}
	var n int64
	err := r.pool.QueryRow(ctx, `
		SELECT COUNT(*) FROM users
		WHERE last_activity_at >= CURRENT_DATE AND blocked = FALSE
	`).Scan(&n)
	return n, err
}

func (r *UserRepository) RegistrationsByDay(ctx context.Context, days int) ([]map[string]any, error) {
	if days < 1 {
		days = 7
	}
	now := time.Now()
	start := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location()).AddDate(0, 0, -(days - 1))

	if r.pool == nil {
		out := make([]map[string]any, days)
		for i := 0; i < days; i++ {
			d := start.AddDate(0, 0, i)
			out[i] = map[string]any{
				"date":  d.Format("2006-01-02"),
				"count": int64((i + 1) % 4),
			}
		}
		return out, nil
	}

	rows, err := r.pool.Query(ctx, `
		SELECT created_at::date AS day, COUNT(*)::bigint
		FROM users
		WHERE created_at >= $1
		GROUP BY created_at::date
		ORDER BY day
	`, start)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	counts := make(map[string]int64)
	for rows.Next() {
		var day time.Time
		var count int64
		if err := rows.Scan(&day, &count); err != nil {
			return nil, err
		}
		counts[day.Format("2006-01-02")] = count
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	out := make([]map[string]any, days)
	for i := 0; i < days; i++ {
		d := start.AddDate(0, 0, i)
		key := d.Format("2006-01-02")
		out[i] = map[string]any{"date": key, "count": counts[key]}
	}
	return out, nil
}

func GenerateDeviceSecret() (string, error) {
	b := make([]byte, 32)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return hex.EncodeToString(b), nil
}

func scanUser(row pgx.Row) (*model.User, error) {
	var u model.User
	err := row.Scan(&u.ID, &u.FirstName, &u.LastName, &u.Phone, &u.Email, &u.Role, &u.PhoneVerified, &u.EmailVerified, &u.Blocked, &u.LastActivity, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &u, nil
}

func mockAdmin() *model.User {
	now := time.Now()
	return &model.User{
		ID: "11111111-1111-1111-1111-111111111111", FirstName: "Админ", LastName: "Системы",
		Phone: "+79000000001", Email: "admin@gornayasalanga.ru", Role: "admin",
		PhoneVerified: true, EmailVerified: true, CreatedAt: now, UpdatedAt: now,
	}
}

func mockGuest() *model.User {
	now := time.Now()
	return &model.User{
		ID: "22222222-2222-2222-2222-222222222222", FirstName: "Иван", LastName: "Гостев",
		Phone: "+79000000002", Email: "guest@gornayasalanga.ru", Role: "guest",
		PhoneVerified: true, EmailVerified: true, CreatedAt: now, UpdatedAt: now,
	}
}

func HashPassword(password string) (string, error) {
	b, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(b), err
}

func CheckPassword(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}

func Paginate[T any](items []T, total int64, page, pageSize int) model.PaginatedResponse {
	totalPages := int(total) / pageSize
	if int(total)%pageSize != 0 {
		totalPages++
	}
	return model.PaginatedResponse{
		Items: items, Total: total, Page: page, PageSize: pageSize, TotalPages: totalPages,
	}
}

func fmtErr(msg string, args ...any) error {
	return fmt.Errorf(msg, args...)
}
