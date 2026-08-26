package email

import (
	"context"

	"github.com/rs/zerolog/log"
)

type LogSender struct {
	publicURL string
}

func (s LogSender) Mode() string { return "log" }

func (s LogSender) SendPasswordReset(_ context.Context, toEmail, resetCode string) error {
	log.Info().
		Str("to", toEmail).
		Str("resetCode", resetCode).
		Msg("Password reset email (log mode)")
	return nil
}

func (s LogSender) SendEmailVerification(_ context.Context, toEmail, verifyCode string) error {
	log.Info().
		Str("to", toEmail).
		Str("verifyCode", verifyCode).
		Msg("Email verification (log mode)")
	return nil
}
