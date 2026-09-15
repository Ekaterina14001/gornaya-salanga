package middleware

import (
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/repository"
	jwtutil "github.com/gornaya-salanga/backend/pkg/jwt"
	"github.com/gornaya-salanga/backend/pkg/response"
	"github.com/rs/zerolog/log"
)

const (
	ContextUserID = "userID"
	ContextRole   = "role"
)

func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		c.Next()
		log.Info().
			Str("method", c.Request.Method).
			Str("path", c.Request.URL.Path).
			Int("status", c.Writer.Status()).
			Dur("duration", time.Since(start)).
			Msg("request")
	}
}

func JWT(jwtManager *jwtutil.Manager) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" || !strings.HasPrefix(header, "Bearer ") {
			response.Unauthorized(c, "missing authorization header")
			c.Abort()
			return
		}
		token := strings.TrimPrefix(header, "Bearer ")
		claims, err := jwtManager.ParseAccess(token)
		if err != nil {
			response.Unauthorized(c, "invalid or expired token")
			c.Abort()
			return
		}
		c.Set(ContextUserID, claims.UserID)
		c.Set(ContextRole, claims.Role)
		c.Next()
	}
}

func AdminOnly() gin.HandlerFunc {
	return func(c *gin.Context) {
		role, _ := c.Get(ContextRole)
		if role != "admin" {
			response.Forbidden(c, "admin access required")
			c.Abort()
			return
		}
		c.Next()
	}
}

func LookupPOSSystem(c *gin.Context, posRepo *repository.POSRepository, validKeys map[string]string, key string) (string, bool) {
	if key == "" {
		return "", false
	}
	for system, valid := range validKeys {
		if key == valid {
			return system, true
		}
	}
	if posRepo != nil {
		system, err := posRepo.ValidateAPIKey(c.Request.Context(), key)
		if err == nil && system != "" {
			return system, true
		}
	}
	return "", false
}

func APIKey(validKeys map[string]string) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := c.GetHeader("X-API-Key")
		if key == "" {
			response.Unauthorized(c, "missing API key")
			c.Abort()
			return
		}
		system, ok := LookupPOSSystem(c, nil, validKeys, key)
		if !ok {
			response.Unauthorized(c, "invalid API key")
			c.Abort()
			return
		}
		c.Set("posSystem", system)
		c.Next()
	}
}

func APIKeyWithDB(posRepo *repository.POSRepository, validKeys map[string]string) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := c.GetHeader("X-API-Key")
		if key == "" {
			response.Unauthorized(c, "missing API key")
			c.Abort()
			return
		}
		system, ok := LookupPOSSystem(c, posRepo, validKeys, key)
		if !ok {
			response.Unauthorized(c, "invalid API key")
			c.Abort()
			return
		}
		c.Set("posSystem", system)
		c.Next()
	}
}

func UDSBasic(companyID string, posRepo *repository.POSRepository, validKeys map[string]string) gin.HandlerFunc {
	return func(c *gin.Context) {
		if id := strings.TrimSpace(c.GetHeader("X-Origin-Request-Id")); id != "" {
			c.Header("X-Request-Id", id)
		}
		user, pass, ok := c.Request.BasicAuth()
		if !ok || strings.TrimSpace(pass) == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"errorCode": "unauthorized", "message": "invalid company ID or API Key"})
			c.Abort()
			return
		}
		if strings.TrimSpace(user) != strings.TrimSpace(companyID) {
			c.JSON(http.StatusUnauthorized, gin.H{"errorCode": "unauthorized", "message": "invalid company ID or API Key"})
			c.Abort()
			return
		}
		system, ok := LookupPOSSystem(c, posRepo, validKeys, pass)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"errorCode": "unauthorized", "message": "invalid company ID or API Key"})
			c.Abort()
			return
		}
		c.Set("posSystem", system)
		c.Next()
	}
}

func POSRequestLogger(posRepo *repository.POSRepository) gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Next()
		if posRepo == nil {
			return
		}
		system, _ := c.Get("posSystem")
		sys, _ := system.(string)
		if sys == "" {
			sys = "unknown"
		}
		_ = posRepo.LogRequest(c.Request.Context(), sys, c.Request.Method+" "+c.FullPath(), c.Writer.Status())
	}
}

type RateLimiter interface {
	Allow(key string) bool
}

type memoryRateLimiter struct {
	mu      sync.Mutex
	limit   int
	window  time.Duration
	buckets map[string][]time.Time
}

func NewMemoryRateLimiter(limit int, window time.Duration) RateLimiter {
	return &memoryRateLimiter{limit: limit, window: window, buckets: map[string][]time.Time{}}
}

func (r *memoryRateLimiter) Allow(key string) bool {
	r.mu.Lock()
	defer r.mu.Unlock()
	now := time.Now()
	cutoff := now.Add(-r.window)
	times := r.buckets[key]
	filtered := times[:0]
	for _, t := range times {
		if t.After(cutoff) {
			filtered = append(filtered, t)
		}
	}
	if len(filtered) >= r.limit {
		r.buckets[key] = filtered
		return false
	}
	filtered = append(filtered, now)
	r.buckets[key] = filtered
	return true
}

func RateLimit(limiter RateLimiter) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := c.ClientIP() + ":" + c.FullPath()
		if !limiter.Allow(key) {
			c.JSON(http.StatusTooManyRequests, response.Envelope{
				Error: &response.ErrorBody{Code: "rate_limited", Message: "Слишком много запросов, попробуйте позже"},
			})
			c.Abort()
			return
		}
		c.Next()
	}
}

func GetUserID(c *gin.Context) string {
	v, _ := c.Get(ContextUserID)
	s, _ := v.(string)
	return s
}

func GetRole(c *gin.Context) string {
	v, _ := c.Get(ContextRole)
	s, _ := v.(string)
	return s
}

func GetPOSSystem(c *gin.Context) string {
	v, _ := c.Get("posSystem")
	s, _ := v.(string)
	return s
}
