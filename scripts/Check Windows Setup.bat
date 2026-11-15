@echo off
setlocal
set "SCRIPT=%~dp0Check-Windows-Setup.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo Setup check reported a problem. See the messages above.
if /I not "%~1"=="--no-pause" pause
exit /b %RESULT%
