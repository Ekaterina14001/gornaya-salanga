package sms

import (
	"context"
	"fmt"
	"strings"

	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/rs/zerolog/log"
)

type Sender interface {
	SendVerificationCode(ctx context.Context, phone, code string) error
	Mode() string
}

func NewSender(cfg *config.Config) (Sender, error) {
	mode := strings.ToLower(strings.TrimSpace(cfg.SMSMode))
	switch mode {
	case "", "log":
		log.Info().Msg("SMS: log mode (codes in server log)")
		return LogSender{}, nil
	case "smsru":
		if cfg.SMSRuAPIID == "" {
			return nil, fmt.Errorf("SMS_MODE=smsru requires SMS_RU_API_ID")
		}
		log.Info().
			Str("from", cfg.SMSRuFrom).
			Bool("test", cfg.SMSRuTest).
			Msg("SMS: sms.ru enabled")
		return NewSMSRuSender(cfg.SMSRuAPIID, cfg.SMSRuFrom, cfg.SMSMessageTemplate, cfg.SMSRuTest), nil
	default:
		return nil, fmt.Errorf("unknown SMS_MODE: %s", mode)
	}
}
