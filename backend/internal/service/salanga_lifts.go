package service

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"

	"github.com/gornaya-salanga/backend/internal/repository"
	"github.com/rs/zerolog/log"
	"golang.org/x/net/html"
)

const salangaLiftsURL = "https://www.salanga.ru/services/Poemniki/"

var (
	reLiftHours = regexp.MustCompile(`Время работы подъёмника:\s*с\s*(\d{1,2}:\d{2})\s*до\s*(\d{1,2}:\d{2})`)
	reKBD1      = regexp.MustCompile(`Подъёмник-1 \(КБД-1\)\s+(.+?)(?:Подъёмник|Второй|$)`)
	reKBD2      = regexp.MustCompile(`Второй подъёмник \(КБД-2\)\s+(.+?)(?:Гарантированно|Есть|$)`)
	reBaby      = regexp.MustCompile(`Есть 2 дополнительных безопорных подъёмника \(бэби-лифт\),\s*(.+?)\.\s*Пользование`)
	reValidUntil = regexp.MustCompile(`Цены действительны до\s+([0-9.]+)`)
)

type SalangaLiftItem struct {
	Name        string
	Description string
	PricesText  string
	OpenTime    string
	CloseTime   string
	Comment     string
	ExternalKey string
	SortOrder   int
}

func FetchSalangaLifts(ctx context.Context) ([]SalangaLiftItem, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, salangaLiftsURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
	req.Header.Set("Accept-Language", "ru-RU,ru;q=0.9")

	client := &http.Client{Timeout: 20 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch lifts page: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("fetch lifts page: status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	items, err := ParseSalangaLiftsHTML(string(body))
	if err != nil {
		return nil, err
	}
	if len(items) == 0 {
		return nil, fmt.Errorf("no lifts parsed from page")
	}
	return items, nil
}

func ParseSalangaLiftsHTML(pageHTML string) ([]SalangaLiftItem, error) {
	plain := htmlPlainText(pageHTML)
	openTime, closeTime := "10:00", "17:00"
	if m := reLiftHours.FindStringSubmatch(plain); len(m) == 3 {
		openTime, closeTime = m[1], m[2]
	}

	rules := extractBlockquoteAfter(plain, "Основные")
	validity := ""
	if m := reValidUntil.FindStringSubmatch(plain); len(m) == 2 {
		validity = "Цены действительны до " + m[1]
	}

	liftPrices, tubingPrices := parseLiftPageTables(pageHTML)
	pricesText := formatPriceTable("Подъёмы", liftPrices)
	if tubingPrices != "" {
		pricesText += "\n\nТрасса сноутюбинга:\n" + tubingPrices
	}
	if validity != "" {
		pricesText += "\n\n" + validity
	}

	var items []SalangaLiftItem
	order := 0
	add := func(name, desc, prices, comment, key string) {
		order++
		items = append(items, SalangaLiftItem{
			Name:        name,
			Description: strings.TrimSpace(desc),
			PricesText:  strings.TrimSpace(prices),
			OpenTime:    openTime,
			CloseTime:   closeTime,
			Comment:     strings.TrimSpace(comment),
			ExternalKey: key,
			SortOrder:   order,
		})
	}

	if m := reKBD1.FindStringSubmatch(plain); len(m) == 2 {
		add("КБД-1", m[1], pricesText, rules, "salanga:lift:kbd-1")
	} else {
		add("КБД-1", "Основной бугельный подъёмник вдоль склона №2", pricesText, rules, "salanga:lift:kbd-1")
	}

	if m := reKBD2.FindStringSubmatch(plain); len(m) == 2 {
		add("КБД-2", m[1], "", rules, "salanga:lift:kbd-2")
	} else {
		add("КБД-2", "Подъёмник на трассы №3 и №4", "", rules, "salanga:lift:kbd-2")
	}

	if m := reBaby.FindStringSubmatch(plain); len(m) == 2 {
		parts := strings.Split(m[1], ",")
		if len(parts) >= 1 {
			add("Бэби-лифт (учебный склон)", strings.TrimSpace(parts[0]), "бесплатно", "", "salanga:lift:baby-slope")
		}
		if len(parts) >= 2 {
			add("Бэби-лифт (от озера)", strings.TrimSpace(parts[1]), "бесплатно", "", "salanga:lift:baby-lake")
		}
	} else {
		add("Бэби-лифт (учебный склон)", "Обслуживает учебный склон", "бесплатно", "", "salanga:lift:baby-slope")
		add("Бэби-лифт (от озера)", "Подъём от озера", "бесплатно", "", "salanga:lift:baby-lake")
	}

	return items, nil
}

func parseLiftPageTables(pageHTML string) (liftPrices, tubingPrices string) {
	doc, err := html.Parse(strings.NewReader(pageHTML))
	if err != nil {
		return "", ""
	}

	var tables []SalangaPriceTable
	var walk func(*html.Node)
	walk = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "table" {
			parsed := parseHTMLTable(n)
			if parsed != nil {
				parsed.Heading = findNearestHeading(n)
				tables = append(tables, *parsed)
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
	}
	walk(doc)

	for _, table := range tables {
		h := strings.ToLower(table.Heading)
		body := formatTableRows(table)
		switch {
		case strings.Contains(h, "сноутюб"):
			tubingPrices = body
		case strings.Contains(h, "прайс") || strings.Contains(h, "подъёмник") || strings.Contains(h, "подъемник"):
			liftPrices = body
		case liftPrices == "" && len(table.Rows) > 0:
			// First price-like table on lifts page.
			if strings.Contains(strings.ToLower(table.Headers[0]), "подъём") ||
				strings.Contains(strings.ToLower(table.Headers[0]), "подъем") {
				liftPrices = body
			}
		}
	}

	if liftPrices == "" && len(tables) > 0 {
		liftPrices = formatTableRows(tables[0])
	}
	if tubingPrices == "" && len(tables) > 1 {
		tubingPrices = formatTableRows(tables[1])
	}
	return liftPrices, tubingPrices
}

func formatTableRows(table SalangaPriceTable) string {
	var lines []string
	appendRow := func(a, b string) {
		a, b = strings.TrimSpace(a), strings.TrimSpace(b)
		if a == "" || isHeaderLike(a) {
			return
		}
		lines = append(lines, fmt.Sprintf("%s — %s", a, b))
	}
	if len(table.Headers) >= 2 {
		appendRow(table.Headers[0], table.Headers[1])
	}
	for _, row := range table.Rows {
		if len(row) >= 2 {
			appendRow(row[0], row[1])
		}
	}
	return strings.Join(lines, "\n")
}

func formatPriceTable(title, body string) string {
	if body == "" {
		return ""
	}
	return title + ":\n" + body
}

func htmlPlainText(pageHTML string) string {
	doc, err := html.Parse(strings.NewReader(pageHTML))
	if err != nil {
		return pageHTML
	}
	return strings.Join(strings.Fields(collectText(doc)), " ")
}

func extractBlockquoteAfter(plain, marker string) string {
	idx := strings.Index(plain, marker)
	if idx < 0 {
		return ""
	}
	snippet := plain[idx:]
	if end := strings.Index(snippet, "Прайс-лист"); end > 0 {
		snippet = snippet[:end]
	}
	return strings.TrimSpace(snippet)
}

func (s *ContentService) SyncSalangaLifts(ctx context.Context) (map[string]any, error) {
	items, err := FetchSalangaLifts(ctx)
	if err != nil {
		log.Warn().Err(err).Msg("salanga lifts fetch failed")
		return nil, err
	}

	repoItems := make([]repository.SalangaLiftInput, len(items))
	for i, item := range items {
		repoItems[i] = repository.SalangaLiftInput{
			Name:        item.Name,
			Description: item.Description,
			PricesText:  item.PricesText,
			OpenTime:    item.OpenTime,
			CloseTime:   item.CloseTime,
			Comment:     item.Comment,
			ExternalKey: item.ExternalKey,
			SortOrder:   item.SortOrder,
		}
	}

	count, err := s.content.SyncSalangaLifts(ctx, repoItems)
	if err != nil {
		return nil, err
	}

	return map[string]any{
		"imported":  count,
		"source":    "salanga.ru",
		"sourceUrl": salangaLiftsURL,
		"fetchedAt": time.Now().Format(time.RFC3339),
	}, nil
}
