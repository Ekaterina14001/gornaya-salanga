-- Seed dev users (passwords: admin123 / guest123)
-- bcrypt hashes generated with cost 10

INSERT INTO users (id, first_name, last_name, phone, email, password_hash, role, phone_verified, email_verified, device_secret)
VALUES
    ('11111111-1111-1111-1111-111111111111', 'Админ', 'Системы', '+79000000001', 'admin@gornayasalanga.ru',
     '$2a$10$OV40BXecbYbegS4EhNoi/ufW55kI90w3YE6uuS4tG4KilbjbGa04i', 'admin', TRUE, TRUE, NULL),
    ('22222222-2222-2222-2222-222222222222', 'Иван', 'Гостев', '+79000000002', 'guest@gornayasalanga.ru',
     '$2a$10$Og4eDDJNcwX6aLZQ6cw.c.vJub1GQUDBBbbLQmmSWcoFkJi35T12.', 'guest', TRUE, TRUE,
     'dev-device-secret-guest-12345678901234567890123456789012');

INSERT INTO bonus_accounts (user_id, balance, total_earned, total_spent)
VALUES
    ('22222222-2222-2222-2222-222222222222', 1500.00, 3000.00, 1500.00);

INSERT INTO bonus_transactions (user_id, type, amount, source, order_id, description)
VALUES
    ('22222222-2222-2222-2222-222222222222', 'earn', 500.00, 'Shelter', 'ORD-001', 'Покупка в Shelter'),
    ('22222222-2222-2222-2222-222222222222', 'spend', 200.00, 'Bars', 'ORD-002', 'Оплата бонусами в Bars');

INSERT INTO content_services (name, description, price, category, sort_order) VALUES
    ('Подъёмник дневной', 'Дневной абонемент на подъёмник', 2500.00, 'lift', 1),
    ('Прокат лыж', 'Прокат комплекта лыж на день', 1200.00, 'rental', 2);

INSERT INTO content_webcams (name, stream_url, location_description, sort_order) VALUES
    ('Вид на гору от Визит-центра', 'https://rtsp.ru/embed/N7yi5kY5', 'Панорама с визит-центра', 1),
    ('Верхняя опора КБД1', 'https://rtsp.ru/embed/s5RGdH4B', 'Верхняя станция канатной дороги', 2),
    ('Визит Центр', 'https://rtsp.ru/embed/DS46yN3h', 'Территория визит-центра', 3),
    ('Озеро', 'https://rtsp.ru/embed/TkaaHKDB', 'Вид на озеро', 4);

INSERT INTO content_trails (name, difficulty, status, open_time, close_time) VALUES
    ('Синяя трасса', 'blue', 'open', '09:00', '17:00'),
    ('Красная трасса', 'red', 'closed', '09:00', '16:00');

INSERT INTO content_lifts (name, status, open_time, close_time) VALUES
    ('Кресельный №1', 'open', '09:00', '17:00'),
    ('Бугель №2', 'closed', '09:00', '16:30');

INSERT INTO content_schedule (service_name, day_of_week, open_time, close_time) VALUES
    ('reception', 1, '08:00', '20:00'),
    ('restaurant', 1, '10:00', '22:00'),
    ('ski_lift', 1, '09:00', '17:00'),
    ('rental', 1, '08:30', '18:00');
