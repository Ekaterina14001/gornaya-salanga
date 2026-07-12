package validator

import (
	"errors"

	"github.com/go-playground/validator/v10"
)

var validate = validator.New()

func Validate(s any) error {
	return validate.Struct(s)
}

func ValidationErrors(err error) map[string]string {
	out := map[string]string{}
	if err == nil {
		return out
	}
	var verrs validator.ValidationErrors
	if !errors.As(err, &verrs) {
		out["_"] = err.Error()
		return out
	}
	for _, fe := range verrs {
		out[fe.Field()] = fe.Tag()
	}
	return out
}
