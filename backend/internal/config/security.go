package config

import (
	"fmt"
	"strings"
)

const minJWTSecretLen = 32

var weakJWTSecrets = map[string]struct{}{
	"dev-jwt-secret-change-in-production":       {},
	"dev-refresh-secret-change-in-production":  {},
	"change-this-jwt-secret-min-32-chars":      {},
	"change-this-refresh-secret-min-32-chars":  {},
}

var weakPOSKeys = map[string]struct{}{
	"dev-shelter-key":  {},
	"dev-bars-key":     {},
	"dev-rkeeper-key":  {},
}

func (c *Config) IsProduction() bool {
	return strings.ToLower(strings.TrimSpace(c.GinMode)) == "release"
}

func (c *Config) DevAuthBypassEnabled() bool {
	return !c.IsProduction()
}

func (c *Config) ValidateForProduction() error {
	if !c.IsProduction() {
		return nil
	}
	var problems []string

	if err := validateJWTSecret("JWT_SECRET", c.JWTSecret); err != nil {
		problems = append(problems, err.Error())
	}
	if err := validateJWTSecret("JWT_REFRESH_SECRET", c.JWTRefreshSecret); err != nil {
		problems = append(problems, err.Error())
	}
	if c.JWTSecret == c.JWTRefreshSecret {
		problems = append(problems, "JWT_SECRET and JWT_REFRESH_SECRET must differ")
	}
	if !c.RedisRequired {
		problems = append(problems, "REDIS_REQUIRED must be true in production")
	}
	for name, key := range c.PosAPIKeys {
		if _, weak := weakPOSKeys[key]; weak || key == "" {
			problems = append(problems, fmt.Sprintf("POS API key for %s must be changed from dev default", name))
		}
	}
	if mode := strings.ToLower(c.SMSMode); mode == "" || mode == "log" {
		problems = append(problems, "SMS_MODE must be smsru in production")
	}
	if mode := strings.ToLower(c.EmailMode); mode == "" || mode == "log" {
		problems = append(problems, "EMAIL_MODE must be smtp in production")
	}
	if strings.Contains(c.DatabaseURL, "salanga:salanga@") {
		problems = append(problems, "DATABASE_URL must not use default dev password in production")
	}

	if len(problems) == 0 {
		return nil
	}
	return fmt.Errorf("production security check failed:\n- %s", strings.Join(problems, "\n- "))
}

func validateJWTSecret(name, value string) error {
	if len(value) < minJWTSecretLen {
		return fmt.Errorf("%s must be at least %d characters", name, minJWTSecretLen)
	}
	if _, weak := weakJWTSecrets[value]; weak {
		return fmt.Errorf("%s must not use default dev value", name)
	}
	return nil
}
