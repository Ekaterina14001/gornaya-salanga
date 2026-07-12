ALTER TABLE content_services
    ADD COLUMN IF NOT EXISTS source VARCHAR(50) NOT NULL DEFAULT 'manual',
    ADD COLUMN IF NOT EXISTS external_key VARCHAR(255);

CREATE UNIQUE INDEX IF NOT EXISTS idx_content_services_external_key
    ON content_services (external_key)
    WHERE external_key IS NOT NULL;
