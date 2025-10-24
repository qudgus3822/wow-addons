@echo off
REM WoW Addon Symlink Creator

echo ========================================
echo WoW Addon Symlink Creator
echo ========================================
echo.
echo Starting PowerShell script...
echo Please click 'Yes' when prompted for admin rights.
echo.
pause

REM Run PowerShell script as Administrator
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoExit -File \"%~dp0create-symlink-en.ps1\"' -Verb RunAs"
