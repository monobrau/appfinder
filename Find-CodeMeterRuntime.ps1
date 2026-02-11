<#
.SYNOPSIS
    Searches for CodeMeter Runtime installation on a Windows system.
.DESCRIPTION
    This script searches for CodeMeter Runtime using multiple methods:
    - Installed Programs (Registry)
    - Installed Programs (WMI)
    - Running Processes
    - File System Locations
    - Windows Services
    - Scheduled Tasks
    
    Designed for use with ConnectWise ScreenConnect remote sessions.
.PARAMETER OutputFile
    Optional path to save results to a text file.
.EXAMPLE
    .\Find-CodeMeterRuntime.ps1
.EXAMPLE
    .\Find-CodeMeterRuntime.ps1 -OutputFile "C:\temp\codemeter-results.txt"
#>

[CmdletBinding()]
param(
    [string]$OutputFile = ""
)

$results = @()
$found = $false

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CodeMeter Runtime Detection Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Computer Name: $env:COMPUTERNAME" -ForegroundColor Yellow
Write-Host "IP Address: $((Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object -First 1).IPAddress)" -ForegroundColor Yellow
Write-Host "Date/Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Function to add result
function Add-Result {
    param([string]$Category, [string]$Detail)
    $script:results += "$Category`: $Detail"
    Write-Host "[$Category] $Detail" -ForegroundColor Green
    $script:found = $true
}

# 1. Check Installed Programs via Registry (32-bit)
Write-Host "Checking Registry (32-bit programs)..." -ForegroundColor White
$reg32 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*CodeMeter*" }
if ($reg32) {
    foreach ($item in $reg32) {
        $installPath = if ($item.InstallLocation) { " - Install Path: $($item.InstallLocation)" } else { "" }
        $uninstallPath = if ($item.UninstallString) { " - Uninstall: $($item.UninstallString)" } else { "" }
        Add-Result "INSTALLED PROGRAM (Registry 32-bit)" "$($item.DisplayName) - Version: $($item.DisplayVersion) - Publisher: $($item.Publisher)$installPath$uninstallPath"
    }
}

# 2. Check Installed Programs via Registry (64-bit)
Write-Host "Checking Registry (64-bit programs)..." -ForegroundColor White
$reg64 = Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*CodeMeter*" }
if ($reg64) {
    foreach ($item in $reg64) {
        $installPath = if ($item.InstallLocation) { " - Install Path: $($item.InstallLocation)" } else { "" }
        $uninstallPath = if ($item.UninstallString) { " - Uninstall: $($item.UninstallString)" } else { "" }
        Add-Result "INSTALLED PROGRAM (Registry 64-bit)" "$($item.DisplayName) - Version: $($item.DisplayVersion) - Publisher: $($item.Publisher)$installPath$uninstallPath"
    }
}

# 3. Check Installed Programs via WMI
Write-Host "Checking WMI (Installed Programs)..." -ForegroundColor White
$wmiPrograms = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -like "*CodeMeter*" }
if ($wmiPrograms) {
    foreach ($prog in $wmiPrograms) {
        $installPath = if ($prog.InstallLocation) { " - Install Path: $($prog.InstallLocation)" } else { "" }
        Add-Result "INSTALLED PROGRAM (WMI)" "$($prog.Name) - Version: $($prog.Version) - Vendor: $($prog.Vendor)$installPath"
    }
}

# 4. Check Running Processes
Write-Host "Checking Running Processes..." -ForegroundColor White
$processes = Get-Process -ErrorAction SilentlyContinue | 
    Where-Object { $_.ProcessName -like "*CodeMeter*" -or $_.ProcessName -like "*cm*" }
if ($processes) {
    foreach ($proc in $processes) {
        $procPath = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)").ExecutablePath
        Add-Result "RUNNING PROCESS" "$($proc.ProcessName) (PID: $($proc.Id)) - Path: $procPath"
    }
}

# 5. Check Windows Services
Write-Host "Checking Windows Services..." -ForegroundColor White
$services = Get-Service -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*CodeMeter*" -or $_.Name -like "*CodeMeter*" }
if ($services) {
    foreach ($svc in $services) {
        $svcPath = (Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'").PathName
        Add-Result "WINDOWS SERVICE" "$($svc.DisplayName) (Status: $($svc.Status)) - Path: $svcPath"
    }
}

# 6. Check Common Installation Paths
Write-Host "Checking Common Installation Paths..." -ForegroundColor White
$commonPaths = @(
    "C:\Program Files\CodeMeter",
    "C:\Program Files (x86)\CodeMeter",
    "C:\Program Files\WIBU-SYSTEMS",
    "C:\Program Files (x86)\WIBU-SYSTEMS",
    "C:\Windows\System32\cm*",
    "C:\Windows\SysWOW64\cm*"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*CodeMeter*" -or $_.Name -like "*cm*" } | 
            Select-Object -First 5
        if ($items) {
            Add-Result "FILE SYSTEM" "Found CodeMeter files in: $path"
            foreach ($item in $items) {
                Write-Host "  - $($item.FullName)" -ForegroundColor Gray
            }
        }
    }
}

# 7. Check Scheduled Tasks
Write-Host "Checking Scheduled Tasks..." -ForegroundColor White
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | 
    Where-Object { $_.TaskName -like "*CodeMeter*" -or $_.TaskName -like "*cm*" }
if ($tasks) {
    foreach ($task in $tasks) {
        Add-Result "SCHEDULED TASK" "$($task.TaskName) - State: $($task.State)"
    }
}

# 8. Check for CodeMeter drivers
Write-Host "Checking Device Drivers..." -ForegroundColor White
$drivers = Get-WmiObject Win32_SystemDriver -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -like "*CodeMeter*" -or $_.Name -like "*cm*" }
if ($drivers) {
    foreach ($drv in $drivers) {
        Add-Result "DEVICE DRIVER" "$($drv.Name) - Path: $($drv.PathName) - State: $($drv.State)"
    }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($found) {
    Write-Host "RESULT: CodeMeter Runtime FOUND on this system!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
} else {
    Write-Host "RESULT: CodeMeter Runtime NOT FOUND on this system." -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Cyan
}

# Output to file if specified
if ($OutputFile -ne "") {
    $output = @()
    $output += "CodeMeter Runtime Detection Report"
    $output += "=================================="
    $output += "Computer Name: $env:COMPUTERNAME"
    $output += "Date/Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += ""
    if ($results.Count -gt 0) {
        $output += "FINDINGS:"
        $output += $results
    } else {
        $output += "No CodeMeter Runtime found on this system."
    }
    $output | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "Results saved to: $OutputFile" -ForegroundColor Yellow
}

# Return exit code for automation
if ($found) {
    exit 0
} else {
    exit 1
}
