package handler

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/gornaya-salanga/backend/pkg/response"
)

const maxUploadBytes = 8 << 20 // 8 MiB

var allowedUploadExt = map[string]string{
	".jpg":  "image/jpeg",
	".jpeg": "image/jpeg",
	".png":  "image/png",
	".webp": "image/webp",
}

func (h *Handler) AdminUploadContentImage(c *gin.Context) {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxUploadBytes)

	file, err := c.FormFile("file")
	if err != nil {
		response.BadRequest(c, "file required")
		return
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if _, ok := allowedUploadExt[ext]; !ok {
		response.BadRequest(c, "unsupported image type")
		return
	}

	dir := h.cfg.UploadDir
	if err := os.MkdirAll(dir, 0o755); err != nil {
		response.Internal(c, "upload dir unavailable")
		return
	}

	name := uuid.NewString() + ext
	dest := filepath.Join(dir, name)
	if err := c.SaveUploadedFile(file, dest); err != nil {
		response.Internal(c, "save failed")
		return
	}

	path := "/uploads/" + name
	publicURL := path
	if base := strings.TrimRight(h.cfg.ResolvePublicAPIURL(c.Request.URL.Scheme, c.Request.Host), "/"); base != "" {
		publicURL = base + path
	}

	response.OK(c, gin.H{
		"path": path,
		"url":  publicURL,
	})
}

func EnsureUploadDir(dir string) error {
	if strings.TrimSpace(dir) == "" {
		return fmt.Errorf("upload dir not configured")
	}
	return os.MkdirAll(dir, 0o755)
}
