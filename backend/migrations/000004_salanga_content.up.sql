-- Real rtsp.ru webcams from legacy Mobile app + headliners table

DELETE FROM content_webcams;

INSERT INTO content_webcams (name, stream_url, location_description, sort_order) VALUES
    ('Вид на гору от Визит-центра', 'https://rtsp.ru/embed/N7yi5kY5', 'Панорама с визит-центра', 1),
    ('Верхняя опора КБД1', 'https://rtsp.ru/embed/s5RGdH4B', 'Верхняя станция канатной дороги', 2),
    ('Визит Центр', 'https://rtsp.ru/embed/DS46yN3h', 'Территория визит-центра', 3),
    ('Озеро', 'https://rtsp.ru/embed/TkaaHKDB', 'Вид на озеро', 4);

CREATE TABLE IF NOT EXISTS content_headliners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    subtitle VARCHAR(255),
    image_url TEXT,
    link_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO content_headliners (title, subtitle, image_url, link_url, sort_order) VALUES
    ('Добро пожаловать в Горную Салангу', 'Горнолыжный комплекс Кузбасса', '', 'https://www.salanga.ru', 1),
    ('Бонусная программа', 'Копите и тратьте бонусы на курорте', '', '/bonus', 2);
