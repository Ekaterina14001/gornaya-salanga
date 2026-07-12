-- Allow admin manual bonus adjustments
ALTER TYPE bonus_source ADD VALUE IF NOT EXISTS 'Admin';
