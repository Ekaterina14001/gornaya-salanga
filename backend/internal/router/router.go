package router

import (
	"net/http"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/gornaya-salanga/backend/internal/handler"
	"github.com/gornaya-salanga/backend/internal/middleware"
	"github.com/gornaya-salanga/backend/internal/repository"
	jwtutil "github.com/gornaya-salanga/backend/pkg/jwt"
)

func Setup(cfg *config.Config, jwtManager *jwtutil.Manager, h *handler.Handler, posRepo *repository.POSRepository) *gin.Engine {
	r := gin.New()
	r.Use(gin.Recovery())
	r.Use(middleware.Logger())

	corsCfg := cors.Config{
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "X-API-Key", "X-Origin-Request-Id", "X-Timestamp"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}
	if cfg.GinMode == "debug" {
		// Flutter web dev server uses a random localhost port.
		corsCfg.AllowOriginFunc = func(origin string) bool {
			if origin == "" {
				return true
			}
			if slices.Contains(cfg.CORSOrigins, origin) {
				return true
			}
			return strings.HasPrefix(origin, "http://localhost:") ||
				strings.HasPrefix(origin, "http://127.0.0.1:")
		}
	} else {
		corsCfg.AllowOrigins = cfg.CORSOrigins
	}
	r.Use(cors.New(corsCfg))

	uploadDir, _ := filepath.Abs(cfg.UploadDir)
	_ = os.MkdirAll(uploadDir, 0o755)
	r.Static("/uploads", uploadDir)

	r.GET("/health", h.Health)

	auth := r.Group("/api/auth")
	authLimiter := middleware.NewMemoryRateLimiter(cfg.RateLimitAuth, cfg.RateLimitAuthWindow)
	{
		auth.POST("/register", middleware.RateLimit(authLimiter), h.Register)
		auth.POST("/login", middleware.RateLimit(authLimiter), h.Login)
		auth.POST("/refresh", h.Refresh)
		auth.POST("/verify-phone", middleware.RateLimit(authLimiter), h.VerifyPhone)
		auth.POST("/verify-email", h.VerifyEmail)
		auth.POST("/forgot-password", middleware.RateLimit(authLimiter), h.ForgotPassword)
		auth.POST("/reset-password", middleware.RateLimit(authLimiter), h.ResetPassword)

		qrLimiter := middleware.NewMemoryRateLimiter(cfg.RateLimitQRVerify, cfg.RateLimitQRWindow)
		auth.POST("/qr/verify", middleware.RateLimit(qrLimiter), h.VerifyQR)
	}

	users := r.Group("/api/users")
	users.Use(middleware.JWT(jwtManager))
	{
		users.GET("/me", h.GetMe)
		users.PUT("/me", h.UpdateMe)
		users.GET("/me/messages", h.GetMyMessages)
		users.POST("/contact", h.SendContact)
	}

	bonus := r.Group("/api/bonus")
	{
		bonus.GET("/balance", middleware.JWT(jwtManager), h.GetBonusBalance)
		bonus.GET("/history", middleware.JWT(jwtManager), h.GetBonusHistory)

		posBonus := bonus.Group("")
		posBonus.Use(middleware.APIKeyWithDB(posRepo, cfg.PosAPIKeys), middleware.POSRequestLogger(posRepo))
		posBonus.POST("/earn", h.EarnBonus)
		posBonus.POST("/spend", h.BonusSpend)
	}

	content := r.Group("/api/content")
	{
		content.GET("/about", h.GetAbout)
		content.GET("/services", h.GetServices)
		content.GET("/schedule", h.GetSchedule)
		content.GET("/rules", h.GetRules)
		content.GET("/webcams", h.GetWebcams)
		content.GET("/trails", h.GetTrails)
		content.GET("/lifts", h.GetLifts)
		content.GET("/weather", h.GetWeather)
		content.GET("/headliners", h.GetHeadliners)
		content.GET("/banner-media", h.GetBannerMedia)
	}

	notifications := r.Group("/api/notifications")
	notifications.Use(middleware.JWT(jwtManager))
	{
		notifications.GET("", h.ListNotifications)
		notifications.PATCH("/:id/read", h.MarkNotificationRead)
		notifications.POST("/register-device", h.RegisterDevice)
	}

	external := r.Group("/api/external")
	external.Use(middleware.APIKeyWithDB(posRepo, cfg.PosAPIKeys), middleware.POSRequestLogger(posRepo))
	{
		external.GET("/user/:id/bonus", h.ExternalGetBonus)
		external.POST("/earn", h.EarnBonus)
		external.POST("/spend", h.BonusSpend)
	}

	partner := r.Group("/partner/v2")
	partner.Use(middleware.UDSBasic(cfg.UDSCompanyID, posRepo, cfg.PosAPIKeys), middleware.POSRequestLogger(posRepo))
	registerUDSPartner(partner, h)

	// Same protocol behind /api/ so existing host nginx `location /api/` proxies it.
	partnerAPI := r.Group("/api/partner/v2")
	partnerAPI.Use(middleware.UDSBasic(cfg.UDSCompanyID, posRepo, cfg.PosAPIKeys), middleware.POSRequestLogger(posRepo))
	registerUDSPartner(partnerAPI, h)

	fc := r.Group("/api/farcards")
	fc.Use(middleware.APIKeyWithDB(posRepo, cfg.PosAPIKeys), middleware.POSRequestLogger(posRepo))
	registerFarCards(fc, h)

	admin := r.Group("/api/admin")
	admin.Use(middleware.JWT(jwtManager), middleware.AdminOnly())
	{
		admin.GET("/dashboard", h.AdminDashboard)
		admin.GET("/users", h.AdminListUsers)
		admin.GET("/users/:id", h.AdminGetUser)
		admin.PATCH("/users/:id/block", h.AdminBlockUser)
		admin.POST("/users/:id/bonus/adjust", h.AdminAdjustUserBonus)
		admin.GET("/bonus/config", h.AdminGetBonusConfig)
		admin.PUT("/bonus/config", h.AdminUpdateBonusConfig)
		admin.GET("/bonus/config/audit", h.AdminBonusConfigAudit)
		admin.GET("/bonus/transactions", h.AdminListTransactions)
		admin.GET("/pos/keys", h.AdminListPOSKeys)
		admin.POST("/pos/keys", h.AdminCreatePOSKey)
		admin.DELETE("/pos/keys/:id", h.AdminRevokePOSKey)
		admin.GET("/pos/logs", h.AdminPOSLogs)
		admin.PUT("/content/about", h.AdminUpdateAbout)
		admin.PUT("/content/rules/:type", h.AdminUpdateRules)
		admin.POST("/content/services", h.AdminCreateService)
		admin.GET("/content/services", h.AdminListServices)
		admin.POST("/content/services/sync-salanga", h.AdminSyncSalangaServices)
		admin.GET("/content/headliners", h.AdminListHeadliners)
		admin.POST("/content/headliners", h.AdminCreateHeadliner)
		admin.PUT("/content/headliners/:id", h.AdminUpdateHeadliner)
		admin.DELETE("/content/headliners/:id", h.AdminDeleteHeadliner)
		admin.POST("/content/upload", h.AdminUploadContentImage)
		admin.PUT("/content/services/:id", h.AdminUpdateService)
		admin.DELETE("/content/services/:id", h.AdminDeleteService)
		admin.POST("/content/webcams", h.AdminCreateWebcam)
		admin.PUT("/content/webcams/:id", h.AdminUpdateWebcam)
		admin.POST("/content/trails", h.AdminCreateTrail)
		admin.PUT("/content/trails/:id", h.AdminUpdateTrail)
		admin.GET("/content/schedule", h.AdminListSchedule)
		admin.PUT("/content/schedule/:id", h.AdminUpdateSchedule)
		admin.GET("/content/lifts", h.AdminListLifts)
		admin.PUT("/content/lifts/:id", h.AdminUpdateLift)
		admin.POST("/content/lifts/sync-salanga", h.AdminSyncSalangaLifts)
		admin.POST("/notifications/broadcast", h.AdminBroadcast)
		admin.GET("/notifications/push-status", h.AdminPushStatus)
		admin.GET("/messages", h.AdminListMessages)
		admin.POST("/messages/:id/reply", h.AdminReplyMessage)
		admin.GET("/bonus/transactions/export", h.AdminExportTransactions)
	}

	return r
}

func registerFarCards(g *gin.RouterGroup, h *handler.Handler) {
	g.POST("/getcardinfoex", h.FarCardsGetCardInfoEx)
	g.POST("/getcardinfoex.php", h.FarCardsGetCardInfoEx)
	g.POST("/transactionsex", h.FarCardsTransactionsEx)
	g.POST("/transactionsex.php", h.FarCardsTransactionsEx)
	g.POST("/findbyqr", h.FarCardsFindByQR)
	g.POST("/findbyqr.php", h.FarCardsFindByQR)
}

func registerUDSPartner(partner *gin.RouterGroup, h *handler.Handler) {
	partner.GET("/settings", h.UDSSettings)
	partner.GET("/customers/find", h.UDSFindCustomer)
	partner.GET("/customers/:id", h.UDSGetCustomer)
	partner.POST("/operations/calc", h.UDSCalc)
	partner.POST("/operations", h.UDSCreateOperation)
	partner.GET("/operations", h.UDSListOperations)
	partner.GET("/operations/:id", h.UDSGetOperation)
	partner.POST("/operations/:id/refund", h.UDSRefund)
}

func NewServer(addr string, handler http.Handler) *http.Server {
	return &http.Server{
		Addr:              addr,
		Handler:           handler,
		ReadHeaderTimeout: 10 * time.Second,
	}
}
