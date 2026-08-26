-- Revert to previous (broken) seed hashes — for rollback only.
UPDATE users
SET password_hash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE email IN ('admin@gornayasalanga.ru', 'guest@gornayasalanga.ru');
