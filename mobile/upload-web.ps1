# Upload Flutter web + deploy configs to VPS and restart containers.
# Run build-web.ps1 first.
# Usage: powershell -ExecutionPolicy Bypass -File .\upload-web.ps1

param(
    [string]$Server = "root@91.218.113.254",
    [string]$RemotePath = "/opt/gornaya-salanga"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$webBuild = Join-Path $PSScriptRoot "build\web"

if (-not (Test-Path (Join-Path $webBuild "index.html"))) {
    Write-Host "Run build-web.ps1 first." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

$ssh = Get-Command ssh -ErrorAction SilentlyContinue
$scp = Get-Command scp -ErrorAction SilentlyContinue
if (-not $ssh -or -not $scp) {
    Write-Error "OpenSSH client required (Settings -> Apps -> Optional features -> OpenSSH Client)"
}

Write-Host "=== Deploy Flutter Web to VPS ===" -ForegroundColor Cyan
Write-Host "Server: $Server"
Write-Host ""

Write-Host "1/4 Uploading build/web ..."
ssh $Server "mkdir -p $RemotePath/mobile/build"
scp -r "$webBuild" "${Server}:${RemotePath}/mobile/build/"

Write-Host "2/4 Uploading Docker/nginx configs ..."
scp (Join-Path $PSScriptRoot "Dockerfile.web") "${Server}:${RemotePath}/mobile/Dockerfile.web"
scp (Join-Path $PSScriptRoot "web-nginx.conf") "${Server}:${RemotePath}/mobile/web-nginx.conf"
scp (Join-Path $repoRoot "admin\nginx.conf") "${Server}:${RemotePath}/admin/nginx.conf"
scp (Join-Path $repoRoot "deploy\docker-compose.yml") "${Server}:${RemotePath}/deploy/docker-compose.yml"

Write-Host "3/4 Ensuring API on port 80 in deploy/.env ..."
ssh $Server @"
if grep -q 'PUBLIC_API_URL=http://91.218.113.254:8080' $RemotePath/deploy/.env 2>/dev/null; then
  sed -i 's|PUBLIC_API_URL=http://91.218.113.254:8080|PUBLIC_API_URL=http://91.218.113.254|' $RemotePath/deploy/.env
fi
"@

Write-Host "4/4 Rebuilding containers (mobile-web, admin) ..."
ssh $Server "cd $RemotePath/deploy && docker compose up -d --build mobile-web admin && docker exec \$(docker compose ps -q mobile-web) chmod -R a+rX /usr/share/nginx/html 2>/dev/null || true"

Write-Host ""
Write-Host "Checking /app/ ..."
ssh $Server "curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/app/ && echo '' && curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/health && echo ''"

Write-Host ""
Write-Host "Done. Open on iPhone (Wi-Fi):" -ForegroundColor Green
Write-Host "  http://91.218.113.254/app/"
Write-Host "Guest: guest@gornayasalanga.ru / guest123"
Write-Host ""
Read-Host "Press Enter to close"
