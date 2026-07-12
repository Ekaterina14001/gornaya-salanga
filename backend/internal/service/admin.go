package service

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/csv"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/internal/repository"
)

type AdminService struct {
	users   *repository.UserRepository
	bonus   *repository.BonusRepository
	content *repository.ContentRepository
	notif   *repository.NotificationRepository
	notify  *NotificationService
	msgs    *repository.MessageRepository
	pos     *repository.POSRepository
	cfg     *config.Config
}

func NewAdminService(
	users *repository.UserRepository,
	bonus *repository.BonusRepository,
	content *repository.ContentRepository,
	notif *repository.NotificationRepository,
	notify *NotificationService,
	msgs *repository.MessageRepository,
	pos *repository.POSRepository,
	cfg *config.Config,
) *AdminService {
	return &AdminService{users: users, bonus: bonus, content: content, notif: notif, notify: notify, msgs: msgs, pos: pos, cfg: cfg}
}

func (s *AdminService) Dashboard(ctx context.Context) (map[string]any, error) {
	userCount, _ := s.users.Count(ctx)
	activeToday, _ := s.users.CountActiveToday(ctx)
	totalBalance, _ := s.bonus.TotalBalance(ctx)
	notificationsToday, _ := s.notif.CountSentToday(ctx)
	weeklyRegistrations, _ := s.users.RegistrationsByDay(ctx, 7)
	return map[string]any{
		"userCount":                 userCount,
		"usersTotal":                userCount,
		"activeToday":               activeToday,
		"totalBalance":              totalBalance,
		"totalBonusesInCirculation": totalBalance,
		"notificationsSentToday":    notificationsToday,
		"weeklyRegistrations":       weeklyRegistrations,
		"health":                    "ok",
		"timestamp":                 time.Now(),
	}, nil
}

func (s *AdminService) ListUsers(ctx context.Context, q string, page, pageSize int) (*model.PaginatedResponse, error) {
	users, total, err := s.users.List(ctx, q, page, pageSize)
	if err != nil {
		return nil, err
	}
	result := repository.Paginate(users, total, page, pageSize)
	return &result, nil
}

func (s *AdminService) GetUser(ctx context.Context, id string) (map[string]any, error) {
	user, err := s.users.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	account, _ := s.bonus.GetAccount(ctx, id)
	history, _, _ := s.bonus.ListHistory(ctx, id, "", 1, 10)
	return map[string]any{"user": user, "bonusAccount": account, "recentTransactions": history}, nil
}

func (s *AdminService) SetBlocked(ctx context.Context, id string, blocked bool) error {
	return s.users.SetBlocked(ctx, id, blocked)
}

func (s *AdminService) AdjustUserBonus(ctx context.Context, adminID, userID, txType string, amount float64, description string) (*model.BonusTransaction, error) {
	if amount <= 0 {
		return nil, fmt.Errorf("amount must be positive")
	}
	if txType != "earn" && txType != "spend" {
		return nil, fmt.Errorf("type must be earn or spend")
	}

	user, err := s.users.GetByID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if user.Blocked {
		return nil, fmt.Errorf("user is blocked")
	}

	if _, err := s.bonus.GetAccount(ctx, userID); err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			_ = s.bonus.CreateAccount(ctx, userID)
		} else {
			return nil, err
		}
	}

	if description == "" {
		description = fmt.Sprintf("Корректировка администратором (%s)", adminID)
	}
	orderID := fmt.Sprintf("admin-%s", uuid.NewString())

	switch txType {
	case "earn":
		return s.bonus.Earn(ctx, userID, amount, "Admin", orderID, description)
	case "spend":
		return s.bonus.Spend(ctx, userID, amount, "Admin", orderID, description)
	default:
		return nil, fmt.Errorf("invalid type")
	}
}

func (s *AdminService) GetBonusConfig(ctx context.Context) (*model.BonusConfig, error) {
	return s.bonus.GetConfig(ctx)
}

func (s *AdminService) UpdateBonusConfig(ctx context.Context, adminID string, cfg *model.BonusConfig) (*model.BonusConfig, error) {
	if err := s.bonus.UpdateConfig(ctx, cfg); err != nil {
		return nil, err
	}
	_ = s.bonus.InsertConfigAudit(ctx, adminID, map[string]any{
		"earnPercentageGlobal": cfg.EarnPercentageGlobal,
		"maxSpendPercentage":   cfg.MaxSpendPercentage,
	})
	return cfg, nil
}

func (s *AdminService) BonusConfigAudit(ctx context.Context) ([]map[string]any, error) {
	return s.bonus.ListConfigAudit(ctx)
}

func (s *AdminService) ListTransactions(ctx context.Context, userID, txType string, page, pageSize int) (*model.PaginatedResponse, error) {
	items, total, err := s.bonus.ListAll(ctx, userID, txType, page, pageSize)
	if err != nil {
		return nil, err
	}
	result := repository.Paginate(items, total, page, pageSize)
	return &result, nil
}

func (s *AdminService) ListPOSKeys(ctx context.Context) ([]map[string]any, error) {
	return s.pos.ListKeys(ctx)
}

func (s *AdminService) CreatePOSKey(ctx context.Context, system string) (map[string]any, error) {
	raw := make([]byte, 24)
	if _, err := rand.Read(raw); err != nil {
		return nil, err
	}
	apiKey := "gs_" + hex.EncodeToString(raw)
	prefix := apiKey[:10]
	hash := sha256.Sum256([]byte(apiKey))
	result, err := s.pos.CreateKey(ctx, system, hex.EncodeToString(hash[:]), prefix)
	if err != nil {
		return nil, err
	}
	result["apiKey"] = apiKey
	result["prefix"] = prefix
	return result, nil
}

func (s *AdminService) RevokePOSKey(ctx context.Context, id string) error {
	return s.pos.RevokeKey(ctx, id)
}

func (s *AdminService) POSLogs(ctx context.Context, page, pageSize int) (*model.PaginatedResponse, error) {
	items, total, err := s.pos.ListLogs(ctx, page, pageSize)
	if err != nil {
		return nil, err
	}
	result := repository.Paginate(items, total, page, pageSize)
	return &result, nil
}

func (s *AdminService) UpdateAbout(ctx context.Context, title, body string, photos []string) (map[string]any, error) {
	return s.content.UpdateAbout(ctx, title, body, photos)
}

func (s *AdminService) UpdateRules(ctx context.Context, ruleType, title, body string) (map[string]any, error) {
	return s.content.UpdateRules(ctx, ruleType, title, body)
}

func (s *AdminService) ListServices(ctx context.Context) ([]map[string]any, error) {
	return s.content.ListServicesAdmin(ctx)
}

func (s *AdminService) CreateService(ctx context.Context, name, description string, price float64, category string, sortOrder int) (map[string]any, error) {
	return s.content.CreateService(ctx, name, description, price, category, sortOrder)
}

func (s *AdminService) UpdateService(ctx context.Context, id string, name, description *string, price *float64, category *string, sortOrder *int, active *bool) (map[string]any, error) {
	return s.content.UpdateService(ctx, id, name, description, price, category, sortOrder, active)
}

func (s *AdminService) DeleteService(ctx context.Context, id string) error {
	return s.content.DeleteService(ctx, id)
}

func (s *AdminService) ListHeadliners(ctx context.Context) ([]map[string]any, error) {
	return s.content.ListHeadlinersAdmin(ctx)
}

func (s *AdminService) CreateHeadliner(ctx context.Context, title, subtitle, imageURL, linkURL string, sortOrder int) (map[string]any, error) {
	return s.content.CreateHeadliner(ctx, title, subtitle, imageURL, linkURL, sortOrder)
}

func (s *AdminService) UpdateHeadliner(ctx context.Context, id string, title, subtitle, imageURL, linkURL *string, sortOrder *int, active *bool) (map[string]any, error) {
	return s.content.UpdateHeadliner(ctx, id, title, subtitle, imageURL, linkURL, sortOrder, active)
}

func (s *AdminService) DeleteHeadliner(ctx context.Context, id string) error {
	return s.content.DeleteHeadliner(ctx, id)
}

func (s *AdminService) UpdateWebcam(ctx context.Context, id string, name, streamURL, locationDesc *string, sortOrder *int, active *bool) (map[string]any, error) {
	return s.content.UpdateWebcam(ctx, id, name, streamURL, locationDesc, sortOrder, active)
}

func (s *AdminService) CreateWebcam(ctx context.Context, name, streamURL, locationDesc string, sortOrder int) (map[string]any, error) {
	return s.content.CreateWebcam(ctx, name, streamURL, locationDesc, sortOrder)
}

func (s *AdminService) UpdateTrail(ctx context.Context, id string, name, difficulty, status, comment *string) (map[string]any, error) {
	return s.content.UpdateTrail(ctx, id, name, difficulty, status, comment)
}

func (s *AdminService) CreateTrail(ctx context.Context, name, difficulty, status, comment string, sortOrder int) (map[string]any, error) {
	return s.content.CreateTrail(ctx, name, difficulty, status, comment, sortOrder)
}

func (s *AdminService) ListSchedule(ctx context.Context) ([]map[string]any, error) {
	return s.content.GetSchedule(ctx)
}

func (s *AdminService) UpdateSchedule(ctx context.Context, id string, openTime, closeTime *string, closed *bool) (map[string]any, error) {
	return s.content.UpdateSchedule(ctx, id, openTime, closeTime, closed)
}

func (s *AdminService) ListLifts(ctx context.Context) ([]map[string]any, error) {
	return s.content.ListLiftsAdmin(ctx)
}

func (s *AdminService) UpdateLift(ctx context.Context, id string, name, status, openTime, closeTime, comment, description, pricesText *string, active *bool) (map[string]any, error) {
	return s.content.UpdateLift(ctx, id, name, status, openTime, closeTime, comment, description, pricesText, active)
}

func (s *AdminService) Broadcast(ctx context.Context, title, body, notifType, audience string, data map[string]any) (int, error) {
	return s.notify.Broadcast(ctx, title, body, notifType, audience, data)
}

func (s *AdminService) ListMessages(ctx context.Context, status string) ([]map[string]any, error) {
	return s.msgs.ListAdmin(ctx, status)
}

func (s *AdminService) ReplyMessage(ctx context.Context, id, reply string) (*model.UserMessage, error) {
	msg, err := s.msgs.Reply(ctx, id, reply)
	if err != nil {
		return nil, err
	}
	title := "Ответ на ваше обращение"
	if msg.Subject != "" {
		title = "Re: " + msg.Subject
	}
	data := map[string]any{"messageId": msg.ID, "linkUrl": "/contact"}
	_ = s.notify.NotifyUser(ctx, msg.UserID, title, reply, "system", data)
	return msg, nil
}

func (s *AdminService) ExportTransactionsCSV(ctx context.Context) (string, error) {
	items, _, err := s.bonus.ListAll(ctx, "", "", 1, 10000)
	if err != nil {
		return "", err
	}
	var b strings.Builder
	w := csv.NewWriter(&b)
	_ = w.Write([]string{"id", "userId", "type", "amount", "source", "orderId", "createdAt"})
	for _, t := range items {
		src := ""
		if t.Source != nil {
			src = *t.Source
		}
		orderID := ""
		if t.OrderID != nil {
			orderID = *t.OrderID
		}
		_ = w.Write([]string{t.ID, t.UserID, t.Type, fmt.Sprintf("%.2f", t.Amount), src, orderID, t.CreatedAt.Format(time.RFC3339)})
	}
	w.Flush()
	return b.String(), w.Error()
}

type POSService struct {
	bonus *repository.BonusRepository
	users *repository.UserRepository
	pos   *repository.POSRepository
	cfg   *config.Config
}

func NewPOSService(bonus *repository.BonusRepository, users *repository.UserRepository, pos *repository.POSRepository, cfg *config.Config) *POSService {
	return &POSService{bonus: bonus, users: users, pos: pos, cfg: cfg}
}
