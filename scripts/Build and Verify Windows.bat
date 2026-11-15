@echo off
setlocal
set "SCRIPT=%~dp0Build-Verify-Windows.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" (echo Build and verification completed.) else (echo Build or verification failed with exit code %RESULT%.)
if /I not "%~1"=="--no-pause" pause
exit /b %RESULT%
