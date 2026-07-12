package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/cache"
	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/gornaya-salanga/backend/internal/database"
	"github.com/gornaya-salanga/backend/internal/handler"
	"github.com/gornaya-salanga/backend/internal/push"
	"github.com/gornaya-salanga/backend/internal/repository"
	"github.com/gornaya-salanga/backend/internal/router"
	"github.com/gornaya-salanga/backend/internal/service"
	jwtutil "github.com/gornaya-salanga/backend/pkg/jwt"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func main() {
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
	log.Logger = log.Output(zerolog.ConsoleWriter{Out: os.Stderr})

	cfg, err := config.Load()
	if err != nil {
		log.Fatal().Err(err).Msg("load config")
	}

	gin.SetMode(cfg.GinMode)

	ctx := context.Background()
	pool, err := database.NewPool(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Warn().Err(err).Msg("database unavailable, running with limited functionality")
	}
	defer func() {
		if pool != nil {
			pool.Close()
		}
	}()

	redisClient, err := cache.NewClient(cfg.RedisURL)
	if err != nil {
		if cfg.RedisRequired {
			log.Fatal().Err(err).Msg("redis required but unavailable")
		}
		log.Warn().Err(err).Msg("redis unavailable, running without cache")
	} else {
		log.Info().Str("url", cfg.RedisURL).Msg("redis connected")
	}
	defer func() {
		if redisClient != nil {
			_ = redisClient.Close()
		}
	}()

	jwtManager := jwtutil.NewManager(cfg.JWTSecret, cfg.JWTRefreshSecret, cfg.JWTAccessTTL, cfg.JWTRefreshTTL)

	userRepo := repository.NewUserRepository(pool)
	bonusRepo := repository.NewBonusRepository(pool)
	contentRepo := repository.NewContentRepository(pool)
	notifRepo := repository.NewNotificationRepository(pool)
	messageRepo := repository.NewMessageRepository(pool)
	posRepo := repository.NewPOSRepository(pool)

	pushSender, err := push.NewFCMSender(ctx, cfg.FCMCredentialsFile)
	if err != nil {
		log.Warn().Err(err).Msg("FCM unavailable, in-app notifications only")
		pushSender = push.NoopSender{}
	}

	authSvc := service.NewAuthService(userRepo, bonusRepo, jwtManager, redisClient, cfg)
	userSvc := service.NewUserServiceWithMessages(userRepo, messageRepo)
	bonusSvc := service.NewBonusService(bonusRepo, userRepo, cfg)
	contentSvc := service.NewContentService(contentRepo, redisClient, cfg)
	notifSvc := service.NewNotificationService(notifRepo, pushSender)
	adminSvc := service.NewAdminService(userRepo, bonusRepo, contentRepo, notifRepo, notifSvc, messageRepo, posRepo, cfg)
	posSvc := service.NewPOSService(bonusRepo, userRepo, posRepo, cfg)

	h := handler.NewHandler(authSvc, userSvc, bonusSvc, contentSvc, notifSvc, adminSvc, posSvc, cfg, jwtManager, redisClient)

	engine := router.Setup(cfg, jwtManager, h, posRepo)

	srv := router.NewServer(":"+cfg.Port, engine)

	go func() {
		log.Info().Str("port", cfg.Port).Msg("starting API server")
		if err := srv.ListenAndServe(); err != nil {
			log.Fatal().Err(err).Msg("server failed")
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Error().Err(err).Msg("shutdown error")
	}
	log.Info().Msg("server stopped")
}
