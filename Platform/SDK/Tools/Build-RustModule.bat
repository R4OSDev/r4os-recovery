@echo off
pwsh -NoLogo -NoProfile -File "%~dp0Build-RustModule.ps1" %*
exit /b %errorlevel%
