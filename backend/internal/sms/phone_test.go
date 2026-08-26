package sms

import "testing"

func TestNormalizePhone(t *testing.T) {
	tests := []struct {
		in   string
		want string
	}{
		{"+79001234567", "79001234567"},
		{"79001234567", "79001234567"},
		{"89001234567", "79001234567"},
		{"9001234567", "79001234567"},
		{"+7 (900) 123-45-67", "79001234567"},
	}
	for _, tt := range tests {
		got, err := NormalizePhone(tt.in)
		if err != nil {
			t.Fatalf("NormalizePhone(%q) error: %v", tt.in, err)
		}
		if got != tt.want {
			t.Fatalf("NormalizePhone(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestFormatPhoneE164(t *testing.T) {
	got, err := FormatPhoneE164("+7 (900) 123-45-67")
	if err != nil {
		t.Fatal(err)
	}
	if got != "+79001234567" {
		t.Fatalf("got %q", got)
	}
}

func TestNormalizePhoneInvalid(t *testing.T) {
	if _, err := NormalizePhone("123"); err == nil {
		t.Fatal("expected error for short phone")
	}
}
