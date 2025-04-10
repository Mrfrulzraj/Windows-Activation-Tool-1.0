@echo off
title Quality Check Tool (Manual Driver Install)
setlocal enabledelayedexpansion

rem Resize window for following masses of content
mode 100,65

::: ============================================
::: 1. Force Admin Rights (Required for SDI/Wi-Fi)
::: ============================================
fltmc >nul 2>&1 || (
    echo [ADMIN REQUIRED] Restarting as administrator...
    timeout /t 2 >nul
    powershell -command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

::: ============================================
::: 2. Internet Check + Wi-Fi Connect
::: ============================================
:: Define WiFi name and password
set SSID=Asher
set Password=06112019

:: Create a WiFi profile XML file
(
echo ^<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1"^>
echo     ^<name^>%SSID%^</name^>
echo     ^<SSIDConfig^>
echo         ^<SSID^>
echo             ^<name^>%SSID%^</name^>
echo         ^</SSID^>
echo     ^</SSIDConfig^>
echo     ^<connectionType^>ESS^</connectionType^>
echo     ^<connectionMode^>manual^</connectionMode^>
echo     ^<MSM^>
echo         ^<security^>
echo             ^<authEncryption^>
echo                 ^<authentication^>WPA2PSK^</authentication^>
echo                 ^<encryption^>AES^</encryption^>
echo                 ^<useOneX^>false^</useOneX^>
echo             ^</authEncryption^>
echo             ^<sharedKey^>
echo                 ^<keyType^>passPhrase^</keyType^>
echo                 ^<protected^>false^</protected^>
echo                 ^<keyMaterial^>%Password%^</keyMaterial^>
echo             ^</sharedKey^>
echo         ^</security^>
echo     ^</MSM^>
echo ^</WLANProfile^>
) > WiFiProfile.xml

:: Add the WiFi profile
netsh wlan add profile filename="WiFiProfile.xml" user=current

:: Connect to the WiFi network
netsh wlan connect name=%SSID%

:: Clean up the temporary WiFi profile file
del WiFiProfile.xml

call :ColorEcho 92 "Successfully Connected to "%SSID%"".
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

echo ===============================
echo    WINDOWS ACTIVATION STATUS
echo ===============================
echo.
echo Checking license status... Please wait.
echo.

:: Check Windows activation status using slmgr.vbs
cscript //nologo %windir%\system32\slmgr.vbs /xpr
echo ============================================
echo Additional Information:
echo.

:: Check Windows edition and product key
wmic os get caption
:: Check remaining grace period (if unactivated)
cscript //nologo %windir%\system32\slmgr.vbs /dli

::: ============================================
::: 4. System Specs (After SDI is closed)
::: ============================================
echo.
echo ========================
echo       SYSTEM SPECS 
echo ========================
echo.
echo == CPU ==
wmic cpu get name | findstr /v "Name"
echo.

echo == RAM ==
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

echo == Storage ==
wmic diskdrive get model,size | findstr /v "Size"
)
echo _________________________
echo.

:: Check TPM 1.2/2.0
echo TPM 1.2/2.0:
powershell -Command "(Get-Tpm).TpmPresent" > "%TEMP%\temp_tpm_present.txt"
findstr /i "True" "%TEMP%\temp_tpm_present.txt" > nul

if %errorlevel% equ 0 (
    powershell -Command "(Get-Tpm).TpmReady" > "%TEMP%\temp_tpm_ready.txt"
    findstr /i "True" "%TEMP%\temp_tpm_ready.txt" > nul

    if %errorlevel% equ 0 (
        powershell -Command "(Get-Tpm).ManufacturerVersion -like '2.0*'" > "%TEMP%\temp_tpm_version.txt"
        findstr /i "True" "%TEMP%\temp_tpm_version.txt" > nul

        if %errorlevel% equ 0 (
            set tpmStatus=Enabled
            call :ColorEcho 92 Enabled
        ) else (
            set tpmStatus=Disabled
            call :ColorEcho 91 "Disabled or Not Found (not version 2.0)"
        )
        del "%TEMP%\temp_tpm_version.txt"
    ) else (
        set tpmStatus=Disabled
        call :ColorEcho 91 "Disabled or Not Ready"
    )
    del "%TEMP%\temp_tpm_ready.txt"
) else (
    set tpmStatus=NotFound
    call :ColorEcho 91 "Not Found"
)
del "%TEMP%\temp_tpm_present.txt"

goto :secureboot

:secureboot
echo.
echo Secure Boot:
powershell -Command "Confirm-SecureBootUEFI" > "%TEMP%\temp_sb.txt"
findstr /i "True" "%TEMP%\temp_sb.txt" > nul

if %errorlevel% equ 0 (
    set secureBootStatus=Enabled
    call :ColorEcho 92 Enabled
) else (
    set secureBootStatus=Disabled
    call :ColorEcho 91 Disabled
)
echo.

echo.
(pause)
goto :eof

:ColorEcho
echo [%1m%~2[0m
exit /b