UPDATE content_headliners SET title = 'Баннер' WHERE title IS NULL OR title = '';
ALTER TABLE content_headliners ALTER COLUMN title SET NOT NULL;
ALTER TABLE content_headliners ALTER COLUMN title DROP DEFAULT;
