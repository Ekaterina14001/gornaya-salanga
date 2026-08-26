-- Fix dev/demo password hashes (admin123 / guest123).
-- Previous seed used an invalid bcrypt hash; production (GIN_MODE=release) has no dev bypass.

UPDATE users
SET password_hash = '$2a$10$OV40BXecbYbegS4EhNoi/ufW55kI90w3YE6uuS4tG4KilbjbGa04i'
WHERE email = 'admin@gornayasalanga.ru';

UPDATE users
SET password_hash = '$2a$10$Og4eDDJNcwX6aLZQ6cw.c.vJub1GQUDBBbbLQmmSWcoFkJi35T12.'
WHERE email = 'guest@gornayasalanga.ru';
