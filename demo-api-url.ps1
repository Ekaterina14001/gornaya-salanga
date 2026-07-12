# Print LAN URL for demo APK + quick backend health check.
# Usage: .\demo-api-url.ps1

$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

. (Join-Path $PSScriptRoot "scripts\Get-DemoLanIp.ps1")

$selected = Get-DemoLanIp
$all = Get-DemoLanIpCandidates

Write-Host "=== Network addresses on this PC ===" -ForegroundColor Cyan
foreach ($item in $all) {
    $mark = if ($selected -and $item.IP -eq $selected.IP) { " <-- use this (Wi-Fi/LAN)" } else { "" }
    $virt = if ($item.Tag -eq 'virtual') { " [virtual, not for phone]" } else { "" }
    Write-Host "  $($item.IP)  ($($item.Adapter))$virt$mark"
}
Write-Host ""

if (-not $selected) {
    Write-Host "LAN IP not found. Connect Wi-Fi or pass IP manually to build-demo-apk.ps1"
    Read-Host "Press Enter to close"
    exit 1
}

$ip = $selected.IP
$url = "http://${ip}:8080"
Write-Host "Demo API URL for APK: $url" -ForegroundColor Green
Write-Host "Adapter: $($selected.Adapter)"
Write-Host ""
Write-Host "On phone (same Wi-Fi), open in Chrome:" -ForegroundColor Cyan
Write-Host "  $url/health"
Write-Host ""

try {
    $r = Invoke-WebRequest -Uri "$url/health" -UseBasicParsing -TimeoutSec 3
    Write-Host "Backend health (from PC): $($r.Content)" -ForegroundColor Green
} catch {
    Write-Host "Backend not reachable at $url from this PC" -ForegroundColor Yellow
    Write-Host "Start: .\start-infra.ps1  then  cd backend; go run ./cmd/api"
}

Write-Host ""
if ($selected.IP -like '192.168.56.*') {
    Write-Host "WARNING: 192.168.56.x is usually VirtualBox, not Wi-Fi." -ForegroundColor Yellow
    Write-Host "If phone cannot connect, pick 192.168.1.x from the list above."
    Write-Host ""
}

Write-Host "If phone still cannot open /health:" -ForegroundColor Cyan
Write-Host "  1. Phone and PC must be on the same Wi-Fi"
Write-Host "  2. Windows Firewall: allow inbound TCP 8080 (private network)"
Write-Host "     New-NetFirewallRule -DisplayName 'Gornaya Salanga API' -Direction Inbound -LocalPort 8080 -Protocol TCP -Action Allow"
Write-Host ""
Write-Host "Build APK:"
Write-Host "  cd mobile"
Write-Host "  .\build-demo-apk.ps1 -ApiUrl `"$url`""
Read-Host "Press Enter to close"
