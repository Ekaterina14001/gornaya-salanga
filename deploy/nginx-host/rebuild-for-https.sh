#!/bin/bash
# After HTTPS is enabled: point clients at https://api.salanga.ru and rebuild Docker images.
# Run as dev: bash deploy/nginx-host/rebuild-for-https.sh

set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$DEPLOY_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found"
  exit 1
fi

cd "$DEPLOY_DIR"

if grep -q '^PUBLIC_API_URL=https://api.salanga.ru' "$ENV_FILE"; then
  echo "PUBLIC_API_URL already https"
else
  sed -i 's|^PUBLIC_API_URL=.*|PUBLIC_API_URL=https://api.salanga.ru|' "$ENV_FILE"
  sed -i 's|^ADMIN_ORIGIN=.*|ADMIN_ORIGIN=https://admin.salanga.ru|' "$ENV_FILE"
  sed -i 's|^PUBLIC_HOST=.*|PUBLIC_HOST=admin.salanga.ru|' "$ENV_FILE"
  if grep -q '^CORS_ORIGINS=' "$ENV_FILE"; then
    sed -i 's|^CORS_ORIGINS=.*|CORS_ORIGINS=https://admin.salanga.ru,https://api.salanga.ru,http://admin.salanga.ru,http://api.salanga.ru|' "$ENV_FILE"
  fi
  echo "Updated deploy/.env for HTTPS"
fi

echo "Rebuilding admin (VITE_API_URL baked at build)..."
docker compose build --no-cache admin
docker compose up -d admin

echo ""
echo "Done. Test:"
echo "  https://admin.salanga.ru/login"
echo "  https://admin.salanga.ru/app/"
