# Upload project to VPS and start demo stack (requires OpenSSH client + SSH access).
# Usage:
#   .\upload-to-vps.ps1 -Server root@203.0.113.10
#   .\upload-to-vps.ps1 -Server root@203.0.113.10 -RemotePath /opt/gornaya-salanga

param(
    [Parameter(Mandatory = $true)]
    [string]$Server,
    [string]$RemotePath = "/opt/gornaya-salanga",
    [int]$Port = 22,
    [string]$SshKeyPath = ""
)

$sshArgs = @()
$scpArgs = @()
if ($Port -ne 22) {
    $sshArgs += @("-p", "$Port")
    $scpArgs += @("-P", "$Port")
}
if ($SshKeyPath -and (Test-Path $SshKeyPath)) {
    $sshArgs += @("-i", $SshKeyPath)
    $scpArgs += @("-i", $SshKeyPath)
}
function Invoke-Ssh([string]$Remote) { & ssh @sshArgs $Server $Remote }
function Invoke-Scp([string]$Local, [string]$Remote) { & scp @scpArgs $Local "${Server}:${Remote}" }

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path $PSScriptRoot -Parent

if (-not (Test-Path (Join-Path $PSScriptRoot ".env"))) {
    Write-Host "Run .\prepare-deploy-env.ps1 first to create deploy\.env" -ForegroundColor Yellow
    Read-Host "Press Enter to close"
    exit 1
}

$ssh = Get-Command ssh -ErrorAction SilentlyContinue
$scp = Get-Command scp -ErrorAction SilentlyContinue
if (-not $ssh -or -not $scp) {
    Write-Error "OpenSSH client required (Windows: Settings -> Apps -> Optional features -> OpenSSH Client)"
}

Write-Host "Creating remote directory $RemotePath ..."
Invoke-Ssh "mkdir -p $RemotePath"

$exclude = @(
    "node_modules", ".git", "mobile/build", "mobile/.dart_tool",
    "admin/node_modules", "admin/dist", "dist", ".env"
)

Write-Host "Uploading project (may take a few minutes)..."
# rsync is ideal but often missing on Windows — use tar+ssh fallback via scp of archive
$archive = Join-Path $env:TEMP "gornaya-salanga-deploy.tar.gz"
if (Get-Command tar -ErrorAction SilentlyContinue) {
    Push-Location $repoRoot
    $tarArgs = @("-czf", $archive, "--exclude=.git", "--exclude=node_modules", "--exclude=mobile/build", "--exclude=mobile/.dart_tool", "--exclude=admin/node_modules", "--exclude=dist", ".")
    & tar @tarArgs
    Pop-Location
    Invoke-Scp $archive "/tmp/gornaya-salanga-deploy.tar.gz"
    Invoke-Ssh "mkdir -p $RemotePath && tar -xzf /tmp/gornaya-salanga-deploy.tar.gz -C $RemotePath --strip-components=0 2>/dev/null || tar -xzf /tmp/gornaya-salanga-deploy.tar.gz -C $RemotePath"
    Remove-Item $archive -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "tar not found. Upload manually via WinSCP/FileZilla to $RemotePath" -ForegroundColor Yellow
    Write-Host "Or: git clone on the server"
    Read-Host "Press Enter to close"
    exit 1
}

Write-Host "Uploading deploy/.env ..."
Invoke-Scp (Join-Path $PSScriptRoot ".env") "${RemotePath}/deploy/.env"

Write-Host "Starting docker compose on server ..."
Invoke-Ssh "cd $RemotePath/deploy && docker compose up -d --build"

Write-Host ""
Write-Host "Done. Check:" -ForegroundColor Green
$hostOnly = ($Server -split '@')[-1]
if ($hostOnly -match '^\d') {
    Write-Host "  http://${hostOnly}:8080/health"
    Write-Host "  http://${hostOnly}  (admin)"
}
Read-Host "Press Enter to close"
