@echo off
REM WoW Auto Symlink Creator - Links ALL folders

echo ========================================
echo WoW Auto Symlink Creator
echo ========================================
echo.
echo This will create symlinks for ALL folders in:
echo D:\Source\Wow\
echo.
echo Press any key to continue...
pause > nul

REM Run PowerShell script as Administrator
powershell -ExecutionPolicy Bypass -Command "Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -NoExit -File \"%~dp0create-all-symlinks.ps1\"' -Verb RunAs"
