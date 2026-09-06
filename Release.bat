@echo off
where pwsh >nul 2>nul
if errorlevel 1 (
    echo PowerShell 7 is required ^(pwsh^).
    exit /b 1
)
pwsh -NoLogo -NoProfile -File "%~dp0Release.ps1" %*
exit /b %errorlevel%
