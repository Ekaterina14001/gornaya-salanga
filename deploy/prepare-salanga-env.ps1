# Create deploy/.env for salanga.ru production.
# Usage:
#   .\prepare-salanga-env.ps1
#   .\prepare-salanga-env.ps1 -UseHttps   # after Let's Encrypt

param(
    [switch]$UseHttps
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function New-RandomHex([int]$bytes = 32) {
    $buf = New-Object byte[] $bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buf)
    return ([BitConverter]::ToString($buf) -replace '-', '').ToLower()
}

$scheme = if ($UseHttps) { "https" } else { "http" }
$apiUrl = "${scheme}://api.salanga.ru"
$adminUrl = "${scheme}://admin.salanga.ru"

$pgPass = New-RandomHex 16
$jwt1 = New-RandomHex 32
$jwt2 = New-RandomHex 32
$pos1 = New-RandomHex 24
$pos2 = New-RandomHex 24
$pos3 = New-RandomHex 24

$example = Join-Path $PSScriptRoot ".env.example"
$target = Join-Path $PSScriptRoot ".env"

$content = Get-Content $example -Raw
$content = $content -replace 'PUBLIC_HOST=.*', 'PUBLIC_HOST=admin.salanga.ru'
$content = $content -replace 'PUBLIC_API_URL=.*', "PUBLIC_API_URL=$apiUrl"
$content = $content -replace 'API_BIND_HOST=0\.0\.0\.0', 'API_BIND_HOST=127.0.0.1'
$content = $content -replace 'API_PUBLISH_PORT=8080', 'API_PUBLISH_PORT=8080'
$content = $content -replace 'ADMIN_BIND_HOST=0\.0\.0\.0', 'ADMIN_BIND_HOST=127.0.0.1'
$content = $content -replace 'ADMIN_PUBLISH_PORT=80', 'ADMIN_PUBLISH_PORT=8081'
$content = $content -replace 'POSTGRES_PASSWORD=.*', "POSTGRES_PASSWORD=$pgPass"
$content = $content -replace 'DATABASE_URL=postgres://salanga:[^@]+@', "DATABASE_URL=postgres://salanga:${pgPass}@"
$content = $content -replace 'JWT_SECRET=.*', "JWT_SECRET=$jwt1"
$content = $content -replace 'JWT_REFRESH_SECRET=.*', "JWT_REFRESH_SECRET=$jwt2"
$content = $content -replace 'CORS_ORIGINS=.*', "CORS_ORIGINS=$adminUrl,$apiUrl,http://admin.salanga.ru,http://api.salanga.ru,https://admin.salanga.ru,https://api.salanga.ru"
$content = $content -replace 'ADMIN_ORIGIN=.*', "ADMIN_ORIGIN=$adminUrl"
$content = $content -replace 'APP_PUBLIC_URL=.*', "APP_PUBLIC_URL=$adminUrl"
$content = $content -replace 'SMS_MODE=log', 'SMS_MODE=smsru'
$content = $content -replace 'EMAIL_MODE=log', 'EMAIL_MODE=smtp'
$content = $content -replace 'SMTP_HOST=.*', 'SMTP_HOST=smtp.yandex.com'
$content = $content -replace 'SMTP_USER=.*', 'SMTP_USER=noreply@salanga.ru'
$content = $content -replace 'SMTP_FROM=.*', 'SMTP_FROM=noreply@salanga.ru'
$content = $content -replace 'POS_API_KEY_SHELTER=.*', "POS_API_KEY_SHELTER=$pos1"
$content = $content -replace 'POS_API_KEY_BARS=.*', "POS_API_KEY_BARS=$pos2"
$content = $content -replace 'POS_API_KEY_RKEEPER=.*', "POS_API_KEY_RKEEPER=$pos3"

if ($content -notmatch 'SMS_RU_API_ID=') {
    $content += "`nSMS_RU_API_ID=`n"
}

Write-Host ""
Write-Host "Set manually in deploy/.env (secrets from client):" -ForegroundColor Yellow
Write-Host "  SMS_RU_API_ID=..."
Write-Host "  SMS_RU_FROM=...   (after SMS.ru approves sender name)"
Write-Host "  SMTP_PASSWORD=... (Yandex app password for noreply@salanga.ru)"
Write-Host ""

Set-Content -Path $target -Value $content -Encoding UTF8

Write-Host "Created: $target" -ForegroundColor Green
Write-Host "PUBLIC_API_URL=$apiUrl"
Write-Host "Admin:       $adminUrl"
Write-Host ""
Write-Host "Build mobile web before deploy:"
Write-Host "  cd ..\mobile"
Write-Host "  .\build-web.ps1 -ApiUrl `"$apiUrl`""
