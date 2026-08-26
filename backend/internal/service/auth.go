package service



import (

	"context"

	"crypto/rand"

	"crypto/sha256"

	"encoding/hex"

	"errors"

	"fmt"

	"math/big"

	"strings"

	"sync"

	"time"



	"github.com/gornaya-salanga/backend/internal/config"

	"github.com/gornaya-salanga/backend/internal/model"

	"github.com/gornaya-salanga/backend/internal/repository"

	"github.com/gornaya-salanga/backend/internal/email"

	"github.com/gornaya-salanga/backend/internal/sms"

	jwtutil "github.com/gornaya-salanga/backend/pkg/jwt"

	"github.com/redis/go-redis/v9"

	"github.com/rs/zerolog/log"

)



var devPasswordResetCodes sync.Map

var devPhoneCodes sync.Map



type AuthService struct {

	users  *repository.UserRepository

	bonus  *repository.BonusRepository

	jwt    *jwtutil.Manager

	redis  *redis.Client

	cfg    *config.Config

	sms    sms.Sender

	mail   email.Sender

}



func NewAuthService(users *repository.UserRepository, bonus *repository.BonusRepository, jwt *jwtutil.Manager, redis *redis.Client, cfg *config.Config, smsSender sms.Sender, mailSender email.Sender) *AuthService {

	return &AuthService{users: users, bonus: bonus, jwt: jwt, redis: redis, cfg: cfg, sms: smsSender, mail: mailSender}

}



func (s *AuthService) Register(ctx context.Context, req *model.RegisterRequest) (*model.AuthResponse, error) {

	phone, err := sms.FormatPhoneE164(req.Phone)
	if err != nil {
		return nil, errors.New("invalid phone number")
	}
	req.Phone = phone

	hash, err := repository.HashPassword(req.Password)
	if err != nil {
		return nil, err
	}

	existing, err := s.users.FindByPhone(ctx, phone)
	if err == nil {
		if existing.PhoneVerified {
			return nil, repository.ErrPhoneTaken
		}
		user, err := s.users.UpdateUnverifiedGuest(ctx, existing.ID, req, hash)
		if err != nil {
			return nil, err
		}
		_ = s.bonus.CreateAccount(ctx, user.ID)
	} else if !errors.Is(err, repository.ErrNotFound) {
		return nil, err
	} else {
		user, err := s.users.Create(ctx, req, hash)
		if err != nil {
			return nil, err
		}
		_ = s.bonus.CreateAccount(ctx, user.ID)
	}

	if err := s.users.SetPhoneVerified(ctx, phone); err != nil {
		return nil, err
	}

	return s.Login(ctx, req.Email, req.Password)
}



func (s *AuthService) Login(ctx context.Context, login, password string) (*model.AuthResponse, error) {

	user, hash, err := s.users.FindByLogin(ctx, login)

	if err != nil {

		return nil, errors.New("invalid credentials")

	}

	if user.Blocked {

		return nil, errors.New("account blocked")

	}

	if !repository.CheckPassword(hash, password) {

		if s.cfg.DevAuthBypassEnabled() &&
			((login == "admin@gornayasalanga.ru" && password == "admin123") ||
				(login != "admin@gornayasalanga.ru" && password == "guest123")) {
			// dev-only demo login when seed password hash mismatch
		} else {

			return nil, errors.New("invalid credentials")

		}

	}



	pair, jti, refreshExp, err := s.jwt.GeneratePair(user.ID, user.Role)

	if err != nil {

		return nil, err

	}



	tokenHash := hashToken(jti)

	_ = s.users.SaveRefreshToken(ctx, user.ID, tokenHash, refreshExp)



	if s.redis != nil {

		_ = s.redis.Set(ctx, "refresh:"+tokenHash, user.ID, time.Until(refreshExp)).Err()

	}



	deviceSecret, err := s.users.GetDeviceSecret(ctx, user.ID)

	if err != nil || deviceSecret == "" {

		deviceSecret, err = repository.GenerateDeviceSecret()

		if err != nil {

			return nil, err

		}

		_ = s.users.SetDeviceSecret(ctx, user.ID, deviceSecret)

	}



	_ = s.users.TouchLastActivity(ctx, user.ID)



	return &model.AuthResponse{

		AccessToken:  pair.AccessToken,

		RefreshToken: pair.RefreshToken,

		ExpiresIn:    pair.ExpiresIn,

		DeviceSecret: deviceSecret,

		User:         user,

	}, nil

}



func (s *AuthService) Refresh(ctx context.Context, refreshToken string) (*model.AuthResponse, error) {

	claims, err := s.jwt.ParseRefresh(refreshToken)

	if err != nil {

		return nil, errors.New("invalid refresh token")

	}



	tokenHash := hashToken(claims.ID)

	userID := claims.Subject



	if s.redis != nil {

		stored, err := s.redis.Get(ctx, "refresh:"+tokenHash).Result()

		if err == nil && stored != "" {

			userID = stored

		} else {

			uid, err := s.users.FindRefreshToken(ctx, tokenHash)

			if err != nil {

				return nil, errors.New("invalid refresh token")

			}

			userID = uid

		}

	} else {

		uid, err := s.users.FindRefreshToken(ctx, tokenHash)

		if err != nil {

			return nil, errors.New("invalid refresh token")

		}

		userID = uid

	}



	user, err := s.users.GetByID(ctx, userID)

	if err != nil {

		return nil, errors.New("user not found")

	}



	_ = s.users.RevokeRefreshToken(ctx, tokenHash)

	if s.redis != nil {

		_ = s.redis.Del(ctx, "refresh:"+tokenHash).Err()

	}



	pair, jti, refreshExp, err := s.jwt.GeneratePair(user.ID, user.Role)

	if err != nil {

		return nil, err

	}

	newHash := hashToken(jti)

	_ = s.users.SaveRefreshToken(ctx, user.ID, newHash, refreshExp)

	if s.redis != nil {

		_ = s.redis.Set(ctx, "refresh:"+newHash, user.ID, time.Until(refreshExp)).Err()

	}



	return &model.AuthResponse{

		AccessToken:  pair.AccessToken,

		RefreshToken: pair.RefreshToken,

		ExpiresIn:    pair.ExpiresIn,

		User:         user,

	}, nil

}



func (s *AuthService) VerifyPhone(ctx context.Context, req *model.VerifyPhoneRequest) error {

	phone, err := sms.FormatPhoneE164(req.Phone)
	if err != nil {
		return errors.New("invalid phone number")
	}
	req.Phone = phone

	code, err := s.getPhoneCode(ctx, req.Phone)

	if err != nil || code != req.Code {

		if s.cfg.SMSDevBypassEnabled() && req.Code == "123456" {

			_ = s.users.SetPhoneVerified(ctx, req.Phone)

			return nil

		}

		return errors.New("invalid verification code")

	}

	if err := s.users.SetPhoneVerified(ctx, req.Phone); err != nil {

		return err

	}

	if s.redis != nil {

		_ = s.redis.Del(ctx, "verify:phone:"+req.Phone).Err()

	} else {

		devPhoneCodes.Delete(req.Phone)

	}

	return nil

}



func (s *AuthService) VerifyEmail(ctx context.Context, email, code string) error {
	email = normalizeEmail(email)
	code = strings.TrimSpace(code)
	if email == "" || code == "" {
		return errors.New("invalid verification code")
	}

	stored, err := s.getEmailCode(ctx, email)
	if err != nil || stored != code {
		return errors.New("invalid or expired code")
	}

	userID, err := s.users.FindIDByEmail(ctx, email)
	if err != nil {
		return errors.New("invalid or expired code")
	}

	if err := s.users.SetEmailVerified(ctx, userID); err != nil {
		return err
	}

	if s.redis != nil {
		_ = s.redis.Del(ctx, "verify:email:"+email).Err()
	}

	return nil
}



func (s *AuthService) ForgotPassword(ctx context.Context, email string) error {

	email = normalizeEmail(email)

	_, err := s.users.FindIDByEmail(ctx, email)

	if err != nil {

		return nil

	}

	code, err := randomCode(6)

	if err != nil {

		return err

	}

	if s.redis != nil {

		_ = s.redis.Set(ctx, resetCodeKey(email), code, 30*time.Minute).Err()

	} else {

		devPasswordResetCodes.Store(email, code)

	}

	if err := s.mail.SendPasswordReset(ctx, email, code); err != nil {
		log.Warn().Err(err).Str("email", email).Msg("password reset email failed")
	}

	return nil

}



func (s *AuthService) ResetPassword(ctx context.Context, email, code, newPassword string) error {

	email = normalizeEmail(email)
	code = strings.TrimSpace(code)

	if email == "" || code == "" {

		return errors.New("invalid reset code")

	}

	stored, err := s.getResetCode(ctx, email)
	if err != nil || stored != code {
		if !(s.cfg.EmailDevBypassEnabled() && code == "123456") {
			return errors.New("invalid or expired code")
		}
	}

	userID, err := s.users.FindIDByEmail(ctx, email)
	if err != nil {
		return errors.New("invalid or expired code")
	}

	hash, err := repository.HashPassword(newPassword)

	if err != nil {

		return err

	}

	if err := s.users.UpdatePassword(ctx, userID, hash); err != nil {

		return err

	}

	if s.redis != nil {

		_ = s.redis.Del(ctx, resetCodeKey(email)).Err()

	} else {

		devPasswordResetCodes.Delete(email)

	}

	return nil

}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func resetCodeKey(email string) string {
	return "reset:password:" + normalizeEmail(email)
}

func (s *AuthService) getResetCode(ctx context.Context, email string) (string, error) {
	email = normalizeEmail(email)
	if s.redis != nil {
		return s.redis.Get(ctx, resetCodeKey(email)).Result()
	}
	if v, ok := devPasswordResetCodes.Load(email); ok {
		if code, ok := v.(string); ok {
			return code, nil
		}
	}
	return "", errors.New("no code")
}



func (s *AuthService) VerifyQR(ctx context.Context, token string) (*model.QRVerifyResponse, error) {

	unverified := jwtutil.ParseQRUnverified(token)

	if unverified == "" {

		return nil, errors.New("invalid qr token")

	}

	secret, err := s.users.GetDeviceSecret(ctx, unverified)

	if err != nil {

		return nil, errors.New("invalid qr token")

	}

	parsed, err := jwtutil.VerifyQR(secret, token)

	if err != nil {

		return nil, errors.New("invalid qr token")

	}

	account, err := s.bonus.GetAccount(ctx, parsed.UserID)

	if err != nil {

		return nil, err

	}

	return &model.QRVerifyResponse{UserID: parsed.UserID, BonusBalance: account.Balance}, nil

}



func (s *AuthService) sendEmailVerification(ctx context.Context, userID, emailAddr string) error {
	if emailAddr == "" {
		return nil
	}
	emailAddr = normalizeEmail(emailAddr)
	code, err := randomCode(6)
	if err != nil {
		return err
	}
	if s.redis != nil {
		_ = s.redis.Set(ctx, "verify:email:"+emailAddr, code, 24*time.Hour).Err()
	} else {
		return nil
	}
	if err := s.mail.SendEmailVerification(ctx, emailAddr, code); err != nil {
		log.Warn().Err(err).Str("email", emailAddr).Msg("verification email failed")
	}
	return nil
}

func (s *AuthService) storePhoneCode(ctx context.Context, phone string) error {

	formatted, err := sms.FormatPhoneE164(phone)
	if err != nil {
		return err
	}
	phone = formatted

	code, err := randomCode(6)

	if err != nil {

		return err

	}

	if s.redis != nil {

		_ = s.redis.Set(ctx, "verify:phone:"+phone, code, 10*time.Minute).Err()

	} else {

		devPhoneCodes.Store(phone, code)

	}

	if err := s.sms.SendVerificationCode(ctx, phone, code); err != nil {

		return fmt.Errorf("send sms: %w", err)

	}

	return nil

}



func (s *AuthService) getPhoneCode(ctx context.Context, phone string) (string, error) {

	if s.redis != nil {

		return s.redis.Get(ctx, "verify:phone:"+phone).Result()

	}

	if v, ok := devPhoneCodes.Load(phone); ok {

		if code, ok := v.(string); ok {

			return code, nil

		}

	}

	return "", errors.New("no code")

}



func (s *AuthService) getEmailCode(ctx context.Context, email string) (string, error) {
	if s.redis == nil {
		return "", errors.New("no redis")
	}
	return s.redis.Get(ctx, "verify:email:"+email).Result()
}



func randomCode(length int) (string, error) {

	max := big.NewInt(1000000)

	n, err := rand.Int(rand.Reader, max)

	if err != nil {

		return "", err

	}

	return fmt.Sprintf("%06d", n.Int64()), nil

}



func randomToken(n int) (string, error) {

	b := make([]byte, n)

	if _, err := rand.Read(b); err != nil {

		return "", err

	}

	return hex.EncodeToString(b), nil

}



func hashToken(jti string) string {

	h := sha256.Sum256([]byte(jti))

	return hex.EncodeToString(h[:])

}


