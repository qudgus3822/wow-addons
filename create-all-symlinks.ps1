# WoW Auto Symlink Creator - Links ALL folders in source directory
# Must run as Administrator!

# WoW installation path (modify this to your actual path!)
$WowAddonsPath = "D:\Source\Wow3"

# Source base path - ALL folders here will be symlinked
$SourceBasePath = "D:\Source\Wow"

Write-Host "========================================" -ForegroundColor Green
Write-Host "WoW Auto Symlink Creator" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    pause
    exit 1
}

# Check source base path exists
if (-not (Test-Path $SourceBasePath)) {
    Write-Host "ERROR: Source base path not found!" -ForegroundColor Red
    Write-Host "Path: $SourceBasePath" -ForegroundColor Yellow
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

# Folders to exclude (will not create symlinks for these)
$ExcludeFolders = @(
    ".git",
    ".vscode",
    "node_modules",
    ".idea",
    ".vs"
)

# Get all directories in source path (excluding hidden and excluded folders)
$allFolders = Get-ChildItem -Path $SourceBasePath -Directory
$addonFolders = $allFolders | Where-Object { $ExcludeFolders -notcontains $_.Name }

if ($addonFolders.Count -eq 0) {
    Write-Host "WARNING: No folders found in $SourceBasePath" -ForegroundColor Yellow
    Write-Host "(Excluded: $($ExcludeFolders -join ', '))" -ForegroundColor Gray
    pause
    exit 0
}

Write-Host "Found $($addonFolders.Count) folder(s) in source directory:" -ForegroundColor Cyan
foreach ($folder in $addonFolders) {
    Write-Host "  - $($folder.Name)" -ForegroundColor Gray
}
Write-Host ""

$successCount = 0
$errorCount = 0

foreach ($folder in $addonFolders) {
    $SourcePath = $folder.FullName
    $TargetPath = Join-Path $WowAddonsPath $folder.Name

    Write-Host "[$($folder.Name)]" -ForegroundColor Yellow

    # Remove existing symlink or folder
    if (Test-Path $TargetPath) {
        Write-Host "  Removing existing link/folder..." -ForegroundColor Yellow
        Remove-Item $TargetPath -Force -Recurse
    }

    # Create symbolic link
    try {
        New-Item -ItemType SymbolicLink -Path $TargetPath -Target $SourcePath -ErrorAction Stop | Out-Null
        Write-Host "  SUCCESS: Symlink created!" -ForegroundColor Green
        Write-Host "  Source: $SourcePath" -ForegroundColor Gray
        Write-Host "  Target: $TargetPath" -ForegroundColor Gray
        $successCount++
    } catch {
        Write-Host "  ERROR: Failed to create symlink!" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }

    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "Summary:" -ForegroundColor Green
Write-Host "  Created: $successCount" -ForegroundColor Green
Write-Host "  Errors:  $errorCount" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

if ($successCount -gt 0) {
    Write-Host "Symlinks created successfully!" -ForegroundColor Green
    Write-Host "All folders in $SourceBasePath are now linked!" -ForegroundColor Cyan
    Write-Host "Edit code in source directory and relog WoW to see changes." -ForegroundColor Cyan
}

Write-Host ""
pause
