# Gornaya Salanga — Горная Саланга

Monorepo for the Gornaya Salanga mountain ski resort platform.

## Components

| Component | Stack | Port |
|-----------|-------|------|
| [backend/](backend/) | Go, Gin, PostgreSQL, Redis, JWT | `:8080` |
| [mobile/](mobile/) | Flutter, BLoC, GoRouter, Dio | — |
| [admin/](admin/) | React 18, TypeScript, shadcn/ui, TanStack Query | `:5173` |

## Prerequisites

- Go 1.22+
- Flutter 3.x
- Node.js 22 LTS
- Docker Desktop (recommended) or local PostgreSQL 16 + Redis 7

## Quick Start

### 1. Start infrastructure

```bash
docker compose up -d
```

**Windows:**

```powershell
.\start-infra.ps1
```

Поднимает PostgreSQL (`:5432`) и Redis (`:6379`). После запуска в логе backend должно быть `redis connected`. Проверка: http://localhost:8080/health → `"redis": "ok"`.

> **Windows:** в `backend/.env` укажите `REDIS_URL=redis://127.0.0.1:6379/0` (не `localhost` — иначе Go подключается по IPv6 `[::1]` и Redis не находится).

**Если Docker пишет «WSL needs updating»:**

```powershell
# PowerShell от имени администратора
.\setup-wsl.ps1
# Перезагрузка ПК, затем Docker Desktop -> Engine running
.\start-infra.ps1
```

**Быстрый обходной путь без Docker** (пока чините WSL):

```powershell
winget install Memurai.MemuraiDeveloper
.\start-redis-local.ps1
cd backend
go run ./cmd/api
```

### 2. Backend

```bash
cd backend
cp .env.example .env
make migrate-up
make run
```

**Windows (без `make`):**

```powershell
cd backend
copy .env.example .env
.\setup-db.ps1         # один раз: создать user/db в локальном PostgreSQL
.\migrate.ps1          # миграции
go run ./cmd/api      # запуск API
```

**Windows без Docker:** если `docker` не установлен, но PostgreSQL уже стоит локально (порт 5432), используйте `setup-db.ps1` — он создаст пользователя `salanga` / пароль `salanga` и БД `gornaya_salanga`. Без Redis API стартует, но OTP-коды и refresh-токены хранятся только в памяти процесса (сбрасываются при перезапуске). Для нормальной разработки лучше запустить Redis через Docker или `.\start-infra.ps1`.

**Порт 8080 занят:** предыдущий экземпляр API уже запущен (`api.exe`). Либо используйте http://localhost:8080/health, либо остановите процесс:

```powershell
netstat -ano | findstr :8080
taskkill /PID <PID> /F
```

Или вручную (если установлен [golang-migrate](https://github.com/golang-migrate/migrate)):

```powershell
migrate -path migrations -database "postgres://salanga:salanga@localhost:5432/gornaya_salanga?sslmode=disable" up
go run ./cmd/api
```

API: http://localhost:8080  
Health: http://localhost:8080/health

### 3. Admin panel

```bash
cd admin
cp .env.example .env
npm install
npm run dev
```

Admin: http://localhost:5173

**Dev credentials:**
- Admin: `admin@gornayasalanga.ru` / `admin123`
- Guest: `guest@gornayasalanga.ru` / `guest123`

### 4. Mobile app

```bash
cd mobile
flutter pub get
flutter devices          # посмотреть доступные устройства
```

**Браузер (Chrome / Edge):**
```powershell
flutter run -d chrome
```
API по умолчанию: `http://localhost:8080` (backend должен быть запущен).

**Android-эмулятор:**
```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

**Физический телефон:** IP компьютера в Wi‑Fi, например `--dart-define=API_BASE_URL=http://192.168.1.5:8080`.

> Если в `flutter devices` только Chrome/Edge — установите [Android Studio](https://developer.android.com/studio) и создайте AVD (Virtual Device Manager).

### Demo APK (Android, для заказчика)

**На ПК** (backend + Redis + PostgreSQL должны работать):

```powershell
.\start-infra.ps1
cd backend
go run ./cmd/api
```

В **другом** терминале:

```powershell
.\demo-api-url.ps1          # покажет http://192.168.x.x:8080
cd mobile
.\build-demo-apk.ps1        # соберёт APK в dist\
```

APK и `DEMO-APK-README.txt` появятся в папке `dist\`. Телефон и ПК — в одной Wi‑Fi сети.

**Установка на телефон:** скопировать APK или `adb install -r dist\gornaya-salanga-demo-....apk`

**Демо-логин:** `guest@gornayasalanga.ru` / `guest123` · SMS-код при регистрации: `123456`

Если с телефона не открывается API — разрешите порт 8080 в брандмауэре Windows (частная сеть).

## Architecture

```
Flutter App ──JWT──► Go REST API ◄──JWT (admin)── React Admin
POS Systems ──API Key──►         ◄── PostgreSQL + Redis
```

## Data sources

- **Weather:** parsed from [salanga.ru/weather](https://www.salanga.ru/weather) on the backend (15 min cache). OpenWeatherMap is used as fallback if scraping fails.
- **Webcams:** live streams via [rtsp.ru](https://rtsp.ru) embeds (4 cameras from the resort).
- **Prices / services:** parsed from [salanga.ru/pricelist-ski](https://www.salanga.ru/pricelist-ski/). In admin → **Контент** → «Импортировать прайс с сайта», or `POST /api/admin/content/services/sync-salanga`. Requires migration `000005`.

## Development

- Migrations: `backend/migrations/` (golang-migrate)
- API routes registered in `backend/internal/router/`
- Flutter features in `mobile/lib/features/`
- Admin pages in `admin/src/pages/`

## License

Proprietary — Gornaya Salanga resort.

## Demo VPS (тест из другого города)

Развёртывание API + админки на арендованном сервере (Timeweb, Selectel и т.д.).

### 1. Арендовать VPS

- Ubuntu 22.04/24.04, **2 CPU, 4 GB RAM**, публичный IPv4
- Открытые порты: **22** (SSH), **80** (админка), **8080** (API)

### 2. Подготовить `.env` на Windows

```powershell
cd deploy
.\prepare-deploy-env.ps1
# Введите публичный IP VPS
```

### 3. Настроить сервер (один раз, по SSH)

```bash
# На VPS:
git clone <url-репозитория> /opt/gornaya-salanga
cd /opt/gornaya-salanga/deploy
bash setup-server.sh
cp .env.example .env   # или загрузите .env с ПК
nano .env              # PUBLIC_HOST, пароли, JWT
docker compose up -d --build
```

Или с Windows (OpenSSH + доступ по ключу):

```powershell
cd deploy
.\upload-to-vps.ps1 -Server root@ВАШ_IP
```

### 4. Проверка

- API: `http://ВАШ_IP:8080/health` → `"redis":"ok"`
- Админка: `http://ВАШ_IP` → `admin@gornayasalanga.ru` / `admin123`

### 5. APK для тестировщиков в другом городе

```powershell
cd mobile
.\build-demo-apk.ps1 -ApiUrl "http://ВАШ_IP:8080"
```

Отправить файл из `dist\` + `DEMO-APK-README.txt`.

**Демо-логин:** `guest@gornayasalanga.ru` / `guest123` · SMS-код: `123456`

### Обновление после изменений в коде

На VPS:

```bash
cd /opt/gornaya-salanga
git pull
cd deploy
docker compose up -d --build
```

Файлы: `deploy/docker-compose.yml`, `backend/Dockerfile`, `admin/Dockerfile`.

