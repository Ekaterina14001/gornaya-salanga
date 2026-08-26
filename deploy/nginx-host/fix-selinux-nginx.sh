#!/bin/bash
# CentOS/RHEL: allow nginx to proxy to Docker on 127.0.0.1:8080/8081
# Run once: sudo bash fix-selinux-nginx.sh

set -euo pipefail

if [ "$(getenforce 2>/dev/null)" = "Enforcing" ]; then
  echo "SELinux: enabling httpd_can_network_connect..."
  setsebool -P httpd_can_network_connect 1
fi

if command -v firewall-cmd >/dev/null 2>&1; then
  echo "Firewalld: opening HTTP/HTTPS..."
  firewall-cmd --permanent --add-service=http
  firewall-cmd --permanent --add-service=https
  firewall-cmd --reload
fi

systemctl reload nginx 2>/dev/null || true

echo "Test:"
curl -s -H 'Host: api.salanga.ru' http://127.0.0.1/health || true
echo ""
curl -s -o /dev/null -w 'admin: %{http_code}\n' -H 'Host: admin.salanga.ru' http://127.0.0.1/
