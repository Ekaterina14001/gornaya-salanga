# Run Flutter Web locally against local backend (localhost:8080).
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\run-web-local.ps1
#   powershell -ExecutionPolicy Bypass -File .\run-web-local.ps1 -VapidKey "B..."
#
# VAPID key: Firebase Console → Project settings → Cloud Messaging → Web Push certificates.

param(
    [string]$ApiUrl = "http://localhost:8080",
    [string]$VapidKey = $env:FIREBASE_VAPID_KEY
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$apiUrl = $ApiUrl.TrimEnd('/')

Write-Host "=== Flutter Web (local) ===" -ForegroundColor Cyan
Write-Host "API: $apiUrl"
if ($VapidKey) {
    Write-Host "Web push VAPID: configured" -ForegroundColor Green
} else {
    Write-Host "Web push VAPID: NOT SET (push in Chrome will not work)" -ForegroundColor Yellow
    Write-Host "  Set env FIREBASE_VAPID_KEY or pass -VapidKey"
}
Write-Host ""

try {
    $health = Invoke-WebRequest -Uri "$apiUrl/health" -UseBasicParsing -TimeoutSec 3
    Write-Host "Backend OK" -ForegroundColor Green
}
catch {
    Write-Host "Backend is not running on port 8080." -ForegroundColor Red
    Write-Host ""
    Write-Host "Start in another terminal:"
    Write-Host "  cd .."
    Write-Host "  .\start-infra.ps1"
    Write-Host "  cd backend"
    Write-Host "  go run ./cmd/api"
    Write-Host ""
    Write-Host "Guest login: guest@gornayasalanga.ru / guest123"
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Guest login: guest@gornayasalanga.ru / guest123"
Write-Host ""

$dartDefines = @("--dart-define=API_BASE_URL=$apiUrl")
if ($VapidKey) {
    $dartDefines += "--dart-define=FIREBASE_VAPID_KEY=$VapidKey"
}

flutter run -d chrome @dartDefines
