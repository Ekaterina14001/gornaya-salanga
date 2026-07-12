-- Initial schema for Gornaya Salanga

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE user_role AS ENUM ('guest', 'admin');
CREATE TYPE bonus_tx_type AS ENUM ('earn', 'spend');
CREATE TYPE bonus_source AS ENUM ('Shelter', 'Bars', 'RKeeper');
CREATE TYPE notification_type AS ENUM ('bonus', 'booking', 'news', 'event', 'promo', 'system');
CREATE TYPE pos_system AS ENUM ('Shelter', 'Bars', 'RKeeper');
CREATE TYPE message_status AS ENUM ('unread', 'read', 'replied');
CREATE TYPE trail_difficulty AS ENUM ('green', 'blue', 'red', 'black');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'guest',
    phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    device_secret VARCHAR(128),
    blocked BOOLEAN NOT NULL DEFAULT FALSE,
    last_activity_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE bonus_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    balance DECIMAL(12, 2) NOT NULL DEFAULT 0,
    total_earned DECIMAL(12, 2) NOT NULL DEFAULT 0,
    total_spent DECIMAL(12, 2) NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE bonus_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type bonus_tx_type NOT NULL,
    amount DECIMAL(12, 2) NOT NULL,
    source bonus_source,
    order_id VARCHAR(100),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_bonus_tx_user_created ON bonus_transactions(user_id, created_at DESC);
CREATE INDEX idx_bonus_tx_type ON bonus_transactions(type);

CREATE TABLE bonus_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    earn_percentage_global DECIMAL(5, 2) NOT NULL DEFAULT 5.00,
    earn_percentage_shelter DECIMAL(5, 2) NOT NULL DEFAULT 5.00,
    earn_percentage_bars DECIMAL(5, 2) NOT NULL DEFAULT 3.00,
    earn_percentage_rkeeper DECIMAL(5, 2) NOT NULL DEFAULT 4.00,
    max_spend_percentage DECIMAL(5, 2) NOT NULL DEFAULT 50.00,
    bonus_expiry_days INT NOT NULL DEFAULT 365,
    min_receipt_amount DECIMAL(12, 2) NOT NULL DEFAULT 100.00,
    qr_ttl_seconds INT NOT NULL DEFAULT 60,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE bonus_config_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES users(id),
    changes JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE pos_api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system pos_system NOT NULL,
    api_key_hash VARCHAR(255) NOT NULL,
    api_key_prefix VARCHAR(16) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ
);

CREATE TABLE pos_request_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system pos_system NOT NULL,
    endpoint VARCHAR(255) NOT NULL,
    status_code INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type notification_type NOT NULL DEFAULT 'news',
    data JSONB DEFAULT '{}',
    read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_created ON notifications(user_id, created_at DESC);

CREATE TABLE content_about (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL DEFAULT 'О курорте',
    body_markdown TEXT NOT NULL DEFAULT '',
    photos JSONB DEFAULT '[]',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE content_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(12, 2) NOT NULL DEFAULT 0,
    category VARCHAR(100),
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE content_schedule (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_name VARCHAR(100) NOT NULL,
    day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    open_time TIME,
    close_time TIME,
    break_start TIME,
    break_end TIME,
    closed BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(service_name, day_of_week)
);

CREATE TABLE content_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_type VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(255) NOT NULL,
    body_markdown TEXT NOT NULL DEFAULT '',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE content_webcams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    stream_url TEXT NOT NULL,
    location_description TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE content_trails (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    difficulty trail_difficulty NOT NULL DEFAULT 'blue',
    status VARCHAR(20) NOT NULL DEFAULT 'closed',
    open_time TIME,
    close_time TIME,
    comment TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE content_lifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'closed',
    open_time TIME,
    close_time TIME,
    comment TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    status message_status NOT NULL DEFAULT 'unread',
    admin_reply TEXT,
    replied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_messages_status ON user_messages(status, created_at DESC);

CREATE TABLE weather_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data JSONB NOT NULL,
    fetched_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO bonus_config (id) VALUES (gen_random_uuid());

INSERT INTO content_about (title, body_markdown) VALUES (
    'Горная Саланга',
    'Добро пожаловать на горнолыжный курорт «Горная Саланга» — место отдыха, спорта и незабываемых впечатлений.'
);

INSERT INTO content_rules (rule_type, title, body_markdown) VALUES
    ('visiting', 'Правила посещения', 'Соблюдайте правила безопасности на склонах.'),
    ('bonus', 'Правила бонусной программы', 'Бонусы начисляются за покупки в заведениях курорта.');
