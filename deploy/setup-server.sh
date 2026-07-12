#!/bin/bash
# One-time VPS setup (Ubuntu 22.04/24.04). Run as root on the server.
# Usage: curl -fsSL ... | bash   OR   bash setup-server.sh

set -euo pipefail

echo "=== Gornaya Salanga — VPS setup ==="

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
  systemctl enable docker
  systemctl start docker
fi

echo "Docker: $(docker --version)"
echo "Compose: $(docker compose version)"

# Firewall: SSH + API + Admin
if command -v ufw >/dev/null 2>&1; then
  ufw allow OpenSSH
  ufw allow 80/tcp
  ufw allow 8080/tcp
  ufw --force enable || true
  echo "UFW: ports 22, 80, 8080 open"
fi

PUBLIC_IP=$(curl -4 -s ifconfig.me || curl -4 -s icanhazip.com || hostname -I | awk '{print $1}')
echo ""
echo "Server public IP (check): $PUBLIC_IP"
echo ""
echo "Next steps:"
echo "  1. Upload/clone project to /opt/gornaya-salanga (or ~/gornaya-salanga)"
echo "  2. cd deploy && cp .env.example .env && nano .env"
echo "     Set PUBLIC_HOST and PUBLIC_API_URL to this server IP"
echo "     Set POSTGRES_PASSWORD, JWT_SECRET, JWT_REFRESH_SECRET"
echo "     Update DATABASE_URL password to match POSTGRES_PASSWORD"
echo "  3. docker compose up -d --build"
echo "  4. curl http://$PUBLIC_IP:8080/health"
echo "  5. Open admin: http://$PUBLIC_IP"
echo "  6. Rebuild mobile APK with PUBLIC_API_URL"
