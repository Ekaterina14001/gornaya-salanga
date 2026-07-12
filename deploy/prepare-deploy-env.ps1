# Create deploy/.env from template with generated secrets.
# Usage: .\prepare-deploy-env.ps1
#        .\prepare-deploy-env.ps1 -PublicHost 203.0.113.10

param(
    [string]$PublicHost = ""
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($PublicHost)) {
    $PublicHost = Read-Host "VPS public IP (e.g. 203.0.113.10)"
}
$PublicHost = $PublicHost.Trim()

function New-RandomHex([int]$bytes = 32) {
    $buf = New-Object byte[] $bytes
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buf)
    return ([BitConverter]::ToString($buf) -replace '-', '').ToLower()
}

$pgPass = New-RandomHex 16
$jwt1 = New-RandomHex 32
$jwt2 = New-RandomHex 32

$apiUrl = "http://${PublicHost}"
$adminUrl = "http://${PublicHost}"

$example = Join-Path $PSScriptRoot ".env.example"
$target = Join-Path $PSScriptRoot ".env"

if (-not (Test-Path $example)) {
    Write-Error ".env.example not found"
}

$content = Get-Content $example -Raw
$content = $content -replace 'PUBLIC_HOST=.*', "PUBLIC_HOST=$PublicHost"
$content = $content -replace 'PUBLIC_API_URL=.*', "PUBLIC_API_URL=$apiUrl"
$content = $content -replace 'POSTGRES_PASSWORD=.*', "POSTGRES_PASSWORD=$pgPass"
$content = $content -replace 'DATABASE_URL=postgres://salanga:[^@]+@', "DATABASE_URL=postgres://salanga:${pgPass}@"
$content = $content -replace 'JWT_SECRET=.*', "JWT_SECRET=$jwt1"
$content = $content -replace 'JWT_REFRESH_SECRET=.*', "JWT_REFRESH_SECRET=$jwt2"
$content = $content -replace 'CORS_ORIGINS=.*', "CORS_ORIGINS=$adminUrl,$apiUrl"
$content = $content -replace 'ADMIN_ORIGIN=.*', "ADMIN_ORIGIN=$adminUrl"
$content = $content -replace '203\.0\.113\.10', $PublicHost

Set-Content -Path $target -Value $content -Encoding UTF8

Write-Host "Created: $target" -ForegroundColor Green
Write-Host "PUBLIC_API_URL=$apiUrl"
Write-Host "Admin:       $adminUrl"
Write-Host ""
Write-Host "Upload deploy/.env to VPS, then on server:"
Write-Host "  cd deploy && docker compose up -d --build"
Write-Host ""
Write-Host "Then build APK:"
Write-Host "  cd ..\mobile"
Write-Host "  .\build-demo-apk.ps1 -ApiUrl `"$apiUrl`""
if ($Host.Name -eq 'ConsoleHost') {
    Read-Host "Press Enter to close"
}
