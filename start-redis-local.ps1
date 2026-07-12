# Start Redis on Windows without Docker (for dev while WSL/Docker is broken).
# Usage: .\start-redis-local.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Test-RedisPort {
    $t = Test-NetConnection -ComputerName 127.0.0.1 -Port 6379 -WarningAction SilentlyContinue
    return $t.TcpTestSucceeded
}

if (Test-RedisPort) {
    Write-Host "Redis already listening on 127.0.0.1:6379"
    Write-Host "Set in backend\.env: REDIS_URL=redis://127.0.0.1:6379/0"
    exit 0
}

# Try Docker single container (if engine is up)
$docker = Get-Command docker -ErrorAction SilentlyContinue
if ($docker) {
    docker info *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Starting Redis via Docker..."
        docker run -d --name gornaya-salanga-redis -p 6379:6379 redis:7-alpine 2>$null
        if ($LASTEXITCODE -ne 0) {
            docker start gornaya-salanga-redis 2>$null
        }
        Start-Sleep -Seconds 3
        if (Test-RedisPort) {
            Write-Host "Redis started via Docker on 127.0.0.1:6379"
            exit 0
        }
    }
}

# Try Memurai (Redis-compatible for Windows)
$memurai = @(
    "${env:ProgramFiles}\Memurai\memurai.exe",
    "${env:ProgramFiles}\Memurai\memurai-server.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($memurai) {
    Write-Host "Starting Memurai: $memurai"
    Start-Process -FilePath $memurai -WindowStyle Hidden
    Start-Sleep -Seconds 2
    if (Test-RedisPort) {
        Write-Host "Memurai started on 127.0.0.1:6379"
        exit 0
    }
}

# Try redis-server in PATH (e.g. from Chocolatey)
$redisServer = Get-Command redis-server -ErrorAction SilentlyContinue
if ($redisServer) {
    Write-Host "Starting redis-server..."
    Start-Process -FilePath $redisServer.Source -ArgumentList "--port 6379" -WindowStyle Hidden
    Start-Sleep -Seconds 2
    if (Test-RedisPort) {
        Write-Host "redis-server started on 127.0.0.1:6379"
        exit 0
    }
}

Write-Host ""
Write-Host "Redis is not installed and Docker is not running." -ForegroundColor Yellow
Write-Host ""
Write-Host "Option A — fix Docker (recommended long-term):" -ForegroundColor Cyan
Write-Host "  1. Run as Administrator: .\setup-wsl.ps1"
Write-Host "  2. Restart PC"
Write-Host "  3. Open Docker Desktop -> Engine running"
Write-Host "  4. .\start-infra.ps1"
Write-Host ""
Write-Host "Option B — Redis without Docker (quick dev fix):" -ForegroundColor Cyan
Write-Host "  Install Memurai Developer (free, Redis-compatible):"
Write-Host "    winget install Memurai.MemuraiDeveloper"
Write-Host "  Then run this script again: .\start-redis-local.ps1"
Write-Host ""
Write-Host "Option C — continue without Redis (limited):" -ForegroundColor Cyan
Write-Host "  Backend works, but OTP codes reset on restart and refresh tokens don't persist."
Write-Host "  Dev SMS code still works: 123456"
Write-Host ""
Write-Host "backend\.env should contain:"
Write-Host "  REDIS_URL=redis://127.0.0.1:6379/0"
exit 1
