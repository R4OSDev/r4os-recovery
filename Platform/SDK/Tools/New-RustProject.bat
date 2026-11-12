@echo off
pwsh -NoLogo -NoProfile -File "%~dp0New-RustProject.ps1" %*
exit /b %errorlevel%
