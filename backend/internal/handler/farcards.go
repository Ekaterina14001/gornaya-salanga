package handler

import (
	"context"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
)

func (h *Handler) farCardsXML(c *gin.Context, fn func(context.Context, []byte) (string, error)) {
	body, err := io.ReadAll(c.Request.Body)
	if err != nil {
		c.Data(http.StatusBadRequest, "text/xml; charset=utf-8", []byte(`<?xml version="1.0"?><Root><Error Result="1"/></Root>`))
		return
	}
	out, err := fn(c.Request.Context(), body)
	if err != nil {
		c.Data(http.StatusOK, "text/xml; charset=utf-8", []byte(out))
		return
	}
	c.Data(http.StatusOK, "text/xml; charset=utf-8", []byte(out))
}

func (h *Handler) FarCardsGetCardInfoEx(c *gin.Context) {
	h.farCardsXML(c, h.farcards.GetCardInfoXML)
}

func (h *Handler) FarCardsTransactionsEx(c *gin.Context) {
	h.farCardsXML(c, h.farcards.TransactionsXML)
}

func (h *Handler) FarCardsFindByQR(c *gin.Context) {
	h.farCardsXML(c, h.farcards.FindByQRXML)
}
