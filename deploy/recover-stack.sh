#!/usr/bin/env bash
# Восстановление admin + api + mobile-web на api.salanga.ru
# Запуск на сервере: bash /home/dev/gornaya-salanga/deploy/recover-stack.sh

set -euo pipefail

DEPLOY_DIR="${DEPLOY_DIR:-/home/dev/gornaya-salanga/deploy}"
cd "$DEPLOY_DIR"

if [[ ! -f .env ]]; then
  echo "ERROR: $DEPLOY_DIR/.env not found"
  exit 1
fi

echo "=== Docker compose ps (before) ==="
docker compose ps -a || true

echo ""
echo "=== Rebuild & start stack ==="
docker compose up -d --build postgres redis
docker compose run --rm migrate || true
docker compose up -d --build api mobile-web admin

echo ""
echo "=== Wait for API health ==="
for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:8080/health >/dev/null 2>&1; then
    echo "API OK"
    break
  fi
  sleep 2
done

echo ""
echo "=== Local checks ==="
echo -n "health (via admin nginx :80): "
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/health || echo "FAIL"
echo -n "admin /: "
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/ || echo "FAIL"
echo -n "app /app/: "
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1/app/ || echo "FAIL"

echo ""
echo "=== Recent logs (admin, api) ==="
docker compose logs admin --tail 40 2>&1 || true
docker compose logs api --tail 20 2>&1 || true

echo ""
echo "=== docker compose ps (after) ==="
docker compose ps
