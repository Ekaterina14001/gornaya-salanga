# Build Flutter web for iPhone/Safari and desktop browsers.
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\build-web.ps1
#   powershell -ExecutionPolicy Bypass -File .\build-web.ps1 -ApiUrl "https://admin.salanga.ru"

param(
    [string]$ApiUrl = "https://admin.salanga.ru",
    [string]$VapidKey = $env:FIREBASE_VAPID_KEY
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$exitCode = 0

try {
    $ApiUrl = $ApiUrl.TrimEnd('/')

    Write-Host "=== Flutter Web build ===" -ForegroundColor Cyan
    Write-Host "API URL: $ApiUrl"
    Write-Host "App URL: ${ApiUrl}/app/"
    Write-Host ""

    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $flutter) { throw "flutter not found in PATH" }

    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" }

    Write-Host "Building web (may take several minutes)..."
    $dartDefines = @("--dart-define=API_BASE_URL=$ApiUrl")
    if ($VapidKey) {
        $dartDefines += "--dart-define=FIREBASE_VAPID_KEY=$VapidKey"
        Write-Host "Web push VAPID: configured"
    } else {
        Write-Host "Web push VAPID: NOT SET - push in browser will not work" -ForegroundColor Yellow
    }
    flutter build web --release --base-href /app/ --pwa-strategy=none @dartDefines
    if ($LASTEXITCODE -ne 0) { throw "flutter build web failed" }

    $webDir = Join-Path $PSScriptRoot "build\web"
    if (-not (Test-Path (Join-Path $webDir "index.html"))) {
        throw "build/web not found"
    }

    Write-Host ""
    Write-Host "SUCCESS" -ForegroundColor Green
    Write-Host "Local test: flutter run -d chrome --dart-define=API_BASE_URL=$ApiUrl"
    Write-Host ""
    Write-Host "Deploy:"
    Write-Host '  cd ..\deploy'
    Write-Host '  .\upload-salanga.ps1'
    Write-Host ""
    Write-Host "Open on iPhone (Wi-Fi): ${ApiUrl}/app/"
    Write-Host "Guest login: guest@gornayasalanga.ru / guest123"
}
catch {
    $exitCode = 1
    Write-Host ""
    Write-Host "FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    if ($Host.Name -eq 'ConsoleHost') {
        Write-Host ""
        Read-Host "Press Enter to close"
    }
    exit $exitCode
}
