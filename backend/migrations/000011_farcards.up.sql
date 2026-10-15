CREATE TABLE farcards_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant TEXT NOT NULL,
    rk_unit TEXT NOT NULL,
    rk_check TEXT NOT NULL,
    card_code BIGINT NOT NULL,
    points_spent DECIMAL(12, 2) NOT NULL DEFAULT 0,
    points_earned DECIMAL(12, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (restaurant, rk_unit, rk_check, card_code)
);

CREATE INDEX farcards_receipts_created_idx ON farcards_receipts (created_at DESC);
