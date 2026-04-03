@echo off
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\start-claude-local.ps1"
set "exit_code=%errorlevel%"

if not "%exit_code%"=="0" (
  echo.
  echo Claude Local failed to start. Exit code: %exit_code%
  pause
)

exit /b %exit_code%
