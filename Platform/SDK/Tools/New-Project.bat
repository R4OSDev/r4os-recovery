@echo off
pwsh -NoLogo -NoProfile -File "%~dp0New-Project.ps1" %*
exit /b %errorlevel%
