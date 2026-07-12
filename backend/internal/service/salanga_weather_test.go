package service

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseSalangaForecastFromFixture(t *testing.T) {
	path := filepath.Join("..", "..", "testdata", "weather.html")
	html, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}

	data, ok := buildSalangaWeatherPayload(string(html))
	if !ok {
		t.Fatal("expected forecast payload")
	}

	forecast, _ := data["forecast"].([]map[string]any)
	if len(forecast) < 4 {
		t.Fatalf("expected at least 4 forecast days, got %d", len(forecast))
	}

	if data["tempDay"] == nil || data["tempNight"] == nil {
		t.Fatal("expected top-level day/night temps")
	}

	first := forecast[0]
	if first["label"] == nil || first["label"] == "" {
		t.Fatal("expected forecast label")
	}
	if first["tempDay"] == nil {
		t.Fatal("expected tempDay in forecast item")
	}
}
