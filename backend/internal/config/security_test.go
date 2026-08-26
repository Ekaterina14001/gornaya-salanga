package config

import "testing"

func TestValidateForProduction_skipsDebug(t *testing.T) {
	cfg := &Config{GinMode: "debug", JWTSecret: "dev-jwt-secret-change-in-production"}
	if err := cfg.ValidateForProduction(); err != nil {
		t.Fatal(err)
	}
}

func TestValidateForProduction_catchesWeakSecrets(t *testing.T) {
	cfg := &Config{
		GinMode:          "release",
		JWTSecret:        "dev-jwt-secret-change-in-production",
		JWTRefreshSecret: "abcdefghijklmnopqrstuvwxyz123456",
		RedisRequired:    false,
		SMSMode:          "log",
		EmailMode:        "log",
		PosAPIKeys:       map[string]string{"Shelter": "dev-shelter-key"},
		DatabaseURL:      "postgres://salanga:salanga@localhost/db",
	}
	err := cfg.ValidateForProduction()
	if err == nil {
		t.Fatal("expected validation error")
	}
}

func TestDevAuthBypassEnabled(t *testing.T) {
	debug := &Config{GinMode: "debug"}
	if !debug.DevAuthBypassEnabled() {
		t.Fatal("debug should allow dev auth bypass")
	}
	release := &Config{GinMode: "release"}
	if release.DevAuthBypassEnabled() {
		t.Fatal("release must not allow dev auth bypass")
	}
}
