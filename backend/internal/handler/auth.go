package handler

import (
	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/pkg/response"
	"github.com/gornaya-salanga/backend/pkg/validator"
)

type loginBody struct {
	Login    string `json:"login"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *Handler) Login(c *gin.Context) {
	var body loginBody
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	login := body.Login
	if login == "" {
		login = body.Email
	}
	if login == "" || body.Password == "" {
		response.BadRequest(c, "login and password required")
		return
	}

	result, err := h.auth.Login(c.Request.Context(), login, body.Password)
	if err != nil {
		msg := err.Error()
		if msg == "invalid credentials" {
			response.Unauthorized(c, msg)
			return
		}
		if msg == "account blocked" {
			response.Forbidden(c, msg)
			return
		}
		response.Internal(c, "login failed")
		return
	}
	response.OK(c, result)
}

func (h *Handler) Register(c *gin.Context) {
	var req model.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	if err := validator.Validate(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	user, err := h.auth.Register(c.Request.Context(), &req)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.Created(c, user)
}

func (h *Handler) Refresh(c *gin.Context) {
	var req model.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	result, err := h.auth.Refresh(c.Request.Context(), req.RefreshToken)
	if err != nil {
		response.Unauthorized(c, "invalid refresh token")
		return
	}
	response.OK(c, result)
}

func (h *Handler) VerifyPhone(c *gin.Context) {
	var req model.VerifyPhoneRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	if err := h.auth.VerifyPhone(c.Request.Context(), &req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.OK(c, gin.H{"verified": true})
}

func (h *Handler) VerifyEmail(c *gin.Context) {
	var req model.VerifyEmailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	if err := h.auth.VerifyEmail(c.Request.Context(), req.Token); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.OK(c, gin.H{"verified": true})
}

func (h *Handler) ForgotPassword(c *gin.Context) {
	var body struct {
		Email string `json:"email"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Email == "" {
		response.BadRequest(c, "email required")
		return
	}
	_ = h.auth.ForgotPassword(c.Request.Context(), body.Email)
	response.OK(c, gin.H{"message": "if account exists, reset link sent"})
}

func (h *Handler) ResetPassword(c *gin.Context) {
	var body struct {
		Token       string `json:"token"`
		NewPassword string `json:"newPassword"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	if err := h.auth.ResetPassword(c.Request.Context(), body.Token, body.NewPassword); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.OK(c, gin.H{"message": "password reset"})
}

func (h *Handler) VerifyQR(c *gin.Context) {
	var req model.QRVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, "invalid request body")
		return
	}
	result, err := h.auth.VerifyQR(c.Request.Context(), req.Token)
	if err != nil {
		response.Unauthorized(c, "invalid qr token")
		return
	}
	response.OK(c, result)
}
