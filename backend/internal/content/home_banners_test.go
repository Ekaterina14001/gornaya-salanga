package content

import (
	"strings"
	"testing"
)

func TestAppBannerImageURL_uploadNotProxied(t *testing.T) {
	base := "https://admin.salanga.ru"
	stored := "https://api.salanga.ru/uploads/f22d184e-f1d5-4fd0-94eb-aeaf45f09296.jpg"
	got := AppBannerImageURL(base, stored)
	want := "https://admin.salanga.ru/uploads/f22d184e-f1d5-4fd0-94eb-aeaf45f09296.jpg"
	if got != want {
		t.Fatalf("got %q want %q", got, want)
	}
}

func TestAppBannerImageURL_salangaSiteProxied(t *testing.T) {
	base := "https://admin.salanga.ru"
	stored := "https://www.salanga.ru/up/17/test.jpg"
	got := AppBannerImageURL(base, stored)
	if got == stored || !strings.Contains(got, "banner-media") {
		t.Fatalf("expected proxy url, got %q", got)
	}
}
