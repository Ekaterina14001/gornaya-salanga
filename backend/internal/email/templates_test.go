package email

import (
	"strings"
	"testing"
)

func TestPasswordResetBody(t *testing.T) {
	subject, text, html := passwordResetBody("482913", "")
	if subject == "" || text == "" || html == "" {
		t.Fatal("empty template parts")
	}
	if !strings.Contains(text, "482913") || !strings.Contains(html, "482913") {
		t.Fatal("code missing from body")
	}
}

func TestEmailVerifyBody(t *testing.T) {
	subject, text, html := emailVerifyBody("482913", "")
	if subject == "" || text == "" || html == "" {
		t.Fatal("empty template parts")
	}
	if !strings.Contains(text, "482913") || !strings.Contains(html, "482913") {
		t.Fatal("code missing from body")
	}
}
