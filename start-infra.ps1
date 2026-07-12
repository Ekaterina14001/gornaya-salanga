# Start PostgreSQL + Redis for local development.
# Usage: .\start-infra.ps1

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$docker = Get-Command docker -ErrorAction SilentlyContinue
if (-not $docker) {
    Write-Error @"
Docker not found.

Install Docker Desktop: https://www.docker.com/products/docker-desktop/
Or run Redis/PostgreSQL locally and set REDIS_URL / DATABASE_URL in backend\.env
"@
}

Write-Host "Checking Docker daemon..."
docker info *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Docker Desktop is not running (often because WSL needs update)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Fix WSL + Docker:" -ForegroundColor Cyan
    Write-Host "  1. PowerShell as Administrator: .\setup-wsl.ps1"
    Write-Host "  2. Restart PC"
    Write-Host "  3. Open Docker Desktop, wait for 'Engine running'"
    Write-Host "  4. Run this script again"
    Write-Host ""
    Write-Host "Quick workaround without Docker:" -ForegroundColor Cyan
    Write-Host "  winget install Memurai.MemuraiDeveloper"
    Write-Host "  .\start-redis-local.ps1"
    Write-Host ""
    exit 1
}

Write-Host "Starting PostgreSQL and Redis..."
docker compose up -d postgres redis
if ($LASTEXITCODE -ne 0) {
    Write-Error "docker compose failed. Is Docker Desktop fully started?"
}

Write-Host ""
Write-Host "Waiting for services..."
$deadline = (Get-Date).AddSeconds(45)
while ((Get-Date) -lt $deadline) {
    $pg = docker inspect --format='{{.State.Health.Status}}' gornaya-salanga-postgres 2>$null
    $rd = docker inspect --format='{{.State.Health.Status}}' gornaya-salanga-redis 2>$null
    if ($pg -eq "healthy" -and $rd -eq "healthy") {
        $redisOk = Test-NetConnection -ComputerName 127.0.0.1 -Port 6379 -WarningAction SilentlyContinue
        $pgOk = Test-NetConnection -ComputerName 127.0.0.1 -Port 5432 -WarningAction SilentlyContinue
        Write-Host ""
        docker compose ps
        Write-Host ""
        if ($pgOk.TcpTestSucceeded) {
            Write-Host "PostgreSQL: port 5432 reachable" -ForegroundColor Green
        } else {
            Write-Host "PostgreSQL: container healthy, but port 5432 not reachable" -ForegroundColor Yellow
        }
        if ($redisOk.TcpTestSucceeded) {
            $pong = docker exec gornaya-salanga-redis redis-cli ping 2>$null
            Write-Host "Redis:      port 6379 reachable ($pong)" -ForegroundColor Green
        } else {
            Write-Host "Redis:      container healthy, but port 6379 NOT reachable" -ForegroundColor Red
            Write-Host "Wait 10 seconds and run: docker compose ps"
            exit 1
        }
        Write-Host ""
        Write-Host "backend\.env:"
        Write-Host "  REDIS_URL=redis://127.0.0.1:6379/0"
        Write-Host ""
        Write-Host "IMPORTANT: restart backend if it was already running:" -ForegroundColor Cyan
        Write-Host "  cd backend"
        Write-Host "  go run ./cmd/api"
        Write-Host "  (look for: redis connected)"
        exit 0
    }
    Start-Sleep -Seconds 2
}

Write-Host "Containers started but health check timed out. Current status:"
docker compose ps
Write-Host ""
Write-Host "If Redis is missing, try: docker compose up -d redis"
Write-Host "Then set REDIS_URL=redis://127.0.0.1:6379/0 in backend\.env"
