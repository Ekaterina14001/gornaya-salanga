# Fix WSL for Docker Desktop on Windows.
# Run PowerShell AS ADMINISTRATOR: right-click -> "Run as administrator"
#
# Usage: .\setup-wsl.ps1

$ErrorActionPreference = "Continue"

Write-Host "=== WSL setup for Docker Desktop ===" -ForegroundColor Cyan
Write-Host ""

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "WARNING: Run this script as Administrator for best results." -ForegroundColor Yellow
    Write-Host "Right-click PowerShell -> Run as administrator" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "[1/4] Enabling Windows features (WSL + Virtual Machine Platform)..."
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null

Write-Host "[2/4] Updating WSL..."
wsl --update
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "wsl --update failed. Download kernel manually:" -ForegroundColor Yellow
    Write-Host "  https://aka.ms/wsl2kernel" -ForegroundColor Yellow
    Write-Host "Install the MSI, then run this script again." -ForegroundColor Yellow
}

Write-Host "[3/4] Setting WSL 2 as default..."
wsl --set-default-version 2 2>$null

Write-Host "[4/4] WSL status:"
wsl --status 2>&1
Write-Host ""

Write-Host "=== Next steps ===" -ForegroundColor Cyan
Write-Host "1. RESTART your computer (required after enabling WSL features)"
Write-Host "2. Open Docker Desktop and wait for 'Engine running'"
Write-Host "3. Run: .\start-infra.ps1"
Write-Host "4. Restart backend: cd backend; go run ./cmd/api"
Write-Host ""
Write-Host "If Docker still fails, use Redis without Docker:"
Write-Host "  .\start-redis-local.ps1"
