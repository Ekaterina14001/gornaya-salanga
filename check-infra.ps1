# Quick check: are Postgres and Redis reachable?
# Usage: .\check-infra.ps1

$ErrorActionPreference = "Continue"
Set-Location $PSScriptRoot

Write-Host "=== Infrastructure check ===" -ForegroundColor Cyan
Write-Host ""

docker compose ps 2>$null
Write-Host ""

$pg = Test-NetConnection -ComputerName 127.0.0.1 -Port 5432 -WarningAction SilentlyContinue
$rd = Test-NetConnection -ComputerName 127.0.0.1 -Port 6379 -WarningAction SilentlyContinue

if ($pg.TcpTestSucceeded) { Write-Host "PostgreSQL 127.0.0.1:5432  OK" -ForegroundColor Green }
else { Write-Host "PostgreSQL 127.0.0.1:5432  FAIL" -ForegroundColor Red }

if ($rd.TcpTestSucceeded) {
    $pong = docker exec gornaya-salanga-redis redis-cli ping 2>$null
    Write-Host "Redis      127.0.0.1:6379  OK ($pong)" -ForegroundColor Green
} else {
    Write-Host "Redis      127.0.0.1:6379  FAIL" -ForegroundColor Red
    Write-Host "Run: .\start-infra.ps1"
}

Write-Host ""
if (-not $rd.TcpTestSucceeded) { exit 1 }
