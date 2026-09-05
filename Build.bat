@echo off
setlocal EnableExtensions DisableDelayedExpansion
where pwsh.exe >nul 2>nul
if errorlevel 1 (
    echo PowerShell 7 ^(pwsh.exe^) is required. Run the workspace setup first.
    exit /b 1
)
pwsh.exe -NoLogo -NoProfile -File "%~dp0Build.ps1" %*
exit /b %ERRORLEVEL%
