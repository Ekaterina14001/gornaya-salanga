package service

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"time"
	"unicode"

	"github.com/gornaya-salanga/backend/internal/repository"
	"github.com/rs/zerolog/log"
	"golang.org/x/net/html"
)

const salangaPricelistURL = "https://www.salanga.ru/pricelist-ski/"

var reDigits = regexp.MustCompile(`(\d+(?:[.,]\d+)?)`)

// SalangaPriceTable is one parsed HTML table from the pricelist page.
type SalangaPriceTable struct {
	Heading  string     `json:"heading"`
	Category string     `json:"category"`
	Headers  []string   `json:"headers"`
	Rows     [][]string `json:"rows"`
}

// SalangaServiceItem is a normalized service row for DB import.
type SalangaServiceItem struct {
	Name        string
	Description string
	Price       float64
	Category    string
	ExternalKey string
	SortOrder   int
}

// FetchSalangaPricelist downloads and parses all price tables from salanga.ru.
func FetchSalangaPricelist(ctx context.Context) ([]SalangaPriceTable, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, salangaPricelistURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
	req.Header.Set("Accept-Language", "ru-RU,ru;q=0.9")

	client := &http.Client{Timeout: 20 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("fetch pricelist: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("fetch pricelist: status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	tables, err := ParseSalangaPricelistHTML(string(body))
	if err != nil {
		return nil, err
	}
	if len(tables) == 0 {
		return nil, fmt.Errorf("no price tables found on page")
	}
	return tables, nil
}

// ParseSalangaPricelistHTML parses price tables from raw HTML (for tests).
func ParseSalangaPricelistHTML(pageHTML string) ([]SalangaPriceTable, error) {
	doc, err := html.Parse(strings.NewReader(pageHTML))
	if err != nil {
		return nil, fmt.Errorf("parse html: %w", err)
	}

	var tables []SalangaPriceTable
	var walk func(*html.Node)
	walk = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "table" {
			parsed := parseHTMLTable(n)
			if parsed == nil {
				return
			}
			heading := findNearestHeading(n)
			parsed.Heading = heading
			parsed.Category = categoryFromHeading(heading)
			tables = append(tables, *parsed)
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walk(c)
		}
	}
	walk(doc)
	return tables, nil
}

// SalangaTablesToServices converts parsed tables into importable service items.
func SalangaTablesToServices(tables []SalangaPriceTable) []SalangaServiceItem {
	var items []SalangaServiceItem
	order := 0

	for _, table := range tables {
		switch table.Category {
		case "lift", "tubing", "snowmobile", "other":
			items = append(items, servicesFromTwoColumnTable(table, &order)...)
		case "rental":
			items = append(items, servicesFromRentalTable(table, &order)...)
		default:
			items = append(items, servicesFromTwoColumnTable(table, &order)...)
		}
	}
	return items
}

func servicesFromTwoColumnTable(table SalangaPriceTable, order *int) []SalangaServiceItem {
	var items []SalangaServiceItem

	appendRow := func(name, priceText string) {
		name = strings.TrimSpace(name)
		priceText = strings.TrimSpace(priceText)
		if name == "" || isHeaderLike(name) {
			return
		}
		*order++
		price, label := parsePriceLabel(priceText)
		items = append(items, SalangaServiceItem{
			Name:        name,
			Description: label,
			Price:       price,
			Category:    table.Category,
			ExternalKey: externalKey(table.Category, name, ""),
			SortOrder:   *order,
		})
	}

	// Some tables store the only row in headers (e.g. tubing).
	if len(table.Rows) == 0 && len(table.Headers) >= 2 {
		appendRow(table.Headers[0], table.Headers[1])
		return items
	}

	if len(table.Headers) >= 2 && !isHeaderLike(table.Headers[0]) {
		appendRow(table.Headers[0], table.Headers[1])
	}

	for _, row := range table.Rows {
		if len(row) == 0 {
			continue
		}
		priceCol := ""
		if len(row) > 1 {
			priceCol = row[1]
		}
		appendRow(row[0], priceCol)
	}

	return items
}

func servicesFromRentalTable(table SalangaPriceTable, order *int) []SalangaServiceItem {
	var items []SalangaServiceItem

	for _, row := range table.Rows {
		if len(row) == 0 {
			continue
		}
		name := strings.TrimSpace(row[0])
		if name == "" || isRentalMetaRow(name) {
			continue
		}

		adult := ""
		child := ""
		if len(row) > 1 {
			adult = strings.TrimSpace(row[1])
		}
		if len(row) > 2 {
			child = strings.TrimSpace(row[2])
		}

		descParts := []string{}
		primaryPrice := 0.0
		if adult != "" {
			p, label := parsePriceLabel(adult)
			if primaryPrice == 0 {
				primaryPrice = p
			}
			descParts = append(descParts, fmt.Sprintf("Взрослый: %s", label))
		}
		if child != "" {
			_, label := parsePriceLabel(child)
			descParts = append(descParts, fmt.Sprintf("Детский: %s", label))
		}
		if len(descParts) == 0 {
			continue
		}

		*order++
		items = append(items, SalangaServiceItem{
			Name:        name,
			Description: strings.Join(descParts, "; "),
			Price:       primaryPrice,
			Category:    "rental",
			ExternalKey: externalKey("rental", name, ""),
			SortOrder:   *order,
		})
	}

	return items
}

func parseHTMLTable(tableNode *html.Node) *SalangaPriceTable {
	var rows [][]string
	var walkRows func(*html.Node)
	walkRows = func(n *html.Node) {
		if n.Type == html.ElementNode && n.Data == "tr" {
			cells := extractRowCells(n)
			if len(cells) > 0 {
				rows = append(rows, cells)
			}
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			walkRows(c)
		}
	}
	walkRows(tableNode)

	if len(rows) == 0 {
		return nil
	}

	maxCols := 0
	for _, row := range rows {
		if len(row) > maxCols {
			maxCols = len(row)
		}
	}
	for i := range rows {
		for len(rows[i]) < maxCols {
			rows[i] = append(rows[i], "")
		}
	}

	headers := rows[0]
	dataRows := rows[1:]
	if len(dataRows) == 0 {
		dataRows = nil
	}

	return &SalangaPriceTable{
		Headers: headers,
		Rows:    dataRows,
	}
}

func extractRowCells(tr *html.Node) []string {
	var cells []string
	for c := tr.FirstChild; c != nil; c = c.NextSibling {
		if c.Type != html.ElementNode {
			continue
		}
		if c.Data != "td" && c.Data != "th" {
			continue
		}
		text := strings.TrimSpace(collectText(c))
		colspan := 1
		for _, attr := range c.Attr {
			if attr.Key == "colspan" {
				if n, err := strconv.Atoi(attr.Val); err == nil && n > 1 {
					colspan = n
				}
			}
		}
		cells = append(cells, text)
		for i := 1; i < colspan; i++ {
			cells = append(cells, text)
		}
	}
	return cells
}

func collectText(n *html.Node) string {
	if n.Type == html.TextNode {
		return n.Data
	}
	var b strings.Builder
	for c := n.FirstChild; c != nil; c = c.NextSibling {
		b.WriteString(collectText(c))
	}
	return b.String()
}

func findNearestHeading(tableNode *html.Node) string {
	for n := tableNode.PrevSibling; n != nil; n = n.PrevSibling {
		if h := headingText(n); h != "" {
			return h
		}
	}
	// Walk up and check previous siblings of ancestors.
	for parent := tableNode.Parent; parent != nil; parent = parent.Parent {
		for n := parent.PrevSibling; n != nil; n = n.PrevSibling {
			if h := headingText(n); h != "" {
				return h
			}
		}
	}
	return ""
}

func headingText(n *html.Node) string {
	if n.Type != html.ElementNode {
		return ""
	}
	switch n.Data {
	case "h2", "h3", "h4", "strong", "b":
		return strings.TrimSpace(collectText(n))
	default:
		return ""
	}
}

func categoryFromHeading(heading string) string {
	h := strings.ToLower(heading)
	switch {
	case strings.Contains(h, "подъёмник"), strings.Contains(h, "подъемник"):
		return "lift"
	case strings.Contains(h, "сноутюб"):
		return "tubing"
	case strings.Contains(h, "снегоход"):
		return "snowmobile"
	case strings.Contains(h, "прокат"):
		return "rental"
	default:
		return "other"
	}
}

func parsePriceLabel(raw string) (float64, string) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return 0, ""
	}
	lower := strings.ToLower(raw)
	if strings.Contains(lower, "бесплат") {
		return 0, "бесплатно"
	}

	label := raw
	if !strings.Contains(lower, "руб") {
		label = raw + " ₽"
	} else {
		label = strings.ReplaceAll(raw, "руб", "₽")
	}

	if strings.Contains(raw, "/") {
		parts := strings.Split(raw, "/")
		if p, ok := parseFirstNumber(parts[0]); ok {
			return p, label
		}
	}

	if p, ok := parseFirstNumber(raw); ok {
		return p, label
	}
	return 0, label
}

func parseFirstNumber(s string) (float64, bool) {
	s = strings.ReplaceAll(s, ",", ".")
	m := reDigits.FindStringSubmatch(s)
	if len(m) < 2 {
		return 0, false
	}
	v, err := strconv.ParseFloat(m[1], 64)
	if err != nil {
		return 0, false
	}
	return v, true
}

func isHeaderLike(s string) bool {
	lower := strings.ToLower(s)
	return strings.Contains(lower, "количество") ||
		strings.Contains(lower, "наименование") ||
		strings.Contains(lower, "цена")
}

func isRentalMetaRow(name string) bool {
	lower := strings.ToLower(name)
	return strings.Contains(lower, "взросл") ||
		strings.Contains(lower, "детск") ||
		isHeaderLike(name)
}

func externalKey(category, name, suffix string) string {
	slug := slugify(name)
	if suffix != "" {
		slug += "-" + slugify(suffix)
	}
	return fmt.Sprintf("salanga:%s:%s", category, slug)
}

func slugify(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	var b strings.Builder
	lastDash := false
	for _, r := range s {
		switch {
		case unicode.IsLetter(r) || unicode.IsDigit(r):
			b.WriteRune(r)
			lastDash = false
		default:
			if !lastDash && b.Len() > 0 {
				b.WriteByte('-')
				lastDash = true
			}
		}
	}
	out := strings.Trim(b.String(), "-")
	if out == "" {
		return "item"
	}
	return out
}

// SyncSalangaServices fetches the live pricelist and upserts services in DB.
func (s *ContentService) SyncSalangaServices(ctx context.Context) (map[string]any, error) {
	tables, err := FetchSalangaPricelist(ctx)
	if err != nil {
		log.Warn().Err(err).Msg("salanga pricelist fetch failed")
		return nil, err
	}

	items := SalangaTablesToServices(tables)
	repoItems := make([]repository.SalangaServiceInput, len(items))
	for i, item := range items {
		repoItems[i] = repository.SalangaServiceInput{
			Name:        item.Name,
			Description: item.Description,
			Price:       item.Price,
			Category:    item.Category,
			ExternalKey: item.ExternalKey,
			SortOrder:   item.SortOrder,
		}
	}
	count, err := s.content.SyncSalangaServices(ctx, repoItems)
	if err != nil {
		return nil, err
	}

	return map[string]any{
		"imported":   count,
		"tables":     len(tables),
		"source":     "salanga.ru",
		"sourceUrl":  salangaPricelistURL,
		"fetchedAt":  time.Now().Format(time.RFC3339),
		"categories": summarizeCategories(items),
	}, nil
}

func summarizeCategories(items []SalangaServiceItem) map[string]int {
	out := map[string]int{}
	for _, item := range items {
		out[item.Category]++
	}
	return out
}
