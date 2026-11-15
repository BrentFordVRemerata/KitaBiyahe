@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run-Checks.ps1"
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" (echo Command completed.) else (echo Command failed with exit code %RESULT%.)
if /I not "%~1"=="--no-pause" pause
exit /b %RESULT%
