package email

func passwordResetBody(code, _ string) (subject, text, html string) {
	subject = "Код для сброса пароля — Горная Саланга"
	text = "Вы запросили сброс пароля в приложении «Горная Саланга».\n\n"
	text += "Ваш код: " + code + "\n\n"
	text += "Код действует 30 минут. Если вы не запрашивали сброс, проигнорируйте письмо."

	html = "<p>Вы запросили сброс пароля в приложении «Горная Саланга».</p>"
	html += `<p style="font-size:28px;font-weight:bold;letter-spacing:4px">` + code + `</p>`
	html += "<p>Код действует 30 минут.</p>"
	return subject, text, html
}

func emailVerifyBody(code, _ string) (subject, text, html string) {
	subject = "Код подтверждения email — Горная Саланга"
	text = "Подтвердите email для приложения «Горная Саланга».\n\n"
	text += "Ваш код: " + code + "\n\n"
	text += "Код действует 24 часа."

	html = "<p>Подтвердите email для приложения «Горная Саланга».</p>"
	html += `<p style="font-size:28px;font-weight:bold;letter-spacing:4px">` + code + `</p>`
	html += "<p>Код действует 24 часа.</p>"
	return subject, text, html
}
