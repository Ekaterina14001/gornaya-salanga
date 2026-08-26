package config

import (
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	DatabaseURL       string
	RedisURL          string
	JWTSecret         string
	JWTRefreshSecret  string
	JWTAccessTTL      time.Duration
	JWTRefreshTTL     time.Duration
	Port              string
	GinMode           string
	CORSOrigins       []string
	AdminOrigin       string
	RateLimitQRVerify int
	RateLimitQRWindow time.Duration
	RateLimitAuth     int
	RateLimitAuthWindow time.Duration
	OpenWeatherAPIKey string
	PosAPIKeys        map[string]string
	QRTTLSeconds      int
	FCMCredentialsFile string
	RedisRequired      bool
	SMSMode            string
	SMSRuAPIID         string
	SMSRuFrom          string
	SMSMessageTemplate string
	SMSRuTest          bool
	EmailMode          string
	SMTPHost           string
	SMTPPort           int
	SMTPTLS            string
	SMTPUser           string
	SMTPPassword       string
	SMTPFrom           string
	SMTPFromName       string
	AppPublicURL       string
}

func Load() (*Config, error) {
	_ = godotenv.Load()

	cfg := &Config{
		DatabaseURL:       getEnv("DATABASE_URL", "postgres://salanga:salanga@localhost:5432/gornaya_salanga?sslmode=disable"),
		RedisURL:          getEnv("REDIS_URL", "redis://127.0.0.1:6379/0"),
		JWTSecret:         getEnv("JWT_SECRET", "dev-jwt-secret-change-in-production"),
		JWTRefreshSecret:  getEnv("JWT_REFRESH_SECRET", "dev-refresh-secret-change-in-production"),
		Port:              getEnv("PORT", "8080"),
		GinMode:           getEnv("GIN_MODE", "debug"),
		AdminOrigin:       getEnv("ADMIN_ORIGIN", "http://localhost:5173"),
		OpenWeatherAPIKey: getEnv("OPENWEATHERMAP_API_KEY", ""),
		QRTTLSeconds:       getEnvInt("QR_TTL_SECONDS", 60),
		RateLimitQRVerify:  getEnvInt("RATE_LIMIT_QR_VERIFY", 10),
		RateLimitAuth:      getEnvInt("RATE_LIMIT_AUTH", 20),
		FCMCredentialsFile: getEnv("FCM_CREDENTIALS_FILE", ""),
		RedisRequired:      getEnvBool("REDIS_REQUIRED", false),
		SMSMode:            getEnv("SMS_MODE", "log"),
		SMSRuAPIID:         getEnv("SMS_RU_API_ID", ""),
		SMSRuFrom:          getEnv("SMS_RU_FROM", ""),
		SMSMessageTemplate: getEnv("SMS_MESSAGE_TEMPLATE", "Код подтверждения Горная Саланга: {code}"),
		SMSRuTest:          getEnvBool("SMS_RU_TEST", false),
		EmailMode:          getEnv("EMAIL_MODE", "log"),
		SMTPHost:           getEnv("SMTP_HOST", ""),
		SMTPPort:           getEnvInt("SMTP_PORT", 465),
		SMTPTLS:            getEnv("SMTP_TLS", ""),
		SMTPUser:           getEnv("SMTP_USER", ""),
		SMTPPassword:       getEnv("SMTP_PASSWORD", ""),
		SMTPFrom:           getEnv("SMTP_FROM", ""),
		SMTPFromName:       getEnv("SMTP_FROM_NAME", "Gornaya Salanga"),
		AppPublicURL:       strings.TrimRight(getEnv("APP_PUBLIC_URL", "http://localhost:5173"), "/"),
	}

	cfg.JWTAccessTTL = parseDuration(getEnv("JWT_ACCESS_TTL", "15m"), 15*time.Minute)
	cfg.JWTRefreshTTL = parseDuration(getEnv("JWT_REFRESH_TTL", "720h"), 720*time.Hour)
	cfg.RateLimitQRWindow = parseDuration(getEnv("RATE_LIMIT_QR_WINDOW", "1m"), time.Minute)
	cfg.RateLimitAuthWindow = parseDuration(getEnv("RATE_LIMIT_AUTH_WINDOW", "1m"), time.Minute)

	cors := getEnv("CORS_ORIGINS", "http://localhost:5173,http://127.0.0.1:5173")
	cfg.CORSOrigins = splitAndTrim(cors)

	cfg.PosAPIKeys = map[string]string{
		"Shelter": getEnv("POS_API_KEY_SHELTER", "dev-shelter-key"),
		"Bars":    getEnv("POS_API_KEY_BARS", "dev-bars-key"),
		"RKeeper": getEnv("POS_API_KEY_RKEEPER", "dev-rkeeper-key"),
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getEnvBool(key string, fallback bool) bool {
	if v := os.Getenv(key); v != "" {
		switch strings.ToLower(strings.TrimSpace(v)) {
		case "1", "true", "yes", "on":
			return true
		case "0", "false", "no", "off":
			return false
		}
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}

func parseDuration(v string, fallback time.Duration) time.Duration {
	d, err := time.ParseDuration(v)
	if err != nil {
		return fallback
	}
	return d
}

func (c *Config) SMSDevBypassEnabled() bool {
	return !c.IsProduction() && (strings.ToLower(strings.TrimSpace(c.SMSMode)) == "" || strings.ToLower(strings.TrimSpace(c.SMSMode)) == "log")
}

func (c *Config) EmailDevBypassEnabled() bool {
	return !c.IsProduction() && (strings.ToLower(strings.TrimSpace(c.EmailMode)) == "" || strings.ToLower(strings.TrimSpace(c.EmailMode)) == "log")
}

func splitAndTrim(s string) []string {
	parts := strings.Split(s, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}
