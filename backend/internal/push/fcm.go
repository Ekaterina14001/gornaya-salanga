package push

import (
	"context"
	"fmt"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/rs/zerolog/log"
	"google.golang.org/api/option"
)

type FCMSender struct {
	client *messaging.Client
}

func NewFCMSender(ctx context.Context, credentialsFile string) (Sender, error) {
	if credentialsFile == "" {
		return NoopSender{}, nil
	}
	app, err := firebase.NewApp(ctx, nil, option.WithCredentialsFile(credentialsFile))
	if err != nil {
		return nil, fmt.Errorf("firebase app: %w", err)
	}
	client, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("firebase messaging: %w", err)
	}
	log.Info().Str("credentials", credentialsFile).Msg("FCM push enabled")
	return &FCMSender{client: client}, nil
}

func (s *FCMSender) Enabled() bool { return true }

func (s *FCMSender) SendToTokens(ctx context.Context, tokens []string, title, body string, data map[string]string) ([]string, error) {
	if len(tokens) == 0 {
		return nil, nil
	}
	if data == nil {
		data = map[string]string{}
	}

	const batchSize = 500
	var invalid []string
	for i := 0; i < len(tokens); i += batchSize {
		end := i + batchSize
		if end > len(tokens) {
			end = len(tokens)
		}
		batch := tokens[i:end]
		msg := &messaging.MulticastMessage{
			Tokens: batch,
			Notification: &messaging.Notification{
				Title: title,
				Body:  body,
			},
			Data: data,
		}
		resp, err := s.client.SendEachForMulticast(ctx, msg)
		if err != nil {
			return invalid, err
		}
		for idx, r := range resp.Responses {
			if r.Success {
				continue
			}
			if messaging.IsUnregistered(r.Error) || messaging.IsInvalidArgument(r.Error) {
				invalid = append(invalid, batch[idx])
			}
		}
	}
	return invalid, nil
}
