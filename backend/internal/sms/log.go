package sms

import (
	"context"

	"github.com/rs/zerolog/log"
)

type LogSender struct{}

func (LogSender) Mode() string { return "log" }

func (LogSender) SendVerificationCode(ctx context.Context, phone, code string) error {
	log.Info().Str("phone", phone).Str("code", code).Msg("SMS verification code (log mode)")
	return nil
}
