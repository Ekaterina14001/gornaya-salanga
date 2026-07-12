# Create PostgreSQL user/database for local dev (without Docker).
# Usage: .\setup-db.ps1
# You will be prompted for the postgres superuser password once.

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$psqlCandidates = @(
    "C:\Program Files\PostgreSQL\18\bin\psql.exe",
    "C:\Program Files\PostgreSQL\17\bin\psql.exe",
    "C:\Program Files\PostgreSQL\16\bin\psql.exe"
)

$psql = $psqlCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $psql) {
    $psqlCmd = Get-Command psql -ErrorAction SilentlyContinue
    if ($psqlCmd) { $psql = $psqlCmd.Source }
}

if (-not $psql) {
    Write-Error "psql not found. Install PostgreSQL or add its bin folder to PATH."
}

$sqlFile = Join-Path $PSScriptRoot "setup-db.sql"

Write-Host "Creating role 'salanga' and database 'gornaya_salanga'..."
Write-Host "Enter the password for PostgreSQL user 'postgres' when prompted."
Write-Host ""

& $psql -U postgres -h localhost -d postgres -v ON_ERROR_STOP=1 -f $sqlFile

if ($LASTEXITCODE -ne 0) {
    Write-Error "setup-db failed. Check postgres password and that PostgreSQL is running."
}

Write-Host ""
Write-Host "Database ready. Run migrations next:"
Write-Host "  .\migrate.ps1"
