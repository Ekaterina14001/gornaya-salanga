package service

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gornaya-salanga/backend/internal/config"
	"github.com/gornaya-salanga/backend/internal/repository"
	"github.com/redis/go-redis/v9"
)

type ContentService struct {
	content *repository.ContentRepository
	redis   *redis.Client
	cfg     *config.Config
}

func NewContentService(content *repository.ContentRepository, redis *redis.Client, cfg *config.Config) *ContentService {
	return &ContentService{content: content, redis: redis, cfg: cfg}
}

func (s *ContentService) GetAbout(ctx context.Context) (map[string]any, error) {
	return s.content.GetAbout(ctx)
}

func (s *ContentService) GetServices(ctx context.Context) ([]map[string]any, error) {
	return s.content.GetServices(ctx)
}

func (s *ContentService) GetSchedule(ctx context.Context) ([]map[string]any, error) {
	return s.content.GetSchedule(ctx)
}

func (s *ContentService) GetRules(ctx context.Context) ([]map[string]any, error) {
	return s.content.GetRules(ctx)
}

func (s *ContentService) GetWebcams(ctx context.Context) ([]map[string]any, error) {
	return s.content.GetWebcams(ctx)
}

func (s *ContentService) GetTrails(ctx context.Context) ([]map[string]any, error) {
	return s.content.GetTrails(ctx)
}

func (s *ContentService) GetLifts(ctx context.Context) ([]map[string]any, error) {
	return s.content.GetLifts(ctx)
}

func (s *ContentService) GetHeadliners(ctx context.Context) ([]map[string]any, error) {
	return s.content.GetHeadliners(ctx)
}

func (s *ContentService) GetWeather(ctx context.Context) (map[string]any, error) {
	cacheKey := "weather:current"
	if s.redis != nil {
		cached, err := s.redis.Get(ctx, cacheKey).Result()
		if err == nil {
			var data map[string]any
			if json.Unmarshal([]byte(cached), &data) == nil {
				return data, nil
			}
		}
	}

	if cached, err := s.content.GetWeatherCache(ctx, 15*time.Minute); err == nil {
		return cached, nil
	}

	data := s.fetchWeather(ctx)
	if s.redis != nil {
		b, _ := json.Marshal(data)
		_ = s.redis.Set(ctx, cacheKey, b, 15*time.Minute).Err()
	}
	_ = s.content.SaveWeatherCache(ctx, data)
	return data, nil
}

func (s *ContentService) fetchWeather(ctx context.Context) map[string]any {
	if data, ok := fetchSalangaWeather(ctx); ok {
		return data
	}

	if s.cfg.OpenWeatherAPIKey != "" {
		url := fmt.Sprintf("https://api.openweathermap.org/data/2.5/weather?q=Sochi,ru&appid=%s&units=metric&lang=ru", s.cfg.OpenWeatherAPIKey)
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err == nil {
			resp, err := http.DefaultClient.Do(req)
			if err == nil {
				defer resp.Body.Close()
				body, _ := io.ReadAll(resp.Body)
				var raw map[string]any
				if json.Unmarshal(body, &raw) == nil {
					return map[string]any{
						"temperature": raw["main"].(map[string]any)["temp"],
						"description": raw["weather"].([]any)[0].(map[string]any)["description"],
						"humidity":    raw["main"].(map[string]any)["humidity"],
						"windSpeed":   raw["wind"].(map[string]any)["speed"],
						"source":      "openweathermap",
					}
				}
			}
		}
	}
	return map[string]any{
		"temperature": -5,
		"description": "Облачно",
		"humidity":    72,
		"windSpeed":   3.5,
		"source":      "stub",
	}
}
