# Upload project to salanga.ru production server.
# Usage:
#   .\upload-salanga.ps1
#   .\upload-salanga.ps1 -PpkPath C:\Users\AN\Downloads\dev@api.salanga.ru.ppk
#
# Requires: OpenSSH client, SSH key for dev@api.salanga.ru:22022

param(
    [string]$Server = "dev@api.salanga.ru",
    [int]$Port = 22022,
    [string]$PpkPath = "C:\Users\AN\Downloads\dev@api.salanga.ru.ppk",
    [string]$SshKeyPath = "",
    [string]$RemotePath = "/home/dev/gornaya-salanga",
    [switch]$DockerOnly
)

$ErrorActionPreference = "Stop"
$deployDir = $PSScriptRoot
$repoRoot = Split-Path $deployDir -Parent

if (-not (Test-Path (Join-Path $deployDir ".env"))) {
    Write-Error "deploy/.env not found. Configure production env first."
}

if ([string]::IsNullOrWhiteSpace($SshKeyPath)) {
    $SshKeyPath = Join-Path $deployDir "salanga_dev"
    if (-not (Test-Path $SshKeyPath)) {
        $SshKeyPath = Join-Path $env:USERPROFILE ".ssh\salanga_dev"
    }
}

if (-not (Test-Path $SshKeyPath)) {
    if (-not (Test-Path $PpkPath)) {
        Write-Error "SSH key not found. Pass -PpkPath to the .ppk from the client."
    }
    Write-Host "Converting PPK to OpenSSH key..." -ForegroundColor Cyan
    & (Join-Path $deployDir "convert-ppk.ps1") -PpkPath $PpkPath -OutPath (Join-Path $deployDir "salanga_dev")
    $SshKeyPath = Join-Path $deployDir "salanga_dev"
}

$webBuild = Join-Path $repoRoot "mobile\build\web\index.html"
if (-not (Test-Path $webBuild)) {
    Write-Error "mobile/build/web not found. Run: cd ..\mobile; .\build-web.ps1 -ApiUrl http://api.salanga.ru"
}

$sshArgs = @(
    "-p", "$Port",
    "-i", $SshKeyPath,
    "-o", "BatchMode=yes",
    "-o", "ConnectTimeout=30",
    "-o", "ServerAliveInterval=15",
    "-o", "StrictHostKeyChecking=accept-new"
)
$scpArgs = @("-P", "$Port", "-i", $SshKeyPath, "-o", "ConnectTimeout=30")

Write-Host "=== Deploy to salanga.ru ===" -ForegroundColor Cyan
Write-Host "Server: $Server (port $Port)"
Write-Host "Remote: $RemotePath"
Write-Host "Key:    $SshKeyPath"
Write-Host ""

if ($DockerOnly) {
    Write-Host "Docker-only mode (skip upload)..." -ForegroundColor Cyan
} else {
    Write-Host "[1/5] Connecting to server..." -ForegroundColor Cyan
    & ssh @sshArgs $Server "mkdir -p $RemotePath"
    if ($LASTEXITCODE -ne 0) { throw "SSH failed. Test: ssh -p $Port -i `"$SshKeyPath`" $Server" }

    $archive = Join-Path $env:TEMP "gornaya-salanga-deploy.tar.gz"
    if (-not (Get-Command tar -ErrorAction SilentlyContinue)) {
        Write-Error "tar required (Windows 10+ built-in). Or upload via WinSCP."
    }

    Write-Host "[2/5] Creating archive (~2-5 min, 400+ MB, no progress bar)..." -ForegroundColor Cyan
    Push-Location $repoRoot
    & tar -czf $archive `
        --exclude=.git `
        --exclude=node_modules `
        --exclude=mobile/.dart_tool `
        --exclude=admin/node_modules `
        --exclude=admin/dist `
        --exclude=dist `
        --exclude=backend/.env `
        --exclude=deploy/.env `
        --exclude=deploy/salanga_dev `
        .
    Pop-Location
    if ($LASTEXITCODE -ne 0) { throw "tar failed" }
    $sizeMb = [math]::Round((Get-Item $archive).Length / 1MB, 0)
    Write-Host "      Archive: $sizeMb MB"

    Write-Host "[3/5] Uploading archive (~1-2 min)..." -ForegroundColor Cyan
    & scp @scpArgs $archive "${Server}:/tmp/gornaya-salanga-deploy.tar.gz"
    if ($LASTEXITCODE -ne 0) { throw "scp failed" }
    Remove-Item $archive -Force -ErrorAction SilentlyContinue

    Write-Host "[4/5] Extracting on server..." -ForegroundColor Cyan
    & ssh @sshArgs $Server "mkdir -p $RemotePath && tar -xzf /tmp/gornaya-salanga-deploy.tar.gz -C $RemotePath && rm -f /tmp/gornaya-salanga-deploy.tar.gz"

    Write-Host "      Uploading deploy/.env ..."
    & scp @scpArgs (Join-Path $deployDir ".env") "${Server}:${RemotePath}/deploy/.env"

    $fcm = Join-Path $repoRoot "backend\secrets\fcm-service-account.json"
    if (Test-Path $fcm) {
        Write-Host "      Uploading FCM service account..."
        & ssh @sshArgs $Server "mkdir -p $RemotePath/backend/secrets"
        & scp @scpArgs $fcm "${Server}:${RemotePath}/backend/secrets/fcm-service-account.json"
    } else {
        Write-Host "      FCM credentials not found - push will not work until uploaded" -ForegroundColor Yellow
    }
}

Write-Host "[5/5] Starting Docker stack (10-20 min on first run)..." -ForegroundColor Cyan
$dockerCmd = @"
set -e
cd $RemotePath/deploy
if ! systemctl is-active docker >/dev/null 2>&1; then
  echo 'ERROR: Docker daemon is not running.'
  echo 'On the server run: sudo systemctl start docker && sudo systemctl enable docker'
  exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo 'ERROR: cannot access Docker (user dev not in group docker?).'
  echo 'On the server run: sudo usermod -aG docker dev'
  echo 'Then exit SSH, log in again, and re-run upload-salanga.ps1 -DockerOnly'
  exit 1
fi
docker compose up -d --build
docker compose ps
"@
& ssh @sshArgs $Server $dockerCmd

Write-Host ""
Write-Host "Done. Next on server (as root/sudo):" -ForegroundColor Green
Write-Host "  sudo bash $RemotePath/deploy/nginx-host/setup-host-nginx.sh"
Write-Host ""
Write-Host "Check:"
Write-Host "  http://api.salanga.ru/health"
Write-Host "  http://admin.salanga.ru/"
Write-Host "  http://admin.salanga.ru/app/"
