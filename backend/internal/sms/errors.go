package sms

import (
	"fmt"
	"strings"
)

func UserFacingError(err error) string {
	if err == nil {
		return ""
	}
	msg := err.Error()
	if strings.Contains(msg, "code 221") {
		return "SMS.ru: нужно создать и согласовать имя отправителя в личном кабинете (sms.ru → Отправители). Пока можно SMS_MODE=log для разработки."
	}
	if strings.Contains(msg, "code 201") {
		return "Недостаточно средств на балансе SMS.ru."
	}
	if strings.Contains(msg, "invalid phone") {
		return "Неверный формат номера телефона."
	}
	if strings.HasPrefix(msg, "send sms: ") {
		return strings.TrimPrefix(msg, "send sms: ")
	}
	return msg
}

func DeliveryErrorMessage(code int, statusText string) string {
	switch code {
	case 221:
		return "создайте буквенного отправителя в SMS.ru (раздел «Отправители») и укажите его в SMS_RU_FROM"
	case 201:
		return "недостаточно средств на балансе SMS.ru"
	default:
		if statusText != "" {
			return statusText
		}
		return fmt.Sprintf("ошибка SMS.ru (код %d)", code)
	}
}
