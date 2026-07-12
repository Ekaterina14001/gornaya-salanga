package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/middleware"
	"github.com/gornaya-salanga/backend/pkg/response"
)

func (h *Handler) ListNotifications(c *gin.Context) {
	userID := middleware.GetUserID(c)
	items, err := h.notif.List(c.Request.Context(), userID)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, items)
}

func (h *Handler) MarkNotificationRead(c *gin.Context) {
	userID := middleware.GetUserID(c)
	id := c.Param("id")
	if err := h.notif.MarkRead(c.Request.Context(), userID, id); err != nil {
		response.NotFound(c, err.Error())
		return
	}
	response.NoContent(c)
}

func (h *Handler) RegisterDevice(c *gin.Context) {
	var req struct {
		Token    string `json:"token" validate:"required"`
		Platform string `json:"platform"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	userID := middleware.GetUserID(c)
	if err := h.notif.RegisterDevice(c.Request.Context(), userID, req.Token, req.Platform); err != nil {
		response.Internal(c, "failed to register device")
		return
	}
	response.OK(c, gin.H{"registered": true})
}
