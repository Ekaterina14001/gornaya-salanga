# Run DB migrations on Windows (replaces: make migrate-up)
# Usage: .\migrate.ps1
#        .\migrate.ps1 -Down   # rollback one migration

param(
    [switch]$Down
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$databaseUrl = $env:DATABASE_URL
if (-not $databaseUrl) {
    if (Test-Path ".env") {
        Get-Content ".env" | ForEach-Object {
            if ($_ -match '^\s*DATABASE_URL=(.+)$') {
                $databaseUrl = $matches[1].Trim().Trim('"').Trim("'")
            }
        }
    }
}
if (-not $databaseUrl) {
    $databaseUrl = "postgres://salanga:salanga@localhost:5432/gornaya_salanga?sslmode=disable"
}

$migrate = Get-Command migrate -ErrorAction SilentlyContinue
if (-not $migrate) {
    Write-Host "Installing golang-migrate CLI..."
    go install -tags "postgres" github.com/golang-migrate/migrate/v4/cmd/migrate@latest
    $goBin = Join-Path (go env GOPATH) "bin"
    if ($env:PATH -notlike "*$goBin*") {
        $env:PATH = "$goBin;$env:PATH"
    }
}

if ($Down) {
    migrate -path migrations -database $databaseUrl down 1
} else {
    migrate -path migrations -database $databaseUrl up
}

Write-Host "Done."
