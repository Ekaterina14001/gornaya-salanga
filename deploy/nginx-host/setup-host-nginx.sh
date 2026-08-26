#!/bin/bash
# Install host nginx + Let's Encrypt for api.salanga.ru and admin.salanga.ru.
# Run on the VPS as root: sudo CERTBOT_EMAIL=you@domain bash setup-host-nginx.sh
# Docker stack must listen on 127.0.0.1:8080 (api) and 127.0.0.1:8081 (admin).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTBOT_EMAIL="${CERTBOT_EMAIL:-noreply@salanga.ru}"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root: sudo CERTBOT_EMAIL=$CERTBOT_EMAIL bash $0"
  exit 1
fi

echo "=== Host nginx + SSL for salanga.ru ==="
echo "Certbot email: $CERTBOT_EMAIL"

install_packages() {
  if command -v dnf >/dev/null 2>&1; then
    if ! command -v certbot >/dev/null 2>&1; then
      dnf install -y epel-release 2>/dev/null || true
      dnf install -y certbot python3-certbot-nginx curl openssl
    fi
    if ! command -v nginx >/dev/null 2>&1; then
      dnf install -y nginx
    fi
  elif command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y nginx certbot python3-certbot-nginx curl openssl
  else
    echo "ERROR: unsupported OS (need dnf or apt-get)"
    exit 1
  fi
}

nginx_conf_dir() {
  if [ -d /etc/nginx/conf.d ]; then
    echo /etc/nginx/conf.d
  else
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    echo /etc/nginx/sites-available
  fi
}

install_ssl_extras() {
  mkdir -p /etc/letsencrypt
  if [ ! -f /etc/letsencrypt/options-ssl-nginx.conf ]; then
    echo "Creating options-ssl-nginx.conf..."
    cat > /etc/letsencrypt/options-ssl-nginx.conf <<'NGINX_SSL'
ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
NGINX_SSL
  fi
  if [ ! -f /etc/letsencrypt/ssl-dhparams.pem ]; then
    echo "Generating ssl-dhparams.pem (may take a minute)..."
    openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048
  fi
}

install_packages
CONF_DIR="$(nginx_conf_dir)"
mkdir -p /var/www/certbot
if command -v semanage >/dev/null 2>&1; then
  semanage fcontext -a -t httpd_sys_content_t '/var/www/certbot(/.*)?' 2>/dev/null || \
    semanage fcontext -m -t httpd_sys_content_t '/var/www/certbot(/.*)?' 2>/dev/null || true
  restorecon -Rv /var/www/certbot 2>/dev/null || true
fi

# HTTP bootstrap (required for webroot certbot when certs don't exist)
if [ ! -f /etc/letsencrypt/live/api.salanga.ru/fullchain.pem ] || \
   [ ! -f /etc/letsencrypt/live/admin.salanga.ru/fullchain.pem ]; then
  echo "Installing HTTP bootstrap config..."
  cp "$SCRIPT_DIR/http-only-bootstrap.conf" "$CONF_DIR/salanga.conf"
  rm -f "$CONF_DIR/api.salanga.ru.conf" "$CONF_DIR/admin.salanga.ru.conf" 2>/dev/null || true
  nginx -t
  systemctl enable nginx
  systemctl start nginx 2>/dev/null || true
  systemctl reload nginx

  echo "Requesting Let's Encrypt certificates..."
  certbot certonly --webroot -w /var/www/certbot \
    -d api.salanga.ru \
    --non-interactive --agree-tos --email "$CERTBOT_EMAIL" \
    --no-eff-email

  certbot certonly --webroot -w /var/www/certbot \
    -d admin.salanga.ru \
    --non-interactive --agree-tos --email "$CERTBOT_EMAIL" \
    --no-eff-email
fi

install_ssl_extras

echo "Installing HTTPS nginx configs..."
cp "$SCRIPT_DIR/api.salanga.ru.conf" "$CONF_DIR/api.salanga.ru.conf"
cp "$SCRIPT_DIR/admin.salanga.ru.conf" "$CONF_DIR/admin.salanga.ru.conf"
rm -f "$CONF_DIR/salanga.conf" 2>/dev/null || true

# CentOS/RHEL: SELinux + firewalld
if [ -f "$SCRIPT_DIR/fix-selinux-nginx.sh" ]; then
  bash "$SCRIPT_DIR/fix-selinux-nginx.sh"
fi

nginx -t
systemctl enable nginx
systemctl reload nginx

# Auto-renewal timer (certbot package usually installs this)
if systemctl list-unit-files certbot-renew.timer >/dev/null 2>&1; then
  systemctl enable --now certbot-renew.timer 2>/dev/null || true
fi

echo ""
echo "=== HTTPS nginx ready ==="
echo "Check:"
echo "  curl -s https://api.salanga.ru/health"
echo "  curl -sI https://admin.salanga.ru/"
echo ""
echo "Next (as dev user): rebuild admin/web for https API URL:"
echo "  bash $SCRIPT_DIR/rebuild-for-https.sh"
