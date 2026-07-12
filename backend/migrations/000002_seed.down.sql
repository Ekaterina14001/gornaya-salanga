DELETE FROM content_schedule;
DELETE FROM content_lifts;
DELETE FROM content_trails;
DELETE FROM content_webcams;
DELETE FROM content_services;
DELETE FROM bonus_transactions;
DELETE FROM bonus_accounts;
DELETE FROM users WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222'
);
