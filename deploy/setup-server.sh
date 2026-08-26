#!/bin/bash
# One-time VPS setup (Ubuntu 22.04/24.04). Run as root on the server.
# Usage: bash setup-server.sh

set -euo pipefail

echo "=== Gornaya Salanga — VPS setup ==="

# Docker install / repair
if ! command -v docker >/dev/null 2>&1; then
  echo "Installing Docker..."
  apt-get update
  apt-get install -y ca-certificates curl gnupg ufw git
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
fi

systemctl enable docker
systemctl start docker || {
  echo "Docker failed to start. Check: journalctl -u docker -n 50"
  exit 1
}

# Allow non-root docker (e.g. user dev)
if id dev >/dev/null 2>&1; then
  usermod -aG docker dev || true
  echo "User dev added to docker group (re-login required)"
fi

echo "Docker: $(docker --version)"
echo "Compose: $(docker compose version)"

# Host nginx for salanga.ru domains (optional; see nginx-host/setup-host-nginx.sh)
if ! command -v nginx >/dev/null 2>&1; then
  apt-get install -y nginx certbot python3-certbot-nginx || true
fi

# Firewall
if command -v ufw >/dev/null 2>&1; then
  ufw allow 22022/tcp comment 'SSH custom' || ufw allow OpenSSH
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable || true
  echo "UFW: ports 22022 (or 22), 80, 443 open"
fi

PUBLIC_IP=$(curl -4 -s ifconfig.me || curl -4 -s icanhazip.com || hostname -I | awk '{print $1}')
echo ""
echo "Server public IP (check): $PUBLIC_IP"
echo ""
echo "salanga.ru production:"
echo "  1. Upload project to /home/dev/gornaya-salanga"
echo "  2. deploy/.env — api.salanga.ru + admin.salanga.ru (see prepare-salanga-env.ps1)"
echo "  3. cd deploy && docker compose up -d --build"
echo "  4. sudo bash deploy/nginx-host/setup-host-nginx.sh"
echo "  5. curl http://api.salanga.ru/health"
echo "  6. Open https://admin.salanga.ru after certbot"
