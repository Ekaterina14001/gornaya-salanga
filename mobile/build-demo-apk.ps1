# Build demo APK for Android (Wi-Fi or public tunnel URL baked in at compile time).
# Usage:
#   .\build-demo-apk.ps1
#   .\build-demo-apk.ps1 -ApiUrl "http://192.168.1.10:8080"

param(
    [string]$ApiUrl = ""
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$exitCode = 0

try {
    . (Join-Path (Split-Path $PSScriptRoot -Parent) "scripts\Get-DemoLanIp.ps1")

    function Get-LanIPv4 {
        $result = Get-DemoLanIp
        if ($result) { return $result.IP }
        return $null
    }

    if ([string]::IsNullOrWhiteSpace($ApiUrl)) {
        $lanIp = Get-LanIPv4
        if (-not $lanIp) {
            Write-Host "LAN IP not found."
            $typed = Read-Host "Enter PC IP (numbers only, e.g. 192.168.0.107)"
            if ([string]::IsNullOrWhiteSpace($typed)) { throw "IP not entered" }
            $lanIp = $typed.Trim()
        }
        $ApiUrl = "http://${lanIp}:8080"
    }

    $ApiUrl = $ApiUrl.TrimEnd('/')

    Write-Host "=== Demo APK build ===" -ForegroundColor Cyan
    Write-Host "API URL: $ApiUrl"
    Write-Host ""
    $confirm = Read-Host "Use this URL? Press Enter = yes, or type another IP"
    if (-not [string]::IsNullOrWhiteSpace($confirm)) {
        $confirm = $confirm.Trim() -replace '^https?://', '' -replace ':8080.*$', ''
        $ApiUrl = "http://${confirm}:8080"
        Write-Host "Updated API URL: $ApiUrl"
    }
    Write-Host ""
    Write-Host "Before installing APK, ensure on this PC:"
    Write-Host "  1. .\start-infra.ps1   (from repo root)"
    Write-Host "  2. cd backend; go run ./cmd/api"
    Write-Host "  3. Phone and PC on the same Wi-Fi (for LAN URL)"
    Write-Host "  4. Windows Firewall allows inbound TCP 8080 (private network)"
    Write-Host ""

    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $flutter) {
        throw "flutter not found in PATH. Install Flutter SDK first."
    }

    if (-not $env:ANDROID_HOME) {
        $sdkCandidates = @(
            "$env:LOCALAPPDATA\Android\Sdk",
            "$env:USERPROFILE\AppData\Local\Android\Sdk"
        )
        foreach ($sdk in $sdkCandidates) {
            if (Test-Path $sdk) {
                $env:ANDROID_HOME = $sdk
                $env:PATH = "$sdk\platform-tools;$sdk\cmdline-tools\latest\bin;$env:PATH"
                Write-Host "ANDROID_HOME=$sdk"
                break
            }
        }
    }

    if (-not $env:ANDROID_HOME -or -not (Test-Path $env:ANDROID_HOME)) {
        throw @"
Android SDK not found. Install Android Studio and Android SDK.
https://developer.android.com/studio
Then run: flutter doctor
"@
    }

    $gradleZip = Join-Path $env:USERPROFILE ".gradle\wrapper\dists\gradle-9.1.0-all"
    $gradleReady = $false
    if (Test-Path $gradleZip) {
        $zips = Get-ChildItem $gradleZip -Recurse -Filter "gradle-9.1.0-all.zip" -ErrorAction SilentlyContinue
        foreach ($z in $zips) {
            if ($z.Length -gt 100000000) { $gradleReady = $true; break }
        }
    }
    if (-not $gradleReady) {
        Write-Host "Gradle not cached yet. Run setup first:" -ForegroundColor Yellow
        Write-Host "  .\setup-gradle.ps1"
        Write-Host ""
        $runSetup = Read-Host "Run setup-gradle.ps1 now? (Y/n)"
        if ($runSetup -ne 'n' -and $runSetup -ne 'N') {
            & (Join-Path $PSScriptRoot "setup-gradle.ps1")
        }
    }

    Write-Host "Running flutter pub get..."
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed (exit $LASTEXITCODE)" }

    Write-Host "Building release APK (may take several minutes)..."
    flutter build apk --release "--dart-define=API_BASE_URL=$ApiUrl"
    if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed (exit $LASTEXITCODE)" }

    $apkSource = Join-Path $PSScriptRoot "build\app\outputs\flutter-apk\app-release.apk"
    if (-not (Test-Path $apkSource)) {
        throw "APK not found at $apkSource"
    }

    $distDir = Join-Path (Split-Path $PSScriptRoot -Parent) "dist"
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null

    $stamp = Get-Date -Format "yyyyMMdd-HHmm"
    $apkName = "gornaya-salanga-demo-$stamp.apk"
    $apkDest = Join-Path $distDir $apkName
    Copy-Item $apkSource $apkDest -Force

    $readme = @"
Demo APK: Gornaya Salanga (Android)
===================================

API: $ApiUrl

Install
-------
1. Copy APK to phone (USB, Telegram, email).
2. Allow install from unknown sources.
3. Open file and install.

Demo login
----------
Guest: guest@gornayasalanga.ru / guest123
Registration SMS code: 123456

Notes
-----
- Phone and PC must be on the same Wi-Fi.
- Test build, not from Google Play.
"@

    $readmePath = Join-Path $distDir "DEMO-APK-README.txt"
    Set-Content -Path $readmePath -Value $readme -Encoding UTF8

    Write-Host ""
    Write-Host "SUCCESS" -ForegroundColor Green
    Write-Host "APK:      $apkDest"
    Write-Host "Readme:   $readmePath"
    Write-Host ""
    Write-Host "Open folder:"
    Write-Host "  explorer `"$distDir`""
    Write-Host ""
    Write-Host "Install on phone (USB):"
    Write-Host "  adb install -r `"$apkDest`""
    Write-Host ""
    Write-Host "Test API from phone:"
    Write-Host "  $ApiUrl/health"
}
catch {
    $exitCode = 1
    Write-Host ""
    Write-Host "FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
finally {
    Write-Host ""
    Read-Host "Press Enter to close"
    exit $exitCode
}
