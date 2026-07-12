package push

import (
	"context"

	"github.com/rs/zerolog/log"
)

type NoopSender struct{}

func (NoopSender) Enabled() bool { return false }

func (NoopSender) SendToTokens(ctx context.Context, tokens []string, title, body string, data map[string]string) ([]string, error) {
	if len(tokens) > 0 {
		log.Debug().
			Int("tokens", len(tokens)).
			Str("title", title).
			Msg("FCM disabled: push not sent (set FCM_CREDENTIALS_FILE)")
	}
	return nil, nil
}
