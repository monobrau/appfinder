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
.PARAMETER CSVFile
    Optional path to save results to a CSV file (supports network shares like \\server\share\file.csv).
    If file exists, data will be appended. If not found, a new file will be created.
.EXAMPLE
    .\Find-CodeMeterRuntime.ps1
.EXAMPLE
    .\Find-CodeMeterRuntime.ps1 -OutputFile "C:\temp\codemeter-results.txt"
.EXAMPLE
    .\Find-CodeMeterRuntime.ps1 -CSVFile "\\server\share\codemeter-results.csv"
#>

[CmdletBinding()]
param(
    [string]$OutputFile = "",
    [string]$CSVFile = ""
)

$results = @()
$csvData = @()
$found = $false
$computerName = $env:COMPUTERNAME
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1'} | Select-Object -First 1).IPAddress
$scanDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CodeMeter Runtime Detection Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Computer Name: $computerName" -ForegroundColor Yellow
Write-Host "IP Address: $ipAddress" -ForegroundColor Yellow
Write-Host "Date/Time: $scanDate" -ForegroundColor Yellow
Write-Host ""

# Function to add result
function Add-Result {
    param(
        [string]$Category, 
        [string]$Detail,
        [string]$Name = "",
        [string]$Version = "",
        [string]$Publisher = "",
        [string]$InstallPath = "",
        [string]$UninstallPath = "",
        [string]$ProcessId = "",
        [string]$ServiceStatus = "",
        [string]$DriverState = ""
    )
    $script:results += "$Category`: $Detail"
    Write-Host "[$Category] $Detail" -ForegroundColor Green
    $script:found = $true
    
    # Add structured data for CSV
    $script:csvData += [PSCustomObject]@{
        ComputerName = $script:computerName
        IPAddress = $script:ipAddress
        ScanDate = $script:scanDate
        Category = $Category
        Name = $Name
        Version = $Version
        Publisher = $Publisher
        InstallPath = $InstallPath
        UninstallPath = $UninstallPath
        ProcessId = $ProcessId
        ServiceStatus = $ServiceStatus
        DriverState = $DriverState
        Detail = $Detail
    }
}

# Helper function to extract version from registry item
function Get-RegistryVersion {
    param($item)
    if ($item.DisplayVersion) {
        return $item.DisplayVersion.ToString()
    }
    elseif ($item.VersionString) {
        return $item.VersionString.ToString()
    }
    elseif ($item.Version) {
        return $item.Version.ToString()
    }
    else {
        return ""
    }
}

# 1. Check Installed Programs via Registry (32-bit)
Write-Host "Checking Registry (32-bit programs)..." -ForegroundColor White
$reg32 = Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*CodeMeter*" -or $_.DisplayName -like "*WIBU*" -or $_.Publisher -like "*WIBU*" }
if ($reg32) {
    foreach ($item in $reg32) {
        $version = Get-RegistryVersion -item $item
        $installPath = if ($item.InstallLocation) { " - Install Path: $($item.InstallLocation)" } else { "" }
        $uninstallPath = if ($item.UninstallString) { " - Uninstall: $($item.UninstallString)" } else { "" }
        $detail = "$($item.DisplayName) - Version: $version - Publisher: $($item.Publisher)$installPath$uninstallPath"
        Add-Result -Category "INSTALLED PROGRAM (Registry 32-bit)" -Detail $detail -Name $item.DisplayName -Version $version -Publisher $item.Publisher -InstallPath $item.InstallLocation -UninstallPath $item.UninstallString
    }
}

# 2. Check Installed Programs via Registry (64-bit)
Write-Host "Checking Registry (64-bit programs)..." -ForegroundColor White
$reg64 = Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*CodeMeter*" -or $_.DisplayName -like "*WIBU*" -or $_.Publisher -like "*WIBU*" }
if ($reg64) {
    foreach ($item in $reg64) {
        $version = Get-RegistryVersion -item $item
        $installPath = if ($item.InstallLocation) { " - Install Path: $($item.InstallLocation)" } else { "" }
        $uninstallPath = if ($item.UninstallString) { " - Uninstall: $($item.UninstallString)" } else { "" }
        $detail = "$($item.DisplayName) - Version: $version - Publisher: $($item.Publisher)$installPath$uninstallPath"
        Add-Result -Category "INSTALLED PROGRAM (Registry 64-bit)" -Detail $detail -Name $item.DisplayName -Version $version -Publisher $item.Publisher -InstallPath $item.InstallLocation -UninstallPath $item.UninstallString
    }
}

# 3. Check Installed Programs via WMI
Write-Host "Checking WMI (Installed Programs)..." -ForegroundColor White
$wmiPrograms = Get-WmiObject -Class Win32_Product -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -like "*CodeMeter*" -or $_.Name -like "*WIBU*" -or $_.Vendor -like "*WIBU*" }
if ($wmiPrograms) {
    foreach ($prog in $wmiPrograms) {
        $version = if ($prog.Version) { $prog.Version.ToString() } else { "" }
        $installPath = if ($prog.InstallLocation) { " - Install Path: $($prog.InstallLocation)" } else { "" }
        $detail = "$($prog.Name) - Version: $version - Vendor: $($prog.Vendor)$installPath"
        Add-Result -Category "INSTALLED PROGRAM (WMI)" -Detail $detail -Name $prog.Name -Version $version -Publisher $prog.Vendor -InstallPath $prog.InstallLocation
    }
}

# 4. Check Running Processes
Write-Host "Checking Running Processes..." -ForegroundColor White
$processes = Get-Process -ErrorAction SilentlyContinue | 
    Where-Object { $_.ProcessName -like "*CodeMeter*" }
if ($processes) {
    foreach ($proc in $processes) {
        $procPath = (Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)").ExecutablePath
        # Only report if path contains CodeMeter or WIBU
        if ($procPath -like "*CodeMeter*" -or $procPath -like "*WIBU*" -or $proc.ProcessName -like "*CodeMeter*") {
            $detail = "$($proc.ProcessName) (PID: $($proc.Id)) - Path: $procPath"
            Add-Result -Category "RUNNING PROCESS" -Detail $detail -Name $proc.ProcessName -ProcessId $proc.Id -InstallPath $procPath
        }
    }
}

# 5. Check Windows Services
Write-Host "Checking Windows Services..." -ForegroundColor White
$services = Get-Service -ErrorAction SilentlyContinue | 
    Where-Object { $_.DisplayName -like "*CodeMeter*" -or $_.Name -like "*CodeMeter*" -or $_.DisplayName -like "*WIBU*" -or $_.Name -like "*WIBU*" }
if ($services) {
    foreach ($svc in $services) {
        $svcPath = (Get-WmiObject Win32_Service -Filter "Name='$($svc.Name)'").PathName
        $detail = "$($svc.DisplayName) (Status: $($svc.Status)) - Path: $svcPath"
        Add-Result -Category "WINDOWS SERVICE" -Detail $detail -Name $svc.DisplayName -ServiceStatus $svc.Status -InstallPath $svcPath
    }
}

# 6. Check Common Installation Paths
Write-Host "Checking Common Installation Paths..." -ForegroundColor White
$commonPaths = @(
    "C:\Program Files\CodeMeter",
    "C:\Program Files (x86)\CodeMeter",
    "C:\Program Files\WIBU-SYSTEMS",
    "C:\Program Files (x86)\WIBU-SYSTEMS"
)

foreach ($path in $commonPaths) {
    if (Test-Path $path) {
        $items = Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like "*CodeMeter*" -or $_.Name -like "*WIBU*" -or $_.FullName -like "*CodeMeter*" -or $_.FullName -like "*WIBU*" } | 
            Select-Object -First 5
        if ($items) {
            $detail = "Found CodeMeter files in: $path"
            Add-Result -Category "FILE SYSTEM" -Detail $detail -InstallPath $path
            foreach ($item in $items) {
                Write-Host "  - $($item.FullName)" -ForegroundColor Gray
            }
        }
    }
}

# 7. Check Scheduled Tasks
Write-Host "Checking Scheduled Tasks..." -ForegroundColor White
$tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | 
    Where-Object { $_.TaskName -like "*CodeMeter*" -or $_.TaskName -like "*WIBU*" }
if ($tasks) {
    foreach ($task in $tasks) {
        $detail = "$($task.TaskName) - State: $($task.State)"
        Add-Result -Category "SCHEDULED TASK" -Detail $detail -Name $task.TaskName
    }
}

# 8. Check for CodeMeter drivers
Write-Host "Checking Device Drivers..." -ForegroundColor White
$drivers = Get-WmiObject Win32_SystemDriver -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -like "*CodeMeter*" -or $_.PathName -like "*CodeMeter*" -or $_.PathName -like "*WIBU*" }
if ($drivers) {
    foreach ($drv in $drivers) {
        $detail = "$($drv.Name) - Path: $($drv.PathName) - State: $($drv.State)"
        Add-Result -Category "DEVICE DRIVER" -Detail $detail -Name $drv.Name -DriverState $drv.State -InstallPath $drv.PathName
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

# Output to CSV file if specified
if ($CSVFile -ne "") {
    # If no findings, still record that the scan was performed
    if ($csvData.Count -eq 0) {
        $csvData += [PSCustomObject]@{
            ComputerName = $computerName
            IPAddress = $ipAddress
            ScanDate = $scanDate
            Category = "SCAN COMPLETED"
            Name = ""
            Version = ""
            Publisher = ""
            InstallPath = ""
            UninstallPath = ""
            ProcessId = ""
            ServiceStatus = ""
            DriverState = ""
            Detail = "No CodeMeter Runtime found on this system"
        }
    }
    
    # Retry logic for CSV file writes (handles file locking from concurrent writes)
    $maxRetries = 5
    $retryDelay = 2  # seconds
    $success = $false
    
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            # Check if file exists to determine if we need headers
            $fileExists = Test-Path $CSVFile -ErrorAction SilentlyContinue
            
            # Export to CSV (append if file exists)
            $csvData | Export-Csv -Path $CSVFile -NoTypeInformation -Append:$fileExists -Encoding UTF8
            
            Write-Host "CSV results saved to: $CSVFile" -ForegroundColor Yellow
            if ($fileExists) {
                Write-Host "  (Appended to existing file)" -ForegroundColor Gray
            } else {
                Write-Host "  (New file created)" -ForegroundColor Gray
            }
            $success = $true
            break
        }
        catch {
            if ($attempt -lt $maxRetries) {
                Write-Host "  Attempt $attempt failed, retrying in $retryDelay seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $retryDelay
            } else {
                Write-Host "ERROR: Could not write to CSV file after $maxRetries attempts: $CSVFile" -ForegroundColor Red
                Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "  Check network connectivity and file permissions." -ForegroundColor Yellow
            }
        }
    }
}

# Output to text file if specified
if ($OutputFile -ne "") {
    try {
        $output = @()
        $output += "CodeMeter Runtime Detection Report"
        $output += "=================================="
        $output += "Computer Name: $computerName"
        $output += "Date/Time: $scanDate"
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
    catch {
        Write-Host "ERROR: Could not write to output file: $OutputFile" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Return exit code for automation
if ($found) {
    exit 0
} else {
    exit 1
}
