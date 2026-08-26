# Convert unencrypted PuTTY .ppk (ed25519) to OpenSSH private key.
# Usage: .\convert-ppk.ps1 -PpkPath C:\Users\AN\Downloads\dev@api.salanga.ru.ppk

param(
    [Parameter(Mandatory = $true)]
    [string]$PpkPath,
    [string]$OutPath = ""
)

$ErrorActionPreference = "Stop"

function Read-PpkLines([string[]]$lines, [string]$key) {
    $header = $lines | Where-Object { $_ -match "^${key}:\s*(\d+)\s*$" } | Select-Object -First 1
    if (-not $header) { throw "PPK missing $key" }
    if ($header -notmatch "^${key}:\s*(\d+)\s*$") { throw "Invalid $key header" }
    $count = [int]$Matches[1]
    $start = [array]::IndexOf($lines, $header)
    ($lines[($start + 1)..($start + $count)]) -join ""
}

function Read-BeUInt32([byte[]]$b, [int]$offset = 0) {
    return ([uint32]$b[$offset] -shl 24) -bor ([uint32]$b[$offset + 1] -shl 16) -bor ([uint32]$b[$offset + 2] -shl 8) -bor [uint32]$b[$offset + 3]
}

function Write-BeUInt32([System.IO.BinaryWriter]$w, [uint32]$v) {
    $w.Write([byte](($v -shr 24) -band 0xff))
    $w.Write([byte](($v -shr 16) -band 0xff))
    $w.Write([byte](($v -shr 8) -band 0xff))
    $w.Write([byte]($v -band 0xff))
}
function Write-SshString([System.IO.BinaryWriter]$w, [string]$s) {
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($s)
    Write-BeUInt32 $w ([uint32]$bytes.Length)
    $w.Write($bytes)
}

function Write-SshBytes([System.IO.BinaryWriter]$w, [byte[]]$b) {
    Write-BeUInt32 $w ([uint32]$b.Length)
    $w.Write($b)
}

if (-not (Test-Path $PpkPath)) { throw "File not found: $PpkPath" }

$lines = Get-Content $PpkPath
if ($lines[0] -notmatch 'PuTTY-User-Key-File') { throw "Not a PuTTY key file" }
if (($lines | Select-String '^Encryption:').Line -ne 'Encryption: none') {
    throw "Only unencrypted PPK supported. Use PuTTYgen to remove passphrase first."
}
if (($lines | Select-String '^PuTTY-User-Key-File').Line -notmatch '2|3') {
    throw "Unsupported PPK version"
}

$keyTypeLine = ($lines | Select-String '^PuTTY-User-Key-File').Line
$algo = ($lines | Where-Object { $_ -match '^Comment:' } | Select-Object -First 1)
$comment = if ($lines -match '^Comment: (.+)$') { $Matches[1] } else { "converted-from-ppk" }

$pubB64 = Read-PpkLines $lines "Public-Lines"
$privB64 = Read-PpkLines $lines "Private-Lines"
$pubRaw = [Convert]::FromBase64String($pubB64)
$seedRaw = [Convert]::FromBase64String($privB64)
if ($seedRaw.Length -eq 36) {
    $len = Read-BeUInt32 $seedRaw 0
    if ($len -eq 32) { $seed = $seedRaw[4..35] } else { throw "Unexpected private blob length prefix $len" }
} elseif ($seedRaw.Length -eq 32) {
    $seed = $seedRaw
} else {
    throw "Expected 32-byte ed25519 seed, got $($seedRaw.Length)"
}

# pubRaw = "ssh-ed25519" + u32 len + 32-byte pubkey
$pubKey = $pubRaw[($pubRaw.Length - 32)..($pubRaw.Length - 1)]
$priv64 = New-Object byte[] 64
[Array]::Copy($seed, 0, $priv64, 0, 32)
[Array]::Copy($pubKey, 0, $priv64, 32, 32)

$pubSsh = New-Object System.IO.MemoryStream
$pubW = New-Object System.IO.BinaryWriter($pubSsh)
Write-SshString $pubW "ssh-ed25519"
Write-SshBytes $pubW $pubKey
$pubBlob = $pubSsh.ToArray()

$check = Get-Random -Minimum 0 -Maximum ([int]::MaxValue)
$inner = New-Object System.IO.MemoryStream
$iw = New-Object System.IO.BinaryWriter($inner)
Write-BeUInt32 $iw ([uint32]$check)
Write-BeUInt32 $iw ([uint32]$check)
Write-SshString $iw "ssh-ed25519"
Write-SshBytes $iw $pubKey
Write-SshBytes $iw $priv64
Write-SshString $iw $comment
$pad = 8 - ($inner.Length % 8)
if ($pad -eq 8) { $pad = 0 }
for ($i = 1; $i -le $pad; $i++) { $iw.Write([byte]$i) }
$innerBlob = $inner.ToArray()

$outer = New-Object System.IO.MemoryStream
$ow = New-Object System.IO.BinaryWriter($outer)
$magic = [System.Text.Encoding]::ASCII.GetBytes("openssh-key-v1`0")
$ow.Write($magic)
Write-SshString $ow "none"
Write-SshString $ow "none"
Write-SshBytes $ow @()
Write-BeUInt32 $ow 1
Write-SshBytes $ow $pubBlob
Write-SshBytes $ow $innerBlob

$b64 = [Convert]::ToBase64String($outer.ToArray())
$chunks = [regex]::Matches($b64, '.{1,70}') | ForEach-Object { $_.Value }
$pem = @("-----BEGIN OPENSSH PRIVATE KEY-----") + $chunks + @("-----END OPENSSH PRIVATE KEY-----") -join "`n"

if ([string]::IsNullOrWhiteSpace($OutPath)) {
    $OutPath = Join-Path $PSScriptRoot "salanga_dev"
}
$dir = Split-Path $OutPath -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
Set-Content -Path $OutPath -Value $pem -Encoding ascii -NoNewline
# Ensure trailing newline
Add-Content -Path $OutPath -Value "" -Encoding ascii

Write-Host "Converted: $OutPath" -ForegroundColor Green
Write-Host ""
Write-Host "Connect (from deploy folder):" -ForegroundColor Cyan
Write-Host "  ssh -p 22022 -i `"$OutPath`" dev@api.salanga.ru"
Write-Host "  # or: ssh -p 22022 -i .\salanga_dev dev@api.salanga.ru"
