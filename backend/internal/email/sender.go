package email

import (
	"context"
	"fmt"
	"strings"

	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/rs/zerolog/log"
)

type Sender interface {
	SendPasswordReset(ctx context.Context, toEmail, resetToken string) error
	SendEmailVerification(ctx context.Context, toEmail, verifyToken string) error
	Mode() string
}

func NewSender(cfg *config.Config) (Sender, error) {
	mode := strings.ToLower(strings.TrimSpace(cfg.EmailMode))
	switch mode {
	case "", "log":
		log.Info().Msg("Email: log mode (links in server log)")
		return LogSender{publicURL: cfg.AppPublicURL}, nil
	case "smtp":
		if cfg.SMTPHost == "" || cfg.SMTPUser == "" || cfg.SMTPPassword == "" {
			return nil, fmt.Errorf("EMAIL_MODE=smtp requires SMTP_HOST, SMTP_USER, SMTP_PASSWORD")
		}
		from := cfg.SMTPFrom
		if from == "" {
			from = cfg.SMTPUser
		}
		log.Info().
			Str("host", cfg.SMTPHost).
			Int("port", cfg.SMTPPort).
			Str("from", from).
			Str("tls", cfg.SMTPTLS).
			Msg("Email: SMTP enabled")
		return NewSMTPSender(SMTPConfig{
			Host:      cfg.SMTPHost,
			Port:      cfg.SMTPPort,
			TLS:       cfg.SMTPTLS,
			User:      cfg.SMTPUser,
			Password:  cfg.SMTPPassword,
			From:      from,
			FromName:  cfg.SMTPFromName,
			PublicURL: cfg.AppPublicURL,
		}), nil
	default:
		return nil, fmt.Errorf("unknown EMAIL_MODE: %s", mode)
	}
}
