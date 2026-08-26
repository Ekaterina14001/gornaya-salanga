# Generate random secrets for production .env
# Usage: powershell -ExecutionPolicy Bypass -File .\scripts\generate-secrets.ps1

function New-RandomHex([int]$bytes = 32) {
    $buf = New-Object byte[] $bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buf)
    return ([BitConverter]::ToString($buf) -replace '-', '').ToLower()
}

$jwt = New-RandomHex 32
$refresh = New-RandomHex 32
$shelter = New-RandomHex 24
$bars = New-RandomHex 24
$rkeeper = New-RandomHex 24
$postgres = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })

Write-Host "=== Production secrets (copy to deploy/.env) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "JWT_SECRET=$jwt"
Write-Host "JWT_REFRESH_SECRET=$refresh"
Write-Host "POSTGRES_PASSWORD=$postgres"
Write-Host "DATABASE_URL=postgres://salanga:${postgres}@postgres:5432/gornaya_salanga?sslmode=disable"
Write-Host "POS_API_KEY_SHELTER=$shelter"
Write-Host "POS_API_KEY_BARS=$bars"
Write-Host "POS_API_KEY_RKEEPER=$rkeeper"
Write-Host ""
Write-Host "Also set in production:" -ForegroundColor Yellow
Write-Host "  GIN_MODE=release"
Write-Host "  REDIS_REQUIRED=true"
Write-Host "  SMS_MODE=smsru"
Write-Host "  EMAIL_MODE=smtp"
