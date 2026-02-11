@echo off
REM CodeMeter Runtime Finder - Batch File Wrapper
REM For use with ConnectWise ScreenConnect

echo ========================================
echo CodeMeter Runtime Detection Script
echo ========================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: PowerShell is not available on this system.
    pause
    exit /b 1
)

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0Find-CodeMeterRuntime.ps1"

echo.
echo ========================================
echo Script execution completed.
echo ========================================
pause
