DROP INDEX IF EXISTS idx_content_lifts_external_key;

ALTER TABLE content_lifts
    DROP COLUMN IF EXISTS active,
    DROP COLUMN IF EXISTS external_key,
    DROP COLUMN IF EXISTS source,
    DROP COLUMN IF EXISTS prices_text,
    DROP COLUMN IF EXISTS description;
