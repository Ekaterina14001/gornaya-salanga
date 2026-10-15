package handler

import (
	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/gornaya-salanga/backend/internal/service"
	jwtutil "github.com/gornaya-salanga/backend/pkg/jwt"
	"github.com/redis/go-redis/v9"
)

type Handler struct {
	auth    *service.AuthService
	users   *service.UserService
	bonus   *service.BonusService
	content *service.ContentService
	notif   *service.NotificationService
	admin   *service.AdminService
	pos     *service.POSService
	uds     *service.UDSService
	farcards *service.FarCardsService
	cfg     *config.Config
	jwt     *jwtutil.Manager
	redis   *redis.Client
}

func NewHandler(
	auth *service.AuthService,
	users *service.UserService,
	bonus *service.BonusService,
	content *service.ContentService,
	notif *service.NotificationService,
	admin *service.AdminService,
	pos *service.POSService,
	uds *service.UDSService,
	farcards *service.FarCardsService,
	cfg *config.Config,
	jwt *jwtutil.Manager,
	redis *redis.Client,
) *Handler {
	return &Handler{
		auth: auth, users: users, bonus: bonus, content: content,
		notif: notif, admin: admin, pos: pos, uds: uds, farcards: farcards, cfg: cfg, jwt: jwt, redis: redis,
	}
}
