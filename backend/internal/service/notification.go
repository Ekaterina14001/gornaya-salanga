package service

import (
	"context"
	"fmt"

	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/internal/push"
	"github.com/gornaya-salanga/backend/internal/repository"
	"github.com/rs/zerolog/log"
)

type NotificationService struct {
	notif *repository.NotificationRepository
	push  push.Sender
}

func NewNotificationService(notif *repository.NotificationRepository, pushSender push.Sender) *NotificationService {
	if pushSender == nil {
		pushSender = push.NoopSender{}
	}
	return &NotificationService{notif: notif, push: pushSender}
}

func (s *NotificationService) List(ctx context.Context, userID string) ([]model.Notification, error) {
	return s.notif.List(ctx, userID)
}

func (s *NotificationService) MarkRead(ctx context.Context, userID, id string) error {
	return s.notif.MarkRead(ctx, userID, id)
}

func (s *NotificationService) RegisterDevice(ctx context.Context, userID, token, platform string) error {
	if platform == "" {
		platform = "unknown"
	}
	return s.notif.SaveDeviceToken(ctx, userID, token, platform)
}

func (s *NotificationService) PushEnabled() bool {
	return s.push.Enabled()
}

func (s *NotificationService) NotifyUser(ctx context.Context, userID, title, body, notifType string, data map[string]any) error {
	if err := s.notif.Create(ctx, userID, title, body, notifType, data); err != nil {
		return err
	}
	s.sendPush(ctx, userID, title, body, notifType, data)
	return nil
}

func (s *NotificationService) Broadcast(ctx context.Context, title, body, notifType, audience string, data map[string]any) (int, error) {
	if notifType == "" {
		notifType = "news"
	}
	userIDs, err := s.notif.ListAudienceUserIDs(ctx, audience)
	if err != nil {
		return 0, err
	}
	count := 0
	for _, uid := range userIDs {
		if err := s.NotifyUser(ctx, uid, title, body, notifType, data); err != nil {
			return count, err
		}
		count++
	}
	return count, nil
}

func (s *NotificationService) sendPush(ctx context.Context, userID, title, body, notifType string, data map[string]any) {
	if !s.push.Enabled() {
		return
	}
	tokens, err := s.notif.ListDeviceTokens(ctx, userID)
	if err != nil {
		log.Warn().Err(err).Str("userId", userID).Msg("list device tokens failed")
		return
	}
	if len(tokens) == 0 {
		return
	}
	payload := map[string]string{
		"type": notifType,
	}
	for k, v := range data {
		payload[k] = fmt.Sprint(v)
	}
	invalid, err := s.push.SendToTokens(ctx, tokens, title, body, payload)
	if err != nil {
		log.Warn().Err(err).Str("userId", userID).Msg("FCM send failed")
		return
	}
	if len(invalid) > 0 {
		_ = s.notif.DeleteDeviceTokens(ctx, invalid)
	}
}
