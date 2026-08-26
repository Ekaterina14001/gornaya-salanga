package sms

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const smsRuSendURL = "https://sms.ru/sms/send"

type SMSRuSender struct {
	apiID    string
	from     string
	template string
	test     bool
	client   *http.Client
}

func NewSMSRuSender(apiID, from, template string, test bool) *SMSRuSender {
	if template == "" {
		template = "Код подтверждения Горная Саланга: {code}"
	}
	return &SMSRuSender{
		apiID:    apiID,
		from:     from,
		template: template,
		test:     test,
		client:   &http.Client{Timeout: 15 * time.Second},
	}
}

func (s *SMSRuSender) Mode() string { return "smsru" }

func (s *SMSRuSender) SendVerificationCode(ctx context.Context, phone, code string) error {
	to, err := NormalizePhone(phone)
	if err != nil {
		return err
	}

	msg := strings.ReplaceAll(s.template, "{code}", code)
	form := url.Values{}
	form.Set("api_id", s.apiID)
	form.Set("to", to)
	form.Set("msg", msg)
	form.Set("json", "1")
	if s.from != "" {
		form.Set("from", s.from)
	}
	if s.test {
		form.Set("test", "1")
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, smsRuSendURL, strings.NewReader(form.Encode()))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := s.client.Do(req)
	if err != nil {
		return fmt.Errorf("sms.ru request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return fmt.Errorf("sms.ru read response: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("sms.ru http %d: %s", resp.StatusCode, string(body))
	}

	var parsed smsRuResponse
	if err := json.Unmarshal(body, &parsed); err != nil {
		return fmt.Errorf("sms.ru parse response: %w", err)
	}
	if parsed.Status != "OK" || parsed.StatusCode != 100 {
		return fmt.Errorf("sms.ru error: %s (code %d)", parsed.StatusText, parsed.StatusCode)
	}

	item, ok := parsed.SMS[to]
	if !ok {
		return fmt.Errorf("sms.ru: no status for phone")
	}
	if item.Status != "OK" || item.StatusCode != 100 {
		text := DeliveryErrorMessage(item.StatusCode, item.StatusText)
		return fmt.Errorf("sms.ru delivery error: %s (code %d)", text, item.StatusCode)
	}
	return nil
}

type smsRuResponse struct {
	Status     string                 `json:"status"`
	StatusCode int                    `json:"status_code"`
	StatusText string                 `json:"status_text"`
	SMS        map[string]smsRuSMSItem `json:"sms"`
}

type smsRuSMSItem struct {
	Status     string `json:"status"`
	StatusCode int    `json:"status_code"`
	StatusText string `json:"status_text"`
	SMSID      string `json:"sms_id"`
}
