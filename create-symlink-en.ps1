# WoW Addon Symbolic Link Creator
# Must run as Administrator!

# WoW installation path (modify this to your actual path!)
$WowAddonsPath = "D:\Source\Wow3"

# Source path
$SourcePath = "D:\Source\Wow"

# Target path
$TargetPath = Join-Path $WowAddonsPath "my-addons"

Write-Host "========================================" -ForegroundColor Green
Write-Host "WoW Addon Symlink Creator" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Source: $SourcePath" -ForegroundColor Cyan
Write-Host "Target: $TargetPath" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "How: Right-click PowerShell icon -> 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

# Check source folder exists
if (-not (Test-Path $SourcePath)) {
    Write-Host "ERROR: Source folder not found!" -ForegroundColor Red
    Write-Host "Path: $SourcePath" -ForegroundColor Yellow
    pause
    exit 1
}

# Check WoW AddOns folder exists
if (-not (Test-Path $WowAddonsPath)) {
    Write-Host "ERROR: WoW AddOns folder not found!" -ForegroundColor Red
    Write-Host "Path: $WowAddonsPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please open this script and modify the WoW installation path." -ForegroundColor Yellow
    pause
    exit 1
}

# Remove existing symlink or folder
if (Test-Path $TargetPath) {
    Write-Host "Removing existing link/folder..." -ForegroundColor Yellow
    Remove-Item $TargetPath -Force -Recurse
}

# Create symbolic link
try {
    New-Item -ItemType SymbolicLink -Path $TargetPath -Target $SourcePath -ErrorAction Stop
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Symlink created successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Now you can edit code in D:\Source\Wow\FindSecondStat" -ForegroundColor Cyan
    Write-Host "and it will be reflected in WoW immediately! (relog required)" -ForegroundColor Cyan
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to create symbolic link!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

Write-Host ""
pause
