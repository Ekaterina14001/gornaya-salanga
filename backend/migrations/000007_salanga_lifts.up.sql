ALTER TABLE content_lifts
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS prices_text TEXT,
    ADD COLUMN IF NOT EXISTS source VARCHAR(50),
    ADD COLUMN IF NOT EXISTS external_key VARCHAR(255),
    ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT TRUE;

CREATE UNIQUE INDEX IF NOT EXISTS idx_content_lifts_external_key
    ON content_lifts (external_key)
    WHERE external_key IS NOT NULL;
