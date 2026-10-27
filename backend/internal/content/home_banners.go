package content

import (
	"net/url"
	"strings"
)

const SalangaSite = "https://www.salanga.ru"

// DefaultHomeBannerImages — картинки с salanga.ru по позиции (sort_order 0…2).
var DefaultHomeBannerImages = []string{
	SalangaSite + "/up/17/51a5c408d8-glavnayazima-02.jpg",
	SalangaSite + "/up/room/nomer-04.jpg",
	SalangaSite + "/yiiassets/easyimage/6/6917b199b8c40571210a89edf50a2b25.jpg",
}

func DefaultHomeBannerImage(sortOrder int) string {
	if sortOrder < 0 {
		sortOrder = 0
	}
	if sortOrder >= len(DefaultHomeBannerImages) {
		return DefaultHomeBannerImages[0]
	}
	return DefaultHomeBannerImages[sortOrder]
}

func EffectiveBannerImageURL(stored string, sortOrder int) string {
	if strings.TrimSpace(stored) != "" {
		return strings.TrimSpace(stored)
	}
	return DefaultHomeBannerImage(sortOrder)
}

func HeadlinerSortOrder(item map[string]any) int {
	if item == nil {
		return 0
	}
	switch v := item["sortOrder"].(type) {
	case int:
		return v
	case int32:
		return int(v)
	case int64:
		return int(v)
	case float64:
		return int(v)
	default:
		return 0
	}
}

func isSalangaWebsiteHost(host string) bool {
	host = strings.ToLower(strings.TrimSpace(host))
	return host == "salanga.ru" || host == "www.salanga.ru"
}

func isUploadBannerURL(parsed *url.URL) bool {
	if parsed == nil {
		return false
	}
	return strings.HasPrefix(parsed.Path, "/uploads/")
}

// AppBannerImageURL отдаёт URL картинки для приложения.
// Загрузки админки (/uploads/…) — напрямую с apiBase; картинки с сайта salanga.ru — через banner-media.
func AppBannerImageURL(apiBase, effectiveURL string) string {
	effectiveURL = strings.TrimSpace(effectiveURL)
	if effectiveURL == "" {
		return effectiveURL
	}
	parsed, err := url.Parse(effectiveURL)
	if err != nil {
		return effectiveURL
	}
	base := strings.TrimRight(strings.TrimSpace(apiBase), "/")
	if base == "" {
		return effectiveURL
	}
	if isUploadBannerURL(parsed) {
		return base + parsed.Path
	}
	if isSalangaWebsiteHost(parsed.Host) {
		return base + "/api/content/banner-media?url=" + url.QueryEscape(effectiveURL)
	}
	return effectiveURL
}

func EnrichHeadlinerImages(items []map[string]any, apiBase string) []map[string]any {
	out := make([]map[string]any, 0, len(items))
	for _, item := range items {
		if item == nil {
			continue
		}
		copy := make(map[string]any, len(item)+1)
		for k, v := range item {
			copy[k] = v
		}
		sortOrder := HeadlinerSortOrder(item)
		stored, _ := item["imageUrl"].(string)
		effective := EffectiveBannerImageURL(stored, sortOrder)
		copy["imageUrl"] = AppBannerImageURL(apiBase, effective)
		out = append(out, copy)
	}
	return out
}

func DefaultHeadlinersForApp(apiBase string) []map[string]any {
	return EnrichHeadlinerImages(DefaultHeadlinersFromSite(), apiBase)
}

func DefaultHeadlinersFromSite() []map[string]any {
	return []map[string]any{
		{
			"title":     "Горная Саланга",
			"subtitle":  "",
			"imageUrl":  DefaultHomeBannerImage(0),
			"linkUrl":   SalangaSite + "/book/",
			"sortOrder": 0,
		},
		{
			"title":     "Добро пожаловать в Горную Салангу",
			"subtitle":  "",
			"imageUrl":  DefaultHomeBannerImage(1),
			"linkUrl":   SalangaSite,
			"sortOrder": 1,
		},
		{
			"title":     "",
			"subtitle":  "",
			"imageUrl":  DefaultHomeBannerImage(2),
			"linkUrl":   SalangaSite + "/book/",
			"sortOrder": 2,
		},
	}
}
