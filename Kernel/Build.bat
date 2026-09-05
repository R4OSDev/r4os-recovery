@echo off
setlocal EnableExtensions DisableDelayedExpansion
call "%~dp0..\Build.bat" -Mode Kernel %*
exit /b %ERRORLEVEL%
