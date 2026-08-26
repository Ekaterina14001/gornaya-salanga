# Check SMS.ru balance, senders, and optionally send a test SMS.
# Usage:
#   powershell -ExecutionPolicy Bypass -File .\scripts\test-sms.ps1
#   powershell -ExecutionPolicy Bypass -File .\scripts\test-sms.ps1 -Phone "+79675998435"

param(
    [string]$Phone = "",
    [switch]$DryRun
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

$apiId = Read-EnvValue "SMS_RU_API_ID"
$from = Read-EnvValue "SMS_RU_FROM"
$testMode = Read-EnvValue "SMS_RU_TEST"

if (-not $apiId) {
    Write-Host "SMS_RU_API_ID not found in backend\.env" -ForegroundColor Red
    exit 1
}

Write-Host "=== SMS.ru check ===" -ForegroundColor Cyan
Write-Host "SMS_MODE: $(Read-EnvValue 'SMS_MODE')"
Write-Host "SMS_RU_FROM: $(if ($from) { $from } else { '(not set)' })"
Write-Host "SMS_RU_TEST: $testMode"
Write-Host ""

$balance = Invoke-RestMethod -Uri "https://sms.ru/my/balance?api_id=$apiId&json=1"
Write-Host "Balance: $($balance.balance) RUB (status $($balance.status_code))"

$senders = Invoke-RestMethod -Uri "https://sms.ru/my/senders?api_id=$apiId&json=1"
Write-Host "Senders:"
$senderList = @()
if ($null -ne $senders.senders) {
    if ($senders.senders -is [System.Array]) {
        $senderList = @($senders.senders)
    } else {
        $senderList = @($senders.senders.PSObject.Properties | ForEach-Object { $_.Name })
    }
}
if ($senderList.Count -gt 0) {
    foreach ($name in $senderList) {
        Write-Host "  - $name"
    }
} else {
    Write-Host "  (none - create at https://sms.ru/?panel=senders )" -ForegroundColor Yellow
}

if (-not $Phone) {
    Write-Host ""
    Write-Host "To send test SMS:"
    Write-Host "  .\scripts\test-sms.ps1 -Phone '+79XXXXXXXXX'"
    exit 0
}

if (-not $from) {
    Write-Host ""
    Write-Host "Set SMS_RU_FROM in backend\.env to an approved sender name first." -ForegroundColor Red
    exit 1
}

$digits = ($Phone -replace '\D', '')
if ($digits.Length -eq 11 -and $digits[0] -eq '8') { $digits = '7' + $digits.Substring(1) }
if ($digits.Length -eq 10 -and $digits[0] -eq '9') { $digits = '7' + $digits }

$body = @{
    api_id = $apiId
    to     = $digits
    msg    = "Test Gornaya Salanga: SMS.ru OK"
    from   = $from
    json   = 1
}
if ($testMode -eq 'true') {
    $body.test = 1
    Write-Host "Sending in TEST mode (no charge)..." -ForegroundColor Yellow
} elseif ($DryRun) {
    Write-Host "Dry run - not sending." -ForegroundColor Yellow
    exit 0
} else {
    Write-Host "Sending REAL SMS to $Phone ..." -ForegroundColor Green
}

$result = Invoke-RestMethod -Uri "https://sms.ru/sms/send" -Method Post -Body $body
$result | ConvertTo-Json -Depth 5
