CREATE TABLE uds_participants (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE uds_operations (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    system VARCHAR(32) NOT NULL,
    nonce VARCHAR(64),
    action VARCHAR(32) NOT NULL,
    state VARCHAR(32) NOT NULL DEFAULT 'NORMAL',
    total DECIMAL(12, 2) NOT NULL,
    cash DECIMAL(12, 2) NOT NULL,
    points DECIMAL(12, 2) NOT NULL DEFAULT 0,
    cashback DECIMAL(12, 2) NOT NULL DEFAULT 0,
    receipt_number VARCHAR(100),
    origin_id BIGINT REFERENCES uds_operations(id),
    earn_tx_id UUID,
    spend_tx_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uds_operations_nonce_uidx ON uds_operations (nonce) WHERE nonce IS NOT NULL AND nonce <> '';
CREATE INDEX uds_operations_user_created_idx ON uds_operations (user_id, created_at DESC);
CREATE INDEX uds_operations_created_idx ON uds_operations (created_at DESC);
