# Send test email using backend/.env SMTP settings.
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\scripts\test-email.ps1 -To "you@mail.ru"

param(
    [Parameter(Mandatory = $true)]
    [string]$To
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $repoRoot "backend\.env"

function Read-EnvValue([string]$key) {
    if (-not (Test-Path $envFile)) { return "" }
    foreach ($line in Get-Content $envFile) {
        if ($line -match "^\s*$key=(.*)$") {
            return $matches[1].Trim().Trim('"').Trim("'")
        }
    }
    return ""
}

$mode = Read-EnvValue "EMAIL_MODE"
if ($mode -ne "smtp") {
    Write-Host "Set EMAIL_MODE=smtp and SMTP_* in backend\.env first." -ForegroundColor Yellow
    Write-Host "Or use EMAIL_MODE=log and check backend log on forgot-password."
    exit 1
}

$hostName = Read-EnvValue "SMTP_HOST"
$port = Read-EnvValue "SMTP_PORT"
if (-not $port) { $port = "465" }
$user = Read-EnvValue "SMTP_USER"
$pass = Read-EnvValue "SMTP_PASSWORD"
$from = Read-EnvValue "SMTP_FROM"
if (-not $from) { $from = $user }

if (-not $hostName -or -not $user -or -not $pass) {
    Write-Host "Missing SMTP_HOST, SMTP_USER or SMTP_PASSWORD in backend\.env" -ForegroundColor Red
    exit 1
}

Write-Host "Sending test email to $To via ${hostName}:${port} ..." -ForegroundColor Cyan

$body = @{
    email = $To
} | ConvertTo-Json

# Trigger forgot-password for guest if exists, or any registered email
try {
    $null = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/forgot-password" -Method Post -Body $body -ContentType "application/json"
    Write-Host "OK: forgot-password requested. Check inbox for $To" -ForegroundColor Green
    Write-Host "Use token from email on Reset Password screen in the app."
}
catch {
    Write-Host "API error (is backend running on :8080?): $_" -ForegroundColor Red
    exit 1
}
