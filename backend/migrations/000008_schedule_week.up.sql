-- Fill schedule for all days of week using Monday template (day_of_week = 1).
INSERT INTO content_schedule (service_name, day_of_week, open_time, close_time, closed)
SELECT service_name, d.day, open_time, close_time, closed
FROM content_schedule
CROSS JOIN (VALUES (0), (2), (3), (4), (5), (6)) AS d(day)
WHERE day_of_week = 1
ON CONFLICT (service_name, day_of_week) DO NOTHING;
