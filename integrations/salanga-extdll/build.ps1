# Сборка SalangaExtDll.dll (32-bit) для FarCards Type=1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Repo = Resolve-Path (Join-Path $Root "..\..")
$BuildDir = Join-Path $Repo "build\salanga-extdll"

function Find-VcVars32 {
    $vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vswhere)) { return $null }
    $install = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
    if (-not $install) { return $null }
    $vcvars = Join-Path $install "VC\Auxiliary\Build\vcvars32.bat"
    if (Test-Path $vcvars) { return $vcvars }
    return $null
}

$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if (-not $cmake) {
    Write-Host "cmake не найден. Установите CMake и «Desktop development with C++» (VS Build Tools), затем повторите." -ForegroundColor Yellow
    Write-Host "  winget install Kitware.CMake"
    Write-Host "  winget install Microsoft.VisualStudio.2022.BuildTools"
    exit 1
}

$vcvars = Find-VcVars32
if ($vcvars) {
    Write-Host "Configure Win32 via $vcvars"
    cmd /c "`"$vcvars`" && cmake -S `"$Root`" -B `"$BuildDir`" -A Win32 && cmake --build `"$BuildDir`" --config Release"
} else {
    Write-Host "Visual Studio (x86 toolset) не найден — пробуем cmake -A Win32 как есть..."
    cmake -S $Root -B $BuildDir -A Win32
    cmake --build $BuildDir --config Release
}

$dll = Get-ChildItem -Path $BuildDir -Recurse -Filter "SalangaExtDll.dll" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($dll) {
    Write-Host "OK: $($dll.FullName)" -ForegroundColor Green
} else {
    Write-Host "DLL не найдена в $BuildDir" -ForegroundColor Red
    exit 1
}
