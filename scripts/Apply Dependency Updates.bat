@echo off
setlocal
set "SCRIPT=%~dp0Apply-Dependency-Updates.ps1"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" (
  echo Dependency updates completed and Windows gates passed.
) else if "%RESULT%"=="3" (
  echo Cancelled. No dependency updates applied.
) else (
  echo Updates were not completed successfully. Review the messages above.
)
if /I not "%~1"=="--no-pause" pause
exit /b %RESULT%
