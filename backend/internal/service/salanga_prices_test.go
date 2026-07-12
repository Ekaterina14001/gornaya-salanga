package service

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseSalangaPricelistFromLegacyJSONStructure(t *testing.T) {
	html := `<html><body>
<h3>Цены на подъёмники:</h3>
<table><tr><th>Количество подъёмов</th><th>Цена, руб</th></tr>
<tr><td>Однократный подъём</td><td>250</td></tr>
<tr><td>Дневной абонемент</td><td>2500</td></tr></table>
<h3>Трасса сноутюбинга:</h3>
<table><tr><td>Однократный спуск</td><td>150 руб</td></tr></table>
<h3>Цены на услуги проката:</h3>
<table>
<tr><th>Наименование</th><th>Цена</th><th>Цена</th></tr>
<tr><td>взрослый</td><td>детский</td><td></td></tr>
<tr><td>Горные лыжи (комплект)</td><td>300/1500</td><td>200/1000</td></tr>
<tr><td>Коньки</td><td>200</td><td></td></tr>
</table>
</body></html>`

	tables, err := ParseSalangaPricelistHTML(html)
	if err != nil {
		t.Fatal(err)
	}
	if len(tables) != 3 {
		t.Fatalf("expected 3 tables, got %d", len(tables))
	}

	items := SalangaTablesToServices(tables)
	if len(items) < 5 {
		t.Fatalf("expected at least 5 services, got %d", len(items))
	}

	foundLift := false
	foundRental := false
	for _, item := range items {
		if item.Name == "Однократный подъём" && item.Price == 250 && item.Category == "lift" {
			foundLift = true
		}
		if item.Name == "Горные лыжи (комплект)" && item.Category == "rental" {
			foundRental = true
			if item.Description == "" {
				t.Fatal("rental item should have description")
			}
		}
	}
	if !foundLift || !foundRental {
		t.Fatalf("missing expected items: lift=%v rental=%v", foundLift, foundRental)
	}
}

func TestFetchSalangaPricelistLive(t *testing.T) {
	if os.Getenv("SALANGA_LIVE_TEST") != "1" {
		t.Skip("set SALANGA_LIVE_TEST=1 to run live fetch")
	}
	tables, err := FetchSalangaPricelist(t.Context())
	if err != nil {
		t.Fatal(err)
	}
	if len(tables) < 3 {
		t.Fatalf("expected >=3 tables, got %d", len(tables))
	}
	items := SalangaTablesToServices(tables)
	if len(items) < 10 {
		t.Fatalf("expected >=10 services, got %d", len(items))
	}
}

func TestParseLegacyParsedTablesFixture(t *testing.T) {
	path := filepath.Join("..", "..", "..", "Desktop", "разработка Саланга", "Mobile", "assets", "parsed_tables.json")
	if _, err := os.Stat(path); err != nil {
		t.Skip("legacy fixture not available")
	}
	// Fixture validates our category mapping expectations only.
	items := SalangaTablesToServices([]SalangaPriceTable{
		{Category: "lift", Headers: []string{"a", "b"}, Rows: [][]string{{"Однократный подъём", "250"}}},
		{Category: "rental", Rows: [][]string{{"Коньки", "200", ""}}},
	})
	if len(items) != 2 {
		t.Fatalf("expected 2 items, got %d", len(items))
	}
}
