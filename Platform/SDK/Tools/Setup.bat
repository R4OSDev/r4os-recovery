@echo off
pwsh.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup.ps1" %*
exit /b %ERRORLEVEL%
