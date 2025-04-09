@echo off
title Quality Check Tool (Manual Driver Install)
color 0A
setlocal enabledelayedexpansion

::: ============================================
::: 1. Force Admin Rights (Required for SDI/Wi-Fi)
::: ============================================
fltmc >nul 2>&1 || (
    echo [ADMIN REQUIRED] Restarting as administrator...
    timeout /t 2 >nul
    powershell -command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)
echo [SUCCESS] Running as administrator.

::: ============================================
::: 2. Internet Check + Wi-Fi Connect
::: ============================================
echo Checking internet connection...
ping -n 1 8.8.8.8 >nul && (
    echo [OK] Internet connected.
) || (
    echo [FAIL] No internet. Connecting to "Production1"...
    netsh wlan connect name="Production1" >nul 2>&1
    timeout /t 5 >nul
    ping -n 1 8.8.8.8 >nul && (
        echo [OK] Wi-Fi connected.
    ) || (
        echo [ERROR] Still offline. Continuing anyway...
    )
)

::: ============================================
::: 3. MANUAL SDI LAUNCH (Wait for user to close)
::: ============================================
echo.
for /f "tokens=*" %%a in ('dir /b /od "%~dp0SDI_%xOS%*.exe"') do set "SDIEXE=%%a"
if exist "%~dp0%SDIEXE%" (
 start "Snappy Driver Installer" /d"%~dp0" "%~dp0%SDIEXE%" %1 %2 %3 %4 %5 %6 %7 %8 %9
)


::: ============================================
::: 4. System Specs (After SDI is closed)
::: ============================================
echo.
echo ===== SYSTEM SPECS =====
echo.
echo -- CPU --
wmic cpu get name | findstr /v "Name"
echo.

echo -- RAM --
echo Memory Information:
echo -------------------------
:: Use PowerShell to handle large numbers for RAM size
for /f "delims=" %%A in ('powershell -command "[math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory/1GB, 2)"') do (
    echo Total Physical Memory: %%A GB
)

:: Get memory frequency
for /f "tokens=2 delims==" %%B in ('wmic memorychip get speed /value ^| find "Speed"') do (
    echo Memory Frequency: %%B MHz
)
echo _________________________
echo.

echo -- Storage --
wmic diskdrive get model,size | findstr /v "Size"
)
echo _________________________
echo.

echo -- TPM --
wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get IsEnabled_InitialValue 
)

echo -- Secure Boot --
powershell -command "Confirm-SecureBootUEFI"
)
echo _________________________
echo.

::: ============================================
::: 5. Exit
::: ============================================
echo.
echo Quality check completed.
pause
exit