package handler

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/middleware"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/pkg/response"
	"github.com/gornaya-salanga/backend/pkg/validator"
)

func (h *Handler) GetBonusBalance(c *gin.Context) {
	userID := middleware.GetUserID(c)
	account, err := h.bonus.GetBalance(c.Request.Context(), userID)
	if err != nil {
		response.OK(c, gin.H{"balance": 0, "totalEarned": 0, "totalSpent": 0})
		return
	}
	response.OK(c, account)
}

func (h *Handler) GetBonusHistory(c *gin.Context) {
	userID := middleware.GetUserID(c)
	page, pageSize := pagination(c)
	txType := c.Query("type")
	if txType != "earn" && txType != "spend" {
		txType = ""
	}
	result, err := h.bonus.GetHistory(c.Request.Context(), userID, txType, page, pageSize)
	if err != nil {
		response.Internal(c, "failed to list history")
		return
	}
	response.OK(c, result)
}

func (h *Handler) EarnBonus(c *gin.Context) {
	var req model.BonusEarnRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	if err := validator.Validate(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	system := middleware.GetPOSSystem(c)
	tx, err := h.bonus.Earn(c.Request.Context(), &req, system)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.Created(c, tx)
}

func (h *Handler) BonusSpend(c *gin.Context) {
	var req model.BonusSpendRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	if err := validator.Validate(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	system := middleware.GetPOSSystem(c)
	tx, err := h.bonus.Spend(c.Request.Context(), &req, system)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.Created(c, tx)
}

func (h *Handler) ExternalGetBonus(c *gin.Context) {
	userID := c.Param("id")
	account, err := h.bonus.GetBalance(c.Request.Context(), userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}
	response.OK(c, gin.H{"userId": userID, "balance": account.Balance})
}

func pagination(c *gin.Context) (int, int) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}
	return page, pageSize
}
