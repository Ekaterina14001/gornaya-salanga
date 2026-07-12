package service

import (
	"context"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/rs/zerolog/log"
	"golang.org/x/net/html"
)

var (
	reTempDay   = regexp.MustCompile(`(?i)днем:\s*([+\-]?\d+)`)
	reTempNight = regexp.MustCompile(`(?i)ночью:\s*([+\-]?\d+)`)
	reWind      = regexp.MustCompile(`(?i)Ветер:\s*(\S+),\s*(\d+)`)
	reForecastDate = regexp.MustCompile(`(?i)на\s+(\d{1,2}\s+\S+)`)
	reTempNightLi = regexp.MustCompile(`(?i)Температура ночью:\s*([+\-]?\d+)`)
	reTempDayLi   = regexp.MustCompile(`(?i)Температура днем:\s*([+\-]?\d+)`)
	rePrecipLi    = regexp.MustCompile(`(?i)Осадки:\s*(\S+)`)
)

type SalangaForecastDay struct {
	Label         string
	TempDay       int
	TempNight     int
	Description   string
	Precipitation bool
	WindDirection string
	WindSpeed     float64
}

// fetchSalangaWeather parses https://www.salanga.ru/weather (same logic as legacy Mobile app).
func fetchSalangaWeather(ctx context.Context) (map[string]any, bool) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://www.salanga.ru/weather", nil)
	if err != nil {
		return nil, false
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")

	client := &http.Client{Timeout: 15 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		log.Warn().Err(err).Msg("salanga.ru weather fetch failed")
		return nil, false
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Warn().Int("status", resp.StatusCode).Msg("salanga.ru weather bad status")
		return nil, false
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, false
	}

	return buildSalangaWeatherPayload(string(body))
}

func buildSalangaWeatherPayload(pageHTML string) (map[string]any, bool) {
	days := parseSalangaForecastHTML(pageHTML)
	if len(days) == 0 {
		rawText := extractFirstForecastCell(pageHTML)
		if rawText == "" {
			return nil, false
		}
		day := parseForecastText("", rawText)
		if day.TempDay == 0 && day.TempNight == 0 {
			return nil, false
		}
		days = []SalangaForecastDay{day}
	}

	first := days[0]
	forecast := make([]map[string]any, len(days))
	for i, day := range days {
		forecast[i] = forecastDayToMap(day)
	}

	return map[string]any{
		"temperature":        first.TempDay,
		"tempDay":            first.TempDay,
		"tempNight":          first.TempNight,
		"feelsLike":          first.TempDay,
		"description":        first.Description,
		"humidity":           65,
		"windSpeed":          first.WindSpeed,
		"windDirection":      first.WindDirection,
		"precipitation":      first.Precipitation,
		"source":             "salanga.ru",
		"forecast":           forecast,
		"rawForecast":        first.Label,
		"fetchedAt":          time.Now().Format(time.RFC3339),
	}, true
}

func forecastDayToMap(day SalangaForecastDay) map[string]any {
	return map[string]any{
		"label":         day.Label,
		"tempDay":       day.TempDay,
		"tempNight":     day.TempNight,
		"description":   day.Description,
		"precipitation": day.Precipitation,
		"windDirection": day.WindDirection,
		"windSpeed":     day.WindSpeed,
	}
}

func parseSalangaForecastHTML(pageHTML string) []SalangaForecastDay {
	doc, err := html.Parse(strings.NewReader(pageHTML))
	if err != nil {
		return nil
	}

	var days []SalangaForecastDay
	var walk func(*html.Node)
	walk = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "tr" {
			if day, ok := parseForecastRow(n); ok {
				days = append(days, day)
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
	}
	walk(doc)

	if len(days) > 7 {
		days = days[:7]
	}
	return days
}

func parseForecastRow(tr *html.Node) (SalangaForecastDay, bool) {
	var cells []*html.Node
	for c := tr.FirstChild; c != nil; c = c.NextSibling {
		if c.Type == html.ElementNode && c.Data == "td" {
			cells = append(cells, c)
		}
	}
	if len(cells) < 2 {
		return SalangaForecastDay{}, false
	}

	labelText := strings.Join(strings.Fields(collectWeatherText(cells[0])), " ")
	forecastText := strings.Join(strings.Fields(collectWeatherText(cells[1])), " ")
	if !strings.Contains(strings.ToLower(labelText), "прогноз") &&
		!strings.Contains(strings.ToLower(forecastText), "температура") {
		return SalangaForecastDay{}, false
	}

	return parseForecastText(labelText, forecastText), true
}

func parseForecastText(labelText, forecastText string) SalangaForecastDay {
	day := SalangaForecastDay{Description: "Ясно"}

	if m := reForecastDate.FindStringSubmatch(labelText); len(m) == 2 {
		day.Label = strings.TrimSpace(m[1])
	} else {
		day.Label = strings.TrimSpace(labelText)
	}

	tempDay, tempNight := 0, 0
	if m := reTempDayLi.FindStringSubmatch(forecastText); len(m) == 2 {
		tempDay, _ = strconv.Atoi(m[1])
	} else if m := reTempDay.FindStringSubmatch(forecastText); len(m) == 2 {
		tempDay, _ = strconv.Atoi(m[1])
	}
	if m := reTempNightLi.FindStringSubmatch(forecastText); len(m) == 2 {
		tempNight, _ = strconv.Atoi(m[1])
	} else if m := reTempNight.FindStringSubmatch(forecastText); len(m) == 2 {
		tempNight, _ = strconv.Atoi(m[1])
	}
	if tempNight == 0 {
		tempNight = tempDay
	}
	day.TempDay = tempDay
	day.TempNight = tempNight

	if m := rePrecipLi.FindStringSubmatch(forecastText); len(m) == 2 {
		precip := strings.ToLower(m[1])
		day.Precipitation = precip != "нет"
		switch {
		case strings.Contains(precip, "снег"):
			day.Description = "Снег"
		case strings.Contains(precip, "дожд"):
			day.Description = "Дождь"
		default:
			day.Description = "Ясно"
		}
	} else if strings.Contains(forecastText, "Снег") {
		day.Description = "Снег"
		day.Precipitation = true
	} else if strings.Contains(forecastText, "Дождь") {
		day.Description = "Дождь"
		day.Precipitation = true
	} else if strings.Contains(forecastText, "Облач") {
		day.Description = "Облачно"
	}

	day.WindSpeed = 5
	if m := reWind.FindStringSubmatch(forecastText); len(m) >= 3 {
		day.WindDirection = m[1]
		if v, err := strconv.Atoi(m[2]); err == nil {
			day.WindSpeed = float64(v) * 2.5
		}
	}

	return day
}

func collectWeatherText(n *html.Node) string {
	if n == nil {
		return ""
	}
	var b strings.Builder
	var walk func(*html.Node)
	walk = func(node *html.Node) {
		if node.Type == html.TextNode {
			b.WriteString(node.Data)
		}
		for c := node.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
	}
	walk(n)
	return b.String()
}

// extractFirstForecastCell pulls text from the second <td> of the first <tr> in HTML table.
func extractFirstForecastCell(html string) string {
	trIdx := strings.Index(strings.ToLower(html), "<tr")
	if trIdx < 0 {
		return ""
	}
	fragment := html[trIdx:]
	tdParts := strings.Split(strings.ToLower(fragment), "<td")
	if len(tdParts) < 3 {
		return ""
	}
	cell := tdParts[2]
	end := strings.Index(cell, "</td>")
	if end < 0 {
		return ""
	}
	cell = cell[:end]
	cell = stripHTMLTags(cell)
	return strings.TrimSpace(cell)
}

func stripHTMLTags(s string) string {
	var b strings.Builder
	inTag := false
	for _, r := range s {
		switch {
		case r == '<':
			inTag = true
		case r == '>':
			inTag = false
		case !inTag:
			b.WriteRune(r)
		}
	}
	return strings.Join(strings.Fields(b.String()), " ")
}
