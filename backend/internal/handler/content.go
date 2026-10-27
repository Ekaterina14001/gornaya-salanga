package handler

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/pkg/response"
)

func (h *Handler) GetAbout(c *gin.Context) {
	data, err := h.content.GetAbout(c.Request.Context())
	if err != nil {
		response.Internal(c, "failed to get about")
		return
	}
	response.OK(c, data)
}

func (h *Handler) GetServices(c *gin.Context) {
	data, _ := h.content.GetServices(c.Request.Context())
	response.OK(c, data)
}

func (h *Handler) GetSchedule(c *gin.Context) {
	data, _ := h.content.GetSchedule(c.Request.Context())
	response.OK(c, data)
}

func (h *Handler) GetRules(c *gin.Context) {
	data, err := h.content.GetRules(c.Request.Context())
	if err != nil {
		response.Internal(c, "failed to get rules")
		return
	}
	if ruleType := normalizeRuleType(c.Query("type")); ruleType != "" {
		for _, item := range data {
			if item["ruleType"] == ruleType {
				response.OK(c, item)
				return
			}
		}
		response.OK(c, gin.H{})
		return
	}
	response.OK(c, data)
}

func normalizeRuleType(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "visit", "visiting":
		return "visiting"
	case "bonus":
		return "bonus"
	default:
		return value
	}
}

func (h *Handler) GetWebcams(c *gin.Context) {
	data, _ := h.content.GetWebcams(c.Request.Context())
	response.OK(c, data)
}

func (h *Handler) GetTrails(c *gin.Context) {
	data, _ := h.content.GetTrails(c.Request.Context())
	response.OK(c, data)
}

func (h *Handler) GetLifts(c *gin.Context) {
	data, _ := h.content.GetLifts(c.Request.Context())
	response.OK(c, data)
}

func (h *Handler) GetWeather(c *gin.Context) {
	data, _ := h.content.GetWeather(c.Request.Context())
	response.OK(c, data)
}

func clientPublicBase(c *gin.Context) string {
	scheme := "https"
	if p := strings.TrimSpace(c.GetHeader("X-Forwarded-Proto")); p != "" {
		scheme = p
	} else if c.Request.TLS == nil {
		scheme = "http"
	}
	host := strings.TrimSpace(c.Request.Host)
	if xh := strings.TrimSpace(c.GetHeader("X-Forwarded-Host")); xh != "" {
		host = strings.TrimSpace(strings.Split(xh, ",")[0])
	}
	if host == "" {
		return ""
	}
	return scheme + "://" + host
}

func (h *Handler) GetHeadliners(c *gin.Context) {
	apiBase := clientPublicBase(c)
	if apiBase == "" {
		apiBase = h.cfg.ResolvePublicAPIURL(c.Request.URL.Scheme, c.Request.Host)
	}
	data, err := h.content.GetHeadliners(c.Request.Context(), apiBase)
	if err != nil {
		response.Internal(c, "headliners failed")
		return
	}
	response.OK(c, data)
}
