@echo off
setlocal
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars32.bat"
if errorlevel 1 exit /b 1
set "SRC=C:\Users\AN\gornaya-salanga\integrations\salanga-extdll"
set "BUILD=C:\Users\AN\gornaya-salanga\build\salanga-extdll"
cmake -S "%SRC%" -B "%BUILD%" -A Win32
if errorlevel 1 exit /b 1
cmake --build "%BUILD%" --config Release
if errorlevel 1 exit /b 1
echo.
echo Built:
dir /s /b "%BUILD%\Release\SalangaExtDll.dll" 2>nul
dir /s /b "%BUILD%\SalangaExtDll.dll" 2>nul
exit /b 0
