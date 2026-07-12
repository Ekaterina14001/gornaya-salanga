DROP INDEX IF EXISTS idx_content_services_external_key;

ALTER TABLE content_services
    DROP COLUMN IF EXISTS external_key,
    DROP COLUMN IF EXISTS source;
