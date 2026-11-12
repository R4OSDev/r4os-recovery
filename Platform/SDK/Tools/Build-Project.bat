@echo off
pwsh -NoLogo -NoProfile -File "%~dp0Build-Project.ps1" %*
exit /b %errorlevel%
