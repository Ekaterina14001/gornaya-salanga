package push

import "context"

type Sender interface {
	Enabled() bool
	SendToTokens(ctx context.Context, tokens []string, title, body string, data map[string]string) ([]string, error)
}
