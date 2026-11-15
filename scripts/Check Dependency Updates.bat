@echo off
setlocal
set "SCRIPT=%~dp0Check-Dependency-Updates.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo Update check failed with exit code %RESULT%.
if /I not "%~1"=="--no-pause" pause
exit /b %RESULT%
