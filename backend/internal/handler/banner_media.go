package handler

import (
	"net/http"
	"net/url"
	"path/filepath"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/pkg/response"
)

func allowedBannerImageHost(host string) bool {
	host = strings.ToLower(strings.TrimSpace(host))
	return host == "www.salanga.ru" || host == "salanga.ru"
}

func (h *Handler) serveLocalUpload(c *gin.Context, parsed *url.URL) bool {
	if parsed == nil || !strings.HasPrefix(parsed.Path, "/uploads/") {
		return false
	}
	name := filepath.Base(parsed.Path)
	if name == "." || name == ".." || name == "/" {
		return false
	}
	dir := strings.TrimSpace(h.cfg.UploadDir)
	if dir == "" {
		return false
	}
	path := filepath.Join(dir, name)
	c.Header("Cache-Control", "public, max-age=3600")
	c.File(path)
	return true
}

func (h *Handler) GetBannerMedia(c *gin.Context) {
	raw := strings.TrimSpace(c.Query("url"))
	if raw == "" {
		response.BadRequest(c, "url required")
		return
	}
	parsed, err := url.Parse(raw)
	if err != nil || parsed.Scheme != "https" {
		response.BadRequest(c, "invalid url")
		return
	}
	if h.serveLocalUpload(c, parsed) {
		return
	}
	if !allowedBannerImageHost(parsed.Host) {
		response.BadRequest(c, "invalid url")
		return
	}

	client := &http.Client{Timeout: 20 * time.Second}
	req, err := http.NewRequestWithContext(c.Request.Context(), http.MethodGet, parsed.String(), nil)
	if err != nil {
		response.Internal(c, "fetch failed")
		return
	}
	req.Header.Set("User-Agent", "GornayaSalangaApp/1.0")
	req.Header.Set("Referer", "https://www.salanga.ru/")

	resp, err := client.Do(req)
	if err != nil || resp.StatusCode != http.StatusOK {
		if resp != nil {
			_ = resp.Body.Close()
		}
		response.NotFound(c, "image unavailable")
		return
	}
	defer resp.Body.Close()

	contentType := resp.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "image/jpeg"
	}
	c.Header("Cache-Control", "public, max-age=3600")
	c.DataFromReader(http.StatusOK, resp.ContentLength, contentType, resp.Body, nil)
}
