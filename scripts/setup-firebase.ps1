# Copy Firebase config from Desktop folder into the monorepo.
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\setup-firebase.ps1

param(
    [string]$SourceDir = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent

function Find-FirstFile([string]$name) {
    if ($SourceDir -and (Test-Path $SourceDir)) {
        $hit = Get-ChildItem -Path $SourceDir -Recurse -Filter $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    $desktop = Join-Path $env:USERPROFILE "Desktop"
    if (Test-Path $desktop) {
        $hit = Get-ChildItem -Path $desktop -Recurse -Filter $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

$serviceAccountSrc = Find-FirstFile "gornaya-slanga-firebase-adminsdk-fbsvc-b63e842c41.json"
$googleServicesSrc = Find-FirstFile "google-services.json"

if (-not $serviceAccountSrc) {
    Write-Error "Service account JSON not found. Pass -SourceDir or place file on Desktop."
}
if (-not $googleServicesSrc) {
    Write-Error "google-services.json not found."
}

$secretsDir = Join-Path $repoRoot "backend\secrets"
New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null

Copy-Item $serviceAccountSrc (Join-Path $secretsDir "fcm-service-account.json") -Force
Copy-Item $googleServicesSrc (Join-Path $repoRoot "mobile\android\app\google-services.json") -Force

Write-Host "Copied Firebase files:" -ForegroundColor Green
Write-Host "  backend\secrets\fcm-service-account.json"
Write-Host "  mobile\android\app\google-services.json"
Write-Host ""
Write-Host "backend\.env should contain:"
Write-Host "  FCM_CREDENTIALS_FILE=secrets/fcm-service-account.json"
Write-Host ""
Write-Host "Project: gornaya-slanga (package com.gornayaslanga.mobile)"
Write-Host ""
Write-Host "Web push: copy VAPID key from Firebase Console -> Cloud Messaging -> Web Push certificates"
Write-Host "  `$env:FIREBASE_VAPID_KEY = 'YOUR_KEY'"
Write-Host "  cd mobile; .\build-web.ps1 -ApiUrl https://admin.salanga.ru"
Write-Host ""
Write-Host "Test push:"
Write-Host "  1. .\start-infra.ps1 && cd backend && go run ./cmd/api"
Write-Host "  2. cd mobile && flutter run   (Android device/emulator)"
Write-Host "  3. Login as guest, allow notifications"
Write-Host "  4. Admin -> Notifications -> broadcast"
