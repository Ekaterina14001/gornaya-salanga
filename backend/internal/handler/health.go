package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/pkg/response"
)

func (h *Handler) Health(c *gin.Context) {
	ctx := c.Request.Context()
	status := "ok"
	redisStatus := "unavailable"
	if h.redis != nil {
		if err := h.redis.Ping(ctx).Err(); err == nil {
			redisStatus = "ok"
		} else {
			redisStatus = "error"
			status = "degraded"
		}
	} else if h.cfg.RedisRequired {
		status = "degraded"
	}

	response.OK(c, gin.H{
		"status": status,
		"redis":  redisStatus,
	})
}
