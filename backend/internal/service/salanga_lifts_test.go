package service

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestParseSalangaLiftsFromFixture(t *testing.T) {
	path := filepath.Join("..", "..", "testdata", "poemniki.html")
	html, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}

	items, err := ParseSalangaLiftsHTML(string(html))
	if err != nil {
		t.Fatal(err)
	}
	if len(items) < 4 {
		t.Fatalf("expected at least 4 lifts, got %d", len(items))
	}

	if items[0].OpenTime != "10:00" || items[0].CloseTime != "17:00" {
		t.Fatalf("unexpected hours: %s–%s", items[0].OpenTime, items[0].CloseTime)
	}

	foundKBD1 := false
	foundBaby := 0
	for _, item := range items {
		switch item.ExternalKey {
		case "salanga:lift:kbd-1":
			foundKBD1 = true
			if item.PricesText == "" {
				t.Fatal("KBD-1 should include prices")
			}
			if !strings.Contains(item.PricesText, "Подъёмы") {
				t.Fatalf("KBD-1 prices missing lift table: %q", item.PricesText)
			}
		case "salanga:lift:baby-slope", "salanga:lift:baby-lake":
			foundBaby++
			if item.PricesText != "бесплатно" {
				t.Fatalf("baby lift should be free, got %q", item.PricesText)
			}
		}
	}
	if !foundKBD1 {
		t.Fatal("missing KBD-1")
	}
	if foundBaby != 2 {
		t.Fatalf("expected 2 baby lifts, got %d", foundBaby)
	}
}

func TestFetchSalangaLiftsLive(t *testing.T) {
	if os.Getenv("SALANGA_LIVE_TEST") != "1" {
		t.Skip("set SALANGA_LIVE_TEST=1 to run live fetch")
	}
	items, err := FetchSalangaLifts(t.Context())
	if err != nil {
		t.Fatal(err)
	}
	if len(items) < 3 {
		t.Fatalf("expected >=3 lifts, got %d", len(items))
	}
}
