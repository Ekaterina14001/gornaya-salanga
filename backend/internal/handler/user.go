package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/middleware"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/pkg/response"
	"github.com/gornaya-salanga/backend/pkg/validator"
)

func (h *Handler) GetMe(c *gin.Context) {
	userID := middleware.GetUserID(c)
	user, err := h.users.GetByID(c.Request.Context(), userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}
	response.OK(c, user)
}

func (h *Handler) UpdateMe(c *gin.Context) {
	userID := middleware.GetUserID(c)
	var req model.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	if err := validator.Validate(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	user, err := h.users.Update(c.Request.Context(), userID, &req)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.OK(c, user)
}

func (h *Handler) SendContact(c *gin.Context) {
	userID := middleware.GetUserID(c)
	var req model.ContactRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	if err := validator.Validate(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	msg, err := h.users.SendContact(c.Request.Context(), userID, &req)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.Created(c, msg)
}

func (h *Handler) GetMyMessages(c *gin.Context) {
	userID := middleware.GetUserID(c)
	items, err := h.users.ListMyMessages(c.Request.Context(), userID)
	if err != nil {
		response.Internal(c, "list messages failed")
		return
	}
	response.OK(c, items)
}
