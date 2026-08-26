package sms

import (
	"fmt"
	"strings"
)

func NormalizePhone(phone string) (string, error) {
	digits := strings.Builder{}
	for _, r := range phone {
		if r >= '0' && r <= '9' {
			digits.WriteRune(r)
		}
	}
	n := digits.String()
	switch {
	case len(n) == 11 && n[0] == '8':
		n = "7" + n[1:]
	case len(n) == 10 && n[0] == '9':
		n = "7" + n
	case len(n) == 11 && n[0] == '7':
	default:
		return "", fmt.Errorf("invalid phone number")
	}
	if len(n) != 11 || n[0] != '7' {
		return "", fmt.Errorf("invalid phone number")
	}
	return n, nil
}

func FormatPhoneE164(phone string) (string, error) {
	n, err := NormalizePhone(phone)
	if err != nil {
		return "", err
	}
	return "+" + n, nil
}
