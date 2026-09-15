package handler

import (
	"encoding/base64"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/gornaya-salanga/backend/internal/middleware"
	"github.com/gornaya-salanga/backend/internal/repository"
	"github.com/gornaya-salanga/backend/internal/service"
)

func TestUDSSettingsRequiresBasicAuth(t *testing.T) {
	gin.SetMode(gin.TestMode)
	cfg := &config.Config{
		UDSCompanyID: "1",
		PosAPIKeys:   map[string]string{"Bars": "test-bars-key"},
	}
	uds := service.NewUDSService(
		repository.NewBonusRepository(nil),
		repository.NewUserRepository(nil),
		repository.NewUDSRepository(nil),
		nil,
		cfg,
	)
	h := &Handler{uds: uds, cfg: cfg}
	r := gin.New()
	r.GET("/partner/v2/settings", middleware.UDSBasic(cfg.UDSCompanyID, nil, cfg.PosAPIKeys), h.UDSSettings)

	req := httptest.NewRequest(http.MethodGet, "/partner/v2/settings", nil)
	w := httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("unauthorized status=%d body=%s", w.Code, w.Body.String())
	}

	token := base64.StdEncoding.EncodeToString([]byte("1:test-bars-key"))
	req = httptest.NewRequest(http.MethodGet, "/partner/v2/settings", nil)
	req.Header.Set("Authorization", "Basic "+token)
	w = httptest.NewRecorder()
	r.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("ok status=%d body=%s", w.Code, w.Body.String())
	}
	body := w.Body.String()
	if !strings.Contains(body, "CHARGE_SCORES") || !strings.Contains(body, "Горная Саланга") {
		t.Fatalf("unexpected body %s", body)
	}
}
