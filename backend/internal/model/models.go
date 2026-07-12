package model

import "time"

type User struct {
	ID            string     `json:"id"`
	FirstName     string     `json:"firstName"`
	LastName      string     `json:"lastName"`
	Phone         string     `json:"phone"`
	Email         string     `json:"email"`
	Role          string     `json:"role"`
	PhoneVerified bool       `json:"phoneVerified"`
	EmailVerified bool       `json:"emailVerified"`
	Blocked       bool       `json:"blocked"`
	LastActivity  *time.Time `json:"lastActivityAt,omitempty"`
	CreatedAt     time.Time  `json:"createdAt"`
	UpdatedAt     time.Time  `json:"updatedAt"`
}

type RegisterRequest struct {
	FirstName string `json:"firstName" validate:"required,min=1,max=100"`
	LastName  string `json:"lastName" validate:"required,min=1,max=100"`
	Phone     string `json:"phone" validate:"required"`
	Email     string `json:"email" validate:"required,email"`
	Password  string `json:"password" validate:"required,min=6"`
}

type LoginRequest struct {
	Login    string `json:"login" validate:"required"`
	Password string `json:"password" validate:"required"`
}

type UpdateProfileRequest struct {
	FirstName *string `json:"firstName" validate:"omitempty,min=1,max=100"`
	LastName  *string `json:"lastName" validate:"omitempty,min=1,max=100"`
	Email     *string `json:"email" validate:"omitempty,email"`
}

type VerifyPhoneRequest struct {
	Phone string `json:"phone" validate:"required"`
	Code  string `json:"code" validate:"required,len=6"`
}

type VerifyEmailRequest struct {
	Token string `json:"token" validate:"required"`
}

type AuthResponse struct {
	AccessToken  string `json:"accessToken"`
	RefreshToken string `json:"refreshToken"`
	ExpiresIn    int64  `json:"expiresIn"`
	DeviceSecret string `json:"deviceSecret,omitempty"`
	User         *User  `json:"user"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refreshToken" validate:"required"`
}

type QRVerifyRequest struct {
	Token string `json:"token" validate:"required"`
}

type QRVerifyResponse struct {
	UserID       string  `json:"userId"`
	BonusBalance float64 `json:"bonusBalance"`
}

type BonusAccount struct {
	ID          string    `json:"id"`
	UserID      string    `json:"userId"`
	Balance     float64   `json:"balance"`
	TotalEarned float64   `json:"totalEarned"`
	TotalSpent  float64   `json:"totalSpent"`
	UpdatedAt   time.Time `json:"updatedAt"`
}

type BonusTransaction struct {
	ID          string    `json:"id"`
	UserID      string    `json:"userId"`
	Type        string    `json:"type"`
	Amount      float64   `json:"amount"`
	Source      *string   `json:"source,omitempty"`
	OrderID     *string   `json:"orderId,omitempty"`
	Description *string   `json:"description,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
}

type BonusEarnRequest struct {
	UserID         string  `json:"userId" validate:"required,uuid"`
	PurchaseAmount float64 `json:"purchaseAmount" validate:"required,gt=0"`
	Source         string  `json:"source" validate:"required,oneof=Shelter Bars RKeeper"`
	OrderID        string  `json:"orderId" validate:"required"`
	Description    string  `json:"description"`
}

type BonusSpendRequest struct {
	UserID         string  `json:"userId" validate:"required,uuid"`
	Amount         float64 `json:"amount" validate:"required,gt=0"`
	PurchaseAmount float64 `json:"purchaseAmount" validate:"required,gt=0"`
	Source         string  `json:"source" validate:"required,oneof=Shelter Bars RKeeper"`
	OrderID        string  `json:"orderId" validate:"required"`
	Description    string  `json:"description"`
}

type Notification struct {
	ID        string         `json:"id"`
	UserID    string         `json:"userId"`
	Title     string         `json:"title"`
	Body      string         `json:"body"`
	Type      string         `json:"type"`
	Data      map[string]any `json:"data"`
	Read      bool           `json:"read"`
	CreatedAt time.Time      `json:"createdAt"`
}

type SendNotificationRequest struct {
	UserID string         `json:"userId" validate:"required,uuid"`
	Title  string         `json:"title" validate:"required"`
	Body   string         `json:"body" validate:"required"`
	Type   string         `json:"type" validate:"required"`
	Data   map[string]any `json:"data"`
}

type UserMessage struct {
	ID         string     `json:"id"`
	UserID     string     `json:"userId"`
	Subject    string     `json:"subject"`
	Body       string     `json:"body"`
	Status     string     `json:"status"`
	AdminReply *string    `json:"adminReply,omitempty"`
	RepliedAt  *time.Time `json:"repliedAt,omitempty"`
	CreatedAt  time.Time  `json:"createdAt"`
}

type ContactRequest struct {
	Subject string `json:"subject" validate:"required,min=3"`
	Body    string `json:"body" validate:"required,min=10"`
}

type BonusConfig struct {
	EarnPercentageGlobal    float64 `json:"earnPercentageGlobal"`
	EarnPercentageShelter   float64 `json:"earnPercentageShelter"`
	EarnPercentageBars      float64 `json:"earnPercentageBars"`
	EarnPercentageRKeeper   float64 `json:"earnPercentageRKeeper"`
	MaxSpendPercentage      float64 `json:"maxSpendPercentage"`
	BonusExpiryDays         int     `json:"bonusExpiryDays"`
	MinReceiptAmount        float64 `json:"minReceiptAmount"`
	QRTTLSeconds            int     `json:"qrTtlSeconds"`
}

type PaginatedResponse struct {
	Items      any   `json:"items"`
	Total      int64 `json:"total"`
	Page       int   `json:"page"`
	PageSize   int   `json:"pageSize"`
	TotalPages int   `json:"totalPages"`
}
