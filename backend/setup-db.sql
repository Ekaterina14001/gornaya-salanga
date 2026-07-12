-- Run as PostgreSQL superuser (postgres) in pgAdmin or psql.
-- Creates dev user/database for Gornaya Salanga backend.

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'salanga') THEN
    CREATE ROLE salanga LOGIN PASSWORD 'salanga';
  ELSE
    ALTER ROLE salanga WITH LOGIN PASSWORD 'salanga';
  END IF;
END
$$;

SELECT format('CREATE DATABASE %I OWNER salanga', 'gornaya_salanga')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'gornaya_salanga')\gexec

GRANT ALL PRIVILEGES ON DATABASE gornaya_salanga TO salanga;
