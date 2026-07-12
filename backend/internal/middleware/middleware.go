package middleware

import (
	"net/http"
	"strings"
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

func APIKey(validKeys map[string]string) gin.HandlerFunc {
	return func(c *gin.Context) {
		key := c.GetHeader("X-API-Key")
		if key == "" {
			response.Unauthorized(c, "missing API key")
			c.Abort()
			return
		}
		for system, valid := range validKeys {
			if key == valid {
				c.Set("posSystem", system)
				c.Next()
				return
			}
		}
		response.Unauthorized(c, "invalid API key")
		c.Abort()
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
		for system, valid := range validKeys {
			if key == valid {
				c.Set("posSystem", system)
				c.Next()
				return
			}
		}
		if posRepo != nil {
			system, err := posRepo.ValidateAPIKey(c.Request.Context(), key)
			if err == nil && system != "" {
				c.Set("posSystem", system)
				c.Next()
				return
			}
		}
		response.Unauthorized(c, "invalid API key")
		c.Abort()
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
	limit   int
	window  time.Duration
	buckets map[string][]time.Time
}

func NewMemoryRateLimiter(limit int, window time.Duration) RateLimiter {
	return &memoryRateLimiter{limit: limit, window: window, buckets: map[string][]time.Time{}}
}

func (r *memoryRateLimiter) Allow(key string) bool {
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
				Error: &response.ErrorBody{Code: "rate_limited", Message: "too many requests"},
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
