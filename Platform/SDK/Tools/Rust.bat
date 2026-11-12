@echo off
setlocal
where pwsh.exe >nul 2>&1
if errorlevel 1 (
    echo FEHLER: PowerShell 7 ^(pwsh.exe^) wurde nicht gefunden.
    exit /b 1
)
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Rust.ps1" %*
exit /b %ERRORLEVEL%
