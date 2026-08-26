package repository

import (
	"errors"
	"strings"

	"github.com/jackc/pgx/v5/pgconn"
)

var (
	ErrPhoneTaken = errors.New("Этот номер телефона уже зарегистрирован. Войдите в аккаунт.")
	ErrEmailTaken = errors.New("Этот email уже зарегистрирован. Войдите в аккаунт.")
)

func mapUniqueViolation(err error) error {
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23505" {
		return err
	}
	constraint := strings.ToLower(pgErr.ConstraintName)
	switch {
	case strings.Contains(constraint, "phone"):
		return ErrPhoneTaken
	case strings.Contains(constraint, "email"):
		return ErrEmailTaken
	default:
		return err
	}
}
