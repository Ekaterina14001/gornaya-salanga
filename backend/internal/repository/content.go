package repository

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/jackc/pgx/v5/pgxpool"
)

type ContentRepository struct {
	pool *pgxpool.Pool
}

func NewContentRepository(pool *pgxpool.Pool) *ContentRepository {
	return &ContentRepository{pool: pool}
}

func (r *ContentRepository) GetAbout(ctx context.Context) (map[string]any, error) {
	if r.pool == nil {
		return map[string]any{
			"title": "Горная Саланга",
			"bodyMarkdown": "Добро пожаловать на горнолыжный курорт «Горная Саланга».",
			"photos": []string{},
		}, nil
	}
	var title, body string
	var photos []byte
	var updatedAt time.Time
	err := r.pool.QueryRow(ctx, `SELECT title, body_markdown, photos, updated_at FROM content_about LIMIT 1`).Scan(&title, &body, &photos, &updatedAt)
	if err != nil {
		return nil, err
	}
	var photoList []any
	_ = json.Unmarshal(photos, &photoList)
	return map[string]any{"title": title, "bodyMarkdown": body, "photos": photoList, "updatedAt": updatedAt}, nil
}

func (r *ContentRepository) UpdateAbout(ctx context.Context, title, body string, photos []string) (map[string]any, error) {
	if r.pool == nil {
		return r.GetAbout(ctx)
	}
	photosJSON, _ := json.Marshal(photos)
	_, err := r.pool.Exec(ctx, `UPDATE content_about SET title = $1, body_markdown = $2, photos = $3, updated_at = NOW()`, title, body, photosJSON)
	if err != nil {
		return nil, err
	}
	return r.GetAbout(ctx)
}

func (r *ContentRepository) GetServices(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{
			{"id": "1", "name": "Подъёмник дневной", "price": 2500.0, "category": "lift"},
		}, nil
	}
	rows, err := r.pool.Query(ctx, `SELECT id, name, description, price, category, sort_order, active FROM content_services WHERE active = TRUE ORDER BY sort_order`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanContentRows(rows, "name", "description", "price", "category", "sortOrder", "active")
}

func (r *ContentRepository) ListServicesAdmin(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return r.GetServices(ctx)
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, name, description, price, category, sort_order, active, source, external_key
		FROM content_services ORDER BY category, sort_order, name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanContentRows(rows, "name", "description", "price", "category", "sortOrder", "active", "source", "externalKey")
}

func (r *ContentRepository) GetSchedule(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{}, nil
	}
	rows, err := r.pool.Query(ctx, `SELECT id, service_name, day_of_week, open_time, close_time, closed FROM content_schedule ORDER BY service_name, day_of_week`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []map[string]any
	for rows.Next() {
		var id, serviceName string
		var dayOfWeek int
		var openTime, closeTime *string
		var closed bool
		if err := rows.Scan(&id, &serviceName, &dayOfWeek, &openTime, &closeTime, &closed); err != nil {
			return nil, err
		}
		items = append(items, map[string]any{
			"id": id, "serviceName": serviceName, "dayOfWeek": dayOfWeek,
			"openTime": openTime, "closeTime": closeTime, "closed": closed,
		})
	}
	return items, rows.Err()
}

func (r *ContentRepository) GetRules(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{
			{"ruleType": "visiting", "title": "Правила посещения", "bodyMarkdown": "Соблюдайте правила безопасности."},
		}, nil
	}
	rows, err := r.pool.Query(ctx, `SELECT id, rule_type, title, body_markdown FROM content_rules`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var items []map[string]any
	for rows.Next() {
		var id, ruleType, title, body string
		if err := rows.Scan(&id, &ruleType, &title, &body); err != nil {
			return nil, err
		}
		items = append(items, map[string]any{"id": id, "ruleType": ruleType, "title": title, "bodyMarkdown": body})
	}
	return items, rows.Err()
}

func (r *ContentRepository) UpdateRules(ctx context.Context, ruleType, title, body string) (map[string]any, error) {
	if r.pool == nil {
		return map[string]any{"ruleType": ruleType, "title": title, "bodyMarkdown": body}, nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE content_rules SET title = $2, body_markdown = $3, updated_at = NOW() WHERE rule_type = $1`, ruleType, title, body)
	if err != nil {
		return nil, err
	}
	return map[string]any{"ruleType": ruleType, "title": title, "bodyMarkdown": body}, nil
}

func (r *ContentRepository) GetWebcams(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{
			{"name": "Вид на гору от Визит-центра", "streamUrl": "https://rtsp.ru/embed/N7yi5kY5", "locationDescription": "Панорама с визит-центра"},
			{"name": "Верхняя опора КБД1", "streamUrl": "https://rtsp.ru/embed/s5RGdH4B", "locationDescription": "Верхняя станция"},
			{"name": "Визит Центр", "streamUrl": "https://rtsp.ru/embed/DS46yN3h", "locationDescription": "Визит-центр"},
			{"name": "Озеро", "streamUrl": "https://rtsp.ru/embed/TkaaHKDB", "locationDescription": "Вид на озеро"},
		}, nil
	}
	rows, err := r.pool.Query(ctx, `SELECT id, name, stream_url, location_description, sort_order, active FROM content_webcams WHERE active = TRUE ORDER BY sort_order`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanContentRows(rows, "name", "streamUrl", "locationDescription", "sortOrder", "active")
}

func (r *ContentRepository) GetTrails(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{{"name": "Синяя трасса", "difficulty": "blue", "status": "open"}}, nil
	}
	rows, err := r.pool.Query(ctx, `SELECT id, name, difficulty, status, open_time, close_time, comment FROM content_trails ORDER BY sort_order`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanContentRows(rows, "name", "difficulty", "status", "openTime", "closeTime", "comment")
}

func (r *ContentRepository) GetLifts(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{{"name": "Кресельный №1", "status": "open"}}, nil
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, name, description, prices_text, status, open_time, close_time, comment, sort_order, source, external_key
		FROM content_lifts WHERE active = TRUE ORDER BY sort_order, name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanContentRows(rows)
}

func (r *ContentRepository) ListLiftsAdmin(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return r.GetLifts(ctx)
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, name, description, prices_text, status, open_time, close_time, comment, sort_order, source, external_key, active
		FROM content_lifts ORDER BY sort_order, name
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanContentRows(rows)
}

func (r *ContentRepository) GetHeadliners(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return []map[string]any{
			{"title": "Добро пожаловать в Горную Салангу", "subtitle": "Горнолыжный комплекс Кузбасса"},
		}, nil
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, title, subtitle, image_url, link_url, sort_order
		FROM content_headliners WHERE is_active = TRUE ORDER BY sort_order
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanContentRows(rows, "title", "subtitle", "imageUrl", "linkUrl", "sortOrder")
}

func (r *ContentRepository) ListHeadlinersAdmin(ctx context.Context) ([]map[string]any, error) {
	if r.pool == nil {
		return r.GetHeadliners(ctx)
	}
	rows, err := r.pool.Query(ctx, `
		SELECT id, title, subtitle, image_url, link_url, sort_order, is_active
		FROM content_headliners ORDER BY sort_order, created_at
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	return scanContentRows(rows, "title", "subtitle", "imageUrl", "linkUrl", "sortOrder", "active")
}

func (r *ContentRepository) CreateHeadliner(ctx context.Context, title, subtitle, imageURL, linkURL string, sortOrder int) (map[string]any, error) {
	id := uuid.NewString()
	if r.pool == nil {
		return map[string]any{"id": id, "title": title, "subtitle": subtitle}, nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO content_headliners (id, title, subtitle, image_url, link_url, sort_order)
		VALUES ($1, $2, $3, $4, $5, $6)
	`, id, title, subtitle, imageURL, linkURL, sortOrder)
	if err != nil {
		return nil, err
	}
	return map[string]any{
		"id": id, "title": title, "subtitle": subtitle,
		"imageUrl": imageURL, "linkUrl": linkURL, "sortOrder": sortOrder, "active": true,
	}, nil
}

func (r *ContentRepository) UpdateHeadliner(ctx context.Context, id string, title, subtitle, imageURL, linkURL *string, sortOrder *int, active *bool) (map[string]any, error) {
	if r.pool == nil {
		return map[string]any{"id": id}, nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE content_headliners SET
			title = COALESCE($2, title),
			subtitle = COALESCE($3, subtitle),
			image_url = COALESCE($4, image_url),
			link_url = COALESCE($5, link_url),
			sort_order = COALESCE($6, sort_order),
			is_active = COALESCE($7, is_active),
			updated_at = NOW()
		WHERE id = $1
	`, id, title, subtitle, imageURL, linkURL, sortOrder, active)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id}, nil
}

func (r *ContentRepository) DeleteHeadliner(ctx context.Context, id string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE content_headliners SET is_active = FALSE, updated_at = NOW() WHERE id = $1`, id)
	return err
}

func (r *ContentRepository) CreateService(ctx context.Context, name, description string, price float64, category string, sortOrder int) (map[string]any, error) {
	id := uuid.NewString()
	if r.pool == nil {
		return map[string]any{"id": id, "name": name, "price": price}, nil
	}
	_, err := r.pool.Exec(ctx, `INSERT INTO content_services (id, name, description, price, category, sort_order) VALUES ($1,$2,$3,$4,$5,$6)`, id, name, description, price, category, sortOrder)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id, "name": name, "description": description, "price": price, "category": category}, nil
}

func (r *ContentRepository) UpdateService(ctx context.Context, id string, name, description *string, price *float64, category *string, sortOrder *int, active *bool) (map[string]any, error) {
	if r.pool == nil {
		return map[string]any{"id": id}, nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE content_services SET
			name = COALESCE($2, name), description = COALESCE($3, description),
			price = COALESCE($4, price), category = COALESCE($5, category),
			sort_order = COALESCE($6, sort_order), active = COALESCE($7, active), updated_at = NOW()
		WHERE id = $1
	`, id, name, description, price, category, sortOrder, active)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id}, nil
}

func (r *ContentRepository) DeleteService(ctx context.Context, id string) error {
	if r.pool == nil {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE content_services SET active = FALSE WHERE id = $1`, id)
	return err
}

type SalangaServiceInput struct {
	Name        string
	Description string
	Price       float64
	Category    string
	ExternalKey string
	SortOrder   int
}

func (r *ContentRepository) SyncSalangaServices(ctx context.Context, items []SalangaServiceInput) (int, error) {
	if r.pool == nil {
		return len(items), nil
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, `
		UPDATE content_services SET active = FALSE, updated_at = NOW()
		WHERE source = 'salanga'
	`); err != nil {
		return 0, err
	}

	imported := 0
	for _, item := range items {
		_, err := tx.Exec(ctx, `
			INSERT INTO content_services (name, description, price, category, sort_order, source, external_key, active)
			VALUES ($1, $2, $3, $4, $5, 'salanga', $6, TRUE)
			ON CONFLICT (external_key) WHERE external_key IS NOT NULL DO UPDATE SET
				name = EXCLUDED.name,
				description = EXCLUDED.description,
				price = EXCLUDED.price,
				category = EXCLUDED.category,
				sort_order = EXCLUDED.sort_order,
				active = TRUE,
				updated_at = NOW()
		`, item.Name, item.Description, item.Price, item.Category, item.SortOrder, item.ExternalKey)
		if err != nil {
			return imported, err
		}
		imported++
	}

	if err := tx.Commit(ctx); err != nil {
		return 0, err
	}
	return imported, nil
}

func (r *ContentRepository) CreateWebcam(ctx context.Context, name, streamURL, locationDesc string, sortOrder int) (map[string]any, error) {
	id := uuid.NewString()
	if r.pool == nil {
		return map[string]any{"id": id, "name": name}, nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO content_webcams (id, name, stream_url, location_description, sort_order)
		VALUES ($1, $2, $3, $4, $5)
	`, id, name, streamURL, locationDesc, sortOrder)
	if err != nil {
		return nil, err
	}
	return map[string]any{
		"id": id, "name": name, "streamUrl": streamURL,
		"locationDescription": locationDesc, "sortOrder": sortOrder, "active": true,
	}, nil
}

func (r *ContentRepository) UpdateWebcam(ctx context.Context, id string, name, streamURL, locationDesc *string, sortOrder *int, active *bool) (map[string]any, error) {
	if r.pool == nil {
		return map[string]any{"id": id}, nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE content_webcams SET
			name = COALESCE($2, name), stream_url = COALESCE($3, stream_url),
			location_description = COALESCE($4, location_description),
			sort_order = COALESCE($5, sort_order), active = COALESCE($6, active), updated_at = NOW()
		WHERE id = $1
	`, id, name, streamURL, locationDesc, sortOrder, active)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id}, nil
}

func (r *ContentRepository) CreateTrail(ctx context.Context, name, difficulty, status, comment string, sortOrder int) (map[string]any, error) {
	id := uuid.NewString()
	if difficulty == "" {
		difficulty = "blue"
	}
	if status == "" {
		status = "closed"
	}
	if r.pool == nil {
		return map[string]any{"id": id, "name": name}, nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO content_trails (id, name, difficulty, status, comment, sort_order)
		VALUES ($1, $2, $3::trail_difficulty, $4, $5, $6)
	`, id, name, difficulty, status, comment, sortOrder)
	if err != nil {
		return nil, err
	}
	return map[string]any{
		"id": id, "name": name, "difficulty": difficulty, "status": status, "comment": comment, "sortOrder": sortOrder,
	}, nil
}

func (r *ContentRepository) UpdateTrail(ctx context.Context, id string, name, difficulty, status, comment *string) (map[string]any, error) {
	if r.pool == nil {
		return map[string]any{"id": id}, nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE content_trails SET
			name = COALESCE($2, name), difficulty = COALESCE($3::trail_difficulty, difficulty),
			status = COALESCE($4, status), comment = COALESCE($5, comment), updated_at = NOW()
		WHERE id = $1
	`, id, name, difficulty, status, comment)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id}, nil
}

func (r *ContentRepository) UpdateSchedule(ctx context.Context, id string, openTime, closeTime *string, closed *bool) (map[string]any, error) {
	if r.pool == nil {
		return map[string]any{"id": id}, nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE content_schedule SET
			open_time = COALESCE($2::time, open_time),
			close_time = COALESCE($3::time, close_time),
			closed = COALESCE($4, closed),
			updated_at = NOW()
		WHERE id = $1
	`, id, openTime, closeTime, closed)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id}, nil
}

func (r *ContentRepository) UpdateLift(ctx context.Context, id string, name, status, openTime, closeTime, comment, description, pricesText *string, active *bool) (map[string]any, error) {
	if r.pool == nil {
		return map[string]any{"id": id}, nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE content_lifts SET
			name = COALESCE($2, name),
			status = COALESCE($3, status),
			open_time = COALESCE($4::time, open_time),
			close_time = COALESCE($5::time, close_time),
			comment = COALESCE($6, comment),
			description = COALESCE($7, description),
			prices_text = COALESCE($8, prices_text),
			active = COALESCE($9, active),
			updated_at = NOW()
		WHERE id = $1
	`, id, name, status, openTime, closeTime, comment, description, pricesText, active)
	if err != nil {
		return nil, err
	}
	return map[string]any{"id": id}, nil
}

type SalangaLiftInput struct {
	Name        string
	Description string
	PricesText  string
	OpenTime    string
	CloseTime   string
	Comment     string
	ExternalKey string
	SortOrder   int
}

func (r *ContentRepository) SyncSalangaLifts(ctx context.Context, items []SalangaLiftInput) (int, error) {
	if r.pool == nil {
		return len(items), nil
	}

	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return 0, err
	}
	defer tx.Rollback(ctx)

	if _, err := tx.Exec(ctx, `
		UPDATE content_lifts SET active = FALSE, updated_at = NOW()
		WHERE source = 'salanga'
	`); err != nil {
		return 0, err
	}

	imported := 0
	for _, item := range items {
		_, err := tx.Exec(ctx, `
			INSERT INTO content_lifts (name, description, prices_text, status, open_time, close_time, comment, sort_order, source, external_key, active)
			VALUES ($1, $2, $3, 'open', $4::time, $5::time, $6, $7, 'salanga', $8, TRUE)
			ON CONFLICT (external_key) WHERE external_key IS NOT NULL DO UPDATE SET
				name = EXCLUDED.name,
				description = EXCLUDED.description,
				prices_text = EXCLUDED.prices_text,
				open_time = EXCLUDED.open_time,
				close_time = EXCLUDED.close_time,
				comment = EXCLUDED.comment,
				sort_order = EXCLUDED.sort_order,
				active = TRUE,
				updated_at = NOW()
		`, item.Name, item.Description, item.PricesText, item.OpenTime, item.CloseTime, item.Comment, item.SortOrder, item.ExternalKey)
		if err != nil {
			return imported, err
		}
		imported++
	}

	if err := tx.Commit(ctx); err != nil {
		return imported, err
	}
	return imported, nil
}

func (r *ContentRepository) SaveWeatherCache(ctx context.Context, data map[string]any) error {
	if r.pool == nil {
		return nil
	}
	b, _ := json.Marshal(data)
	_, err := r.pool.Exec(ctx, `INSERT INTO weather_cache (data) VALUES ($1)`, b)
	return err
}

func (r *ContentRepository) GetWeatherCache(ctx context.Context, maxAge time.Duration) (map[string]any, error) {
	if r.pool == nil {
		return nil, errors.New("no cache")
	}
	var data []byte
	err := r.pool.QueryRow(ctx, `
		SELECT data FROM weather_cache WHERE fetched_at > $1 ORDER BY fetched_at DESC LIMIT 1
	`, time.Now().Add(-maxAge)).Scan(&data)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, errors.New("no cache")
		}
		return nil, err
	}
	var out map[string]any
	if err := json.Unmarshal(data, &out); err != nil {
		return nil, err
	}
	return out, nil
}

func normalizeScanValue(val any) any {
	if val == nil {
		return nil
	}
	switch v := val.(type) {
	case [16]byte:
		if u, err := uuid.FromBytes(v[:]); err == nil {
			return u.String()
		}
		return fmt.Sprintf("%x", v)
	case []byte:
		if len(v) == 16 {
			if u, err := uuid.FromBytes(v); err == nil {
				return u.String()
			}
		}
		return string(v)
	case pgtype.UUID:
		if !v.Valid {
			return nil
		}
		if u, err := uuid.FromBytes(v.Bytes[:]); err == nil {
			return u.String()
		}
		return nil
	case pgtype.Numeric:
		f, err := v.Float64Value()
		if err == nil && f.Valid {
			return f.Float64
		}
		return nil
	case pgtype.Time:
		if !v.Valid {
			return nil
		}
		totalSec := v.Microseconds / 1_000_000
		h := totalSec / 3600
		m := (totalSec % 3600) / 60
		s := totalSec % 60
		return fmt.Sprintf("%02d:%02d:%02d", h, m, s)
	default:
		return val
	}
}

func scanContentRows(rows pgx.Rows, _ ...string) ([]map[string]any, error) {
	fieldDescs := rows.FieldDescriptions()
	var items []map[string]any
	for rows.Next() {
		vals, err := rows.Values()
		if err != nil {
			return nil, err
		}
		item := make(map[string]any)
		for i, fd := range fieldDescs {
			key := string(fd.Name)
			if key == "stream_url" {
				key = "streamUrl"
			} else if key == "image_url" {
				key = "imageUrl"
			} else if key == "link_url" {
				key = "linkUrl"
			} else if key == "location_description" {
				key = "locationDescription"
			} else if key == "sort_order" {
				key = "sortOrder"
			} else if key == "open_time" {
				key = "openTime"
			} else if key == "close_time" {
				key = "closeTime"
			} else if key == "body_markdown" {
				key = "bodyMarkdown"
			} else if key == "rule_type" {
				key = "ruleType"
			} else if key == "external_key" {
				key = "externalKey"
			} else if key == "prices_text" {
				key = "pricesText"
			}
			item[key] = normalizeScanValue(vals[i])
		}
		items = append(items, item)
	}
	return items, rows.Err()
}
