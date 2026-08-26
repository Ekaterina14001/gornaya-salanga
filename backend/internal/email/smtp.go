package email

import (
	"bytes"
	"context"
	"crypto/tls"
	"encoding/base64"
	"fmt"
	"net"
	"net/smtp"
	"strings"
	"time"
)

type SMTPConfig struct {
	Host      string
	Port      int
	TLS       string
	User      string
	Password  string
	From      string
	FromName  string
	PublicURL string
}

type SMTPSender struct {
	cfg SMTPConfig
}

func NewSMTPSender(cfg SMTPConfig) *SMTPSender {
	if cfg.Port == 0 {
		cfg.Port = 465
	}
	if cfg.TLS == "" {
		if cfg.Port == 465 {
			cfg.TLS = "ssl"
		} else {
			cfg.TLS = "starttls"
		}
	}
	if cfg.FromName == "" {
		cfg.FromName = "Gornaya Salanga"
	}
	return &SMTPSender{cfg: cfg}
}

func (s *SMTPSender) Mode() string { return "smtp" }

func (s *SMTPSender) SendPasswordReset(ctx context.Context, toEmail, resetCode string) error {
	subject, text, html := passwordResetBody(resetCode, s.cfg.PublicURL)
	return s.send(ctx, toEmail, subject, text, html)
}

func (s *SMTPSender) SendEmailVerification(ctx context.Context, toEmail, verifyToken string) error {
	subject, text, html := emailVerifyBody(verifyToken, s.cfg.PublicURL)
	return s.send(ctx, toEmail, subject, text, html)
}

func (s *SMTPSender) send(_ context.Context, to, subject, textBody, htmlBody string) error {
	from := s.cfg.From
	msg := buildMessage(from, s.cfg.FromName, to, subject, textBody, htmlBody)
	addr := fmt.Sprintf("%s:%d", s.cfg.Host, s.cfg.Port)
	auth := smtp.PlainAuth("", s.cfg.User, s.cfg.Password, s.cfg.Host)

	switch strings.ToLower(s.cfg.TLS) {
	case "ssl", "tls":
		return sendMailSSL(addr, s.cfg.Host, auth, from, []string{to}, msg)
	case "starttls", "start_tls":
		return sendMailSTARTTLS(addr, s.cfg.Host, auth, from, []string{to}, msg)
	case "none", "plain":
		return smtp.SendMail(addr, auth, from, []string{to}, msg)
	default:
		return fmt.Errorf("unknown SMTP_TLS: %s", s.cfg.TLS)
	}
}

func buildMessage(from, fromName, to, subject, textBody, htmlBody string) []byte {
	var buf bytes.Buffer
	fromHeader := from
	if fromName != "" {
		fromHeader = fmt.Sprintf("%s <%s>", encodeHeader(fromName), from)
	}
	buf.WriteString("From: " + fromHeader + "\r\n")
	buf.WriteString("To: " + to + "\r\n")
	buf.WriteString("Subject: " + encodeHeader(subject) + "\r\n")
	buf.WriteString("MIME-Version: 1.0\r\n")
	boundary := "gs-boundary-" + fmt.Sprint(time.Now().UnixNano())
	buf.WriteString("Content-Type: multipart/alternative; boundary=" + boundary + "\r\n")
	buf.WriteString("\r\n")
	writePart(&buf, boundary, "text/plain; charset=UTF-8", textBody)
	writePart(&buf, boundary, "text/html; charset=UTF-8", htmlBody)
	buf.WriteString("--" + boundary + "--\r\n")
	return buf.Bytes()
}

func writePart(buf *bytes.Buffer, boundary, contentType, body string) {
	buf.WriteString("--" + boundary + "\r\n")
	buf.WriteString("Content-Type: " + contentType + "\r\n")
	buf.WriteString("\r\n")
	buf.WriteString(body)
	buf.WriteString("\r\n")
}

func encodeHeader(value string) string {
	if value == "" {
		return ""
	}
	needsEncode := false
	for _, r := range value {
		if r > 127 {
			needsEncode = true
			break
		}
	}
	if !needsEncode {
		return value
	}
	return "=?UTF-8?B?" + base64.StdEncoding.EncodeToString([]byte(value)) + "?="
}

func sendMailSSL(addr, host string, auth smtp.Auth, from string, to []string, msg []byte) error {
	conn, err := tls.Dial("tcp", addr, &tls.Config{ServerName: host, MinVersion: tls.VersionTLS12})
	if err != nil {
		return fmt.Errorf("smtp tls dial: %w", err)
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, host)
	if err != nil {
		return fmt.Errorf("smtp client: %w", err)
	}
	defer client.Close()

	if auth != nil {
		if err := client.Auth(auth); err != nil {
			return fmt.Errorf("smtp auth: %w", err)
		}
	}
	return sendMessage(client, from, to, msg)
}

func sendMailSTARTTLS(addr, host string, auth smtp.Auth, from string, to []string, msg []byte) error {
	conn, err := net.Dial("tcp", addr)
	if err != nil {
		return fmt.Errorf("smtp dial: %w", err)
	}
	defer conn.Close()

	client, err := smtp.NewClient(conn, host)
	if err != nil {
		return fmt.Errorf("smtp client: %w", err)
	}
	defer client.Close()

	if ok, _ := client.Extension("STARTTLS"); ok {
		if err := client.StartTLS(&tls.Config{ServerName: host, MinVersion: tls.VersionTLS12}); err != nil {
			return fmt.Errorf("smtp starttls: %w", err)
		}
	}
	if auth != nil {
		if err := client.Auth(auth); err != nil {
			return fmt.Errorf("smtp auth: %w", err)
		}
	}
	return sendMessage(client, from, to, msg)
}

func sendMessage(client *smtp.Client, from string, to []string, msg []byte) error {
	if err := client.Mail(from); err != nil {
		return err
	}
	for _, rcpt := range to {
		if err := client.Rcpt(rcpt); err != nil {
			return err
		}
	}
	w, err := client.Data()
	if err != nil {
		return err
	}
	if _, err := w.Write(msg); err != nil {
		return err
	}
	if err := w.Close(); err != nil {
		return err
	}
	return client.Quit()
}
