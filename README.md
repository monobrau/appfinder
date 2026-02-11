# CodeMeter Runtime Finder

Scripts to help locate CodeMeter Runtime installations on Windows systems, designed for use with ConnectWise ScreenConnect remote sessions.

## Problem
A device with IP address **10.20.150.235** (CONF-LARGE) needs to be checked for CodeMeter Runtime installation, but it's not showing up in the RMM portal.

## Files

### 1. `Find-CodeMeterRuntime.ps1` (Full Script)
Comprehensive PowerShell script that searches for CodeMeter Runtime using multiple detection methods:
- Installed Programs (Registry - 32-bit and 64-bit)
- Installed Programs (WMI)
- Running Processes
- Windows Services
- File System Locations
- Scheduled Tasks
- Device Drivers

**Usage:**
```powershell
.\Find-CodeMeterRuntime.ps1
```

**With output file:**
```powershell
.\Find-CodeMeterRuntime.ps1 -OutputFile "C:\temp\codemeter-results.txt"
```

### 2. `Find-CodeMeterRuntime-OneLiner.ps1` (Quick Version)
Single-line PowerShell command that can be quickly copied and pasted into ScreenConnect's command prompt.

**Usage:**
1. Open the file and copy the entire command
2. Paste into ScreenConnect's command prompt or PowerShell window
3. Press Enter

## How to Use with ConnectWise ScreenConnect

### Method 1: Upload and Run Script
1. Connect to the target machine via ScreenConnect
2. Upload `Find-CodeMeterRuntime.ps1` to the machine (e.g., `C:\temp\`)
3. Open PowerShell as Administrator
4. Navigate to the script location: `cd C:\temp`
5. Run: `.\Find-CodeMeterRuntime.ps1`

### Method 2: Copy-Paste One-Liner
1. Connect to the target machine via ScreenConnect
2. Open PowerShell or Command Prompt
3. Copy the entire command from `Find-CodeMeterRuntime-OneLiner.ps1`
4. Paste and press Enter

### Method 3: Direct PowerShell Execution
1. In ScreenConnect, open PowerShell
2. Copy and paste this command:
```powershell
powershell -ExecutionPolicy Bypass -File "\\path\to\Find-CodeMeterRuntime.ps1"
```

## What to Look For

The script will display:
- **Computer Name** and **IP Address** (to confirm you're on the right machine)
- **Green text** if CodeMeter Runtime is found
- **Red text** if CodeMeter Runtime is not found
- Specific details about where it was found (registry, processes, services, etc.)

## Target Device

Based on the ConnectWise configuration list:
- **Device Name:** CONF-LARGE
- **IP Address:** 10.20.150.235
- **OS:** Microsoft Windows 10 Pro x64

## Notes

- The script requires PowerShell (available on Windows 7+)
- Some checks may require Administrator privileges
- The script is safe to run and only reads information (no modifications)
- If CodeMeter Runtime is found, you'll see detailed information about its location and version

## Troubleshooting

If the device is offline or unreachable:
1. Check if the device is powered on
2. Verify network connectivity (ping 10.20.150.235)
3. Check if ScreenConnect agent is installed and running
4. Consider scheduling an on-site visit if remote access isn't possible
