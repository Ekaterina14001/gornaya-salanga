package handler

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/middleware"
	"github.com/gornaya-salanga/backend/internal/service"
)

func (h *Handler) UDSSettings(c *gin.Context) {
	data, err := h.uds.Settings(c.Request.Context(), middleware.GetPOSSystem(c))
	if err != nil {
		udsFail(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) UDSFindCustomer(c *gin.Context) {
	total, _ := strconv.ParseFloat(c.Query("total"), 64)
	skip, _ := strconv.ParseFloat(c.Query("skipLoyaltyTotal"), 64)
	unred, _ := strconv.ParseFloat(c.Query("unredeemableTotal"), 64)
	data, err := h.uds.Find(c.Request.Context(), middleware.GetPOSSystem(c), c.Query("code"), c.Query("phone"), c.Query("uid"), total, skip, unred)
	if err != nil {
		udsFail(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) UDSGetCustomer(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"errorCode": "notFound", "message": "customer not found"})
		return
	}
	data, err := h.uds.GetCustomer(c.Request.Context(), middleware.GetPOSSystem(c), id)
	if err != nil {
		udsFail(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) UDSCalc(c *gin.Context) {
	var req service.UDSOperationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"errorCode": "badRequest", "message": "invalid request body"})
		return
	}
	data, err := h.uds.Calc(c.Request.Context(), middleware.GetPOSSystem(c), &req)
	if err != nil {
		udsFail(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) UDSCreateOperation(c *gin.Context) {
	var req service.UDSOperationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"errorCode": "badRequest", "message": "invalid request body"})
		return
	}
	data, err := h.uds.Create(c.Request.Context(), middleware.GetPOSSystem(c), &req)
	if err != nil {
		udsFail(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) UDSListOperations(c *gin.Context) {
	maxN, _ := strconv.Atoi(c.DefaultQuery("max", "10"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))
	data, err := h.uds.ListOperations(c.Request.Context(), maxN, offset)
	if err != nil {
		udsFail(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) UDSGetOperation(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"errorCode": "notFound", "message": "operation not found"})
		return
	}
	data, err := h.uds.GetOperation(c.Request.Context(), id)
	if err != nil {
		udsFail(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func (h *Handler) UDSRefund(c *gin.Context) {
	id, err := strconv.ParseInt(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"errorCode": "notFound", "message": "operation not found"})
		return
	}
	var body struct {
		PartialAmount *float64 `json:"partialAmount"`
	}
	_ = c.ShouldBindJSON(&body)
	data, err := h.uds.Refund(c.Request.Context(), id, body.PartialAmount)
	if err != nil {
		udsFail(c, err)
		return
	}
	c.JSON(http.StatusOK, data)
}

func udsFail(c *gin.Context, err error) {
	code := "badRequest"
	message := err.Error()
	status := http.StatusBadRequest
	var udsErr *service.UDSError
	if errors.As(err, &udsErr) && udsErr != nil {
		code = udsErr.Code
		message = udsErr.Message
	}
	switch code {
	case "unauthorized":
		status = http.StatusUnauthorized
	case "notFound":
		status = http.StatusNotFound
	}
	c.JSON(status, gin.H{"errorCode": code, "message": message})
}
