# Download Gradle for Flutter Android build (fixes network errors during first build).
# Usage: .\setup-gradle.ps1

$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

$gradleVersion = "9.1.0"
$gradleUrl = "https://services.gradle.org/distributions/gradle-${gradleVersion}-all.zip"
$zipName = "gradle-${gradleVersion}-all.zip"

# Folder created by Gradle wrapper on first run
$distRoot = Join-Path $env:USERPROFILE ".gradle\wrapper\dists\gradle-${gradleVersion}-all"
$hashDir = Get-ChildItem $distRoot -Directory -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $hashDir) {
    Write-Host "Creating Gradle wrapper cache entry..."
    New-Item -ItemType Directory -Force -Path (Join-Path $distRoot "bootstrap") | Out-Null
    Push-Location (Join-Path $PSScriptRoot "android")
    cmd /c "gradlew.bat --version" 2>$null
    Pop-Location
    $hashDir = Get-ChildItem $distRoot -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "bootstrap" } | Select-Object -First 1
}

if (-not $hashDir) {
    Write-Host "Could not determine Gradle cache folder. Open mobile\android in Android Studio once." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit 1
}

$targetDir = $hashDir.FullName
$targetZip = Join-Path $targetDir $zipName

Write-Host "Gradle cache: $targetDir"
Write-Host ""

# Remove failed partial download
Get-ChildItem $targetDir -Filter "*.lck" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem $targetDir -Filter "*.part" -ErrorAction SilentlyContinue | Remove-Item -Force

if (Test-Path $targetZip) {
    $size = (Get-Item $targetZip).Length
    if ($size -gt 100000000) {
        Write-Host "Gradle already downloaded ($([math]::Round($size/1MB)) MB)" -ForegroundColor Green
        Read-Host "Press Enter to close"
        exit 0
    }
    Remove-Item $targetZip -Force
}

Write-Host "Downloading $zipName (~200 MB). This may take several minutes..."
Write-Host "URL: $gradleUrl"
Write-Host ""

$downloaded = $false
for ($i = 1; $i -le 3; $i++) {
    Write-Host "Attempt $i/3..."
    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
            curl.exe -L --retry 3 --retry-delay 5 -o $targetZip $gradleUrl
            if ($LASTEXITCODE -eq 0 -and (Test-Path $targetZip) -and (Get-Item $targetZip).Length -gt 100000000) {
                $downloaded = $true
                break
            }
        }
        Invoke-WebRequest -Uri $gradleUrl -OutFile $targetZip -UseBasicParsing -TimeoutSec 600
        if ((Get-Item $targetZip).Length -gt 100000000) {
            $downloaded = $true
            break
        }
    } catch {
        Write-Host "  Failed: $($_.Exception.Message)" -ForegroundColor Yellow
        if (Test-Path $targetZip) { Remove-Item $targetZip -Force }
        Start-Sleep -Seconds 3
    }
}

if ($downloaded) {
    Write-Host ""
    Write-Host "SUCCESS: Gradle saved to $targetZip" -ForegroundColor Green
    Write-Host "Now run: .\build-demo-apk.ps1"
} else {
    Write-Host ""
    Write-Host "Auto-download failed (network/firewall)." -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual download:" -ForegroundColor Cyan
    Write-Host "  1. Open in browser:"
    Write-Host "     $gradleUrl"
    Write-Host "  2. Save file as:"
    Write-Host "     $targetZip"
    Write-Host "  3. File size should be about 200 MB (not 0 KB)"
    Write-Host "  4. Run .\build-demo-apk.ps1 again"
    Write-Host ""
    Write-Host "Alternative: Android Studio -> Open folder mobile\android -> wait for Gradle sync"
}

Write-Host ""
Read-Host "Press Enter to close"
