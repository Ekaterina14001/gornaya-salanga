package service

import (
	"context"

	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/internal/repository"
)

type UserService struct {
	users *repository.UserRepository
	msgs  *repository.MessageRepository
}

func NewUserService(users *repository.UserRepository) *UserService {
	return &UserService{users: users}
}

func NewUserServiceWithMessages(users *repository.UserRepository, msgs *repository.MessageRepository) *UserService {
	return &UserService{users: users, msgs: msgs}
}

func (s *UserService) GetByID(ctx context.Context, id string) (*model.User, error) {
	return s.users.GetByID(ctx, id)
}

func (s *UserService) Update(ctx context.Context, id string, req *model.UpdateProfileRequest) (*model.User, error) {
	return s.users.Update(ctx, id, req)
}

func (s *UserService) SendContact(ctx context.Context, userID string, req *model.ContactRequest) (*model.UserMessage, error) {
	if s.msgs == nil {
		return nil, repository.ErrNotFound
	}
	return s.msgs.Create(ctx, userID, req.Subject, req.Body)
}

func (s *UserService) ListMyMessages(ctx context.Context, userID string) ([]model.UserMessage, error) {
	if s.msgs == nil {
		return []model.UserMessage{}, nil
	}
	return s.msgs.ListByUser(ctx, userID)
}
