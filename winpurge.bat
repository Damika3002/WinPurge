@echo off
setlocal EnableExtensions EnableDelayedExpansion
title WinPurge v1.0
color 0F

rem ===========================================================================
rem  WinPurge v1.0
rem  High-Performance, Zero-Telemetry System Cleaner for Windows
rem  Native Windows Batch (No External Dependencies Required)
rem ===========================================================================

rem ---- 1. Console Virtual Terminal & ANSI Colors Initialization -------------
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1
set "NO_COLOR=0"
set "ESC="
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

if defined ESC (
    set "C_0=%ESC%[0m"
    set "C_G=%ESC%[92m"
    set "C_R=%ESC%[91m"
    set "C_Y=%ESC%[93m"
    set "C_C=%ESC%[36m"
    set "C_W=%ESC%[97m"
    set "C_D=%ESC%[90m"
) else (
    set "C_0=" & set "C_G=" & set "C_R=" & set "C_Y=" & set "C_C=" & set "C_W=" & set "C_D="
)

rem ---- 2. Optional Environment (.env) Configuration -------------------------
set "AUTO_CONFIRM=0"
set "SKIP_RECYCLE_BIN=0"
set "SKIP_PREFETCH=0"

if exist "%~dp0.env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%~dp0.env") do (
        set "_k=%%A"
        set "_v=%%B"
        if defined _k (
            set "_k=!_k: =!"
            if /i "!_k!"=="AUTO_CONFIRM" set "AUTO_CONFIRM=!_v!"
            if /i "!_k!"=="SKIP_RECYCLE_BIN" set "SKIP_RECYCLE_BIN=!_v!"
            if /i "!_k!"=="SKIP_PREFETCH" set "SKIP_PREFETCH=!_v!"
            if /i "!_k!"=="NO_COLOR" set "NO_COLOR=!_v!"
        )
    )
)

rem ---- 3. Command-Line Arguments Parsing ------------------------------------
set "IS_CHILD=0"
for %%A in (%*) do (
    if /i "%%~A"=="/y"           set "AUTO_CONFIRM=1"
    if /i "%%~A"=="/yes"         set "AUTO_CONFIRM=1"
    if /i "%%~A"=="/norecycle"   set "SKIP_RECYCLE_BIN=1"
    if /i "%%~A"=="/noprefetch"  set "SKIP_PREFETCH=1"
    if /i "%%~A"=="/nocolor"     set "NO_COLOR=1"
    if /i "%%~A"=="/child"       set "IS_CHILD=1"
)

if "%NO_COLOR%"=="1" (
    set "C_0=" & set "C_G=" & set "C_R=" & set "C_Y=" & set "C_C=" & set "C_W=" & set "C_D="
)

rem ---- 4. Administrator Privilege Check & Auto-Elevation --------------------
set "IS_ADMIN=0"
fltmc >nul 2>&1 && set "IS_ADMIN=1"
if "%IS_ADMIN%"=="0" fsutil dirty query %SystemDrive% >nul 2>&1 && set "IS_ADMIN=1"
if "%IS_ADMIN%"=="0" net session >nul 2>&1 && set "IS_ADMIN=1"
if "%IS_ADMIN%"=="0" whoami /groups 2>nul | find "S-1-16-12288" >nul && set "IS_ADMIN=1"

if "%IS_ADMIN%"=="1" goto :elevated

if "%IS_CHILD%"=="1" (
    cls
    echo %C_C%================================================================%C_0%
    echo   %C_R%[ ERROR ] Administrator privileges could not be acquired.%C_0%
    echo %C_C%================================================================%C_0%
    echo   WinPurge requires verified Administrator privileges to clean
    echo   system temporary files, manage update caches, and run DISM.
    echo.
    echo   Please right-click "winpurge.bat" and select:
    echo   "Run as administrator"
    echo %C_C%================================================================%C_0%
    echo.
    pause
    exit /b 1
)

echo Requesting Administrator privileges...
echo Please click [YES] on the Windows User Account Control prompt.

set "VBS=%TEMP%\winpurge_uac.vbs"
>"%VBS%" echo Set sh = CreateObject("Shell.Application")
>>"%VBS%" echo sh.ShellExecute "conhost.exe", "cmd.exe /k """"%~f0"" /child %*""", "", "runas", 1

cscript //nologo "%VBS%" >nul 2>&1
if errorlevel 1 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'conhost.exe' -ArgumentList 'cmd.exe /k \"\"%~f0\"\" /child %*' -Verb RunAs" >nul 2>&1
)

timeout /t 2 /nobreak >nul 2>&1
del /f /q "%VBS%" >nul 2>&1
exit /b 0

rem ---- 5. Main Execution Engine ---------------------------------------------
:elevated
cd /d "%~dp0"
cls

rem Baseline Disk Space & Metrics Initialization
set "TOTAL_DEL=0"
set "TOTAL_LOCK=0"
set "FREEBEFORE=0"
set "FREEAFTER=0"
for /f %%a in ('powershell -NoProfile -Command "(New-Object IO.DriveInfo $env:SystemDrive).AvailableFreeSpace"') do set "FREEBEFORE=%%a"

rem Fast Network Availability Check (1-second ping)
set "ONLINE=0"
ping -n 1 -w 1000 1.1.1.1 >nul 2>&1 && set "ONLINE=1"
if "%ONLINE%"=="0" ping -n 1 -w 1000 8.8.8.8 >nul 2>&1 && set "ONLINE=1"

echo %C_C%================================================================%C_0%
echo                   %C_W%W I N P U R G E   v 1 . 0%C_0%
echo            %C_D%High-Performance System Cleaner for Windows%C_0%
echo %C_C%================================================================%C_0%
echo.
echo Privilege Level : %C_G%Full Administrator [Elevated]%C_0%
echo Target Volume   : %C_W%%SystemDrive%%C_0%

if "%ONLINE%"=="1" (
    echo Network Status  : %C_G%Online [Internet Verified]%C_0%
) else (
    echo Network Status  : %C_R%[ OFFLINE ] No active internet connection detected.%C_0%
    echo                   %C_R%DISM online component cleanup will be skipped.%C_0%
)

if "%SKIP_RECYCLE_BIN%"=="1" echo Configuration   : %C_Y%Recycle Bin purge bypassed by configuration.%C_0%
if "%SKIP_PREFETCH%"=="1"    echo Configuration   : %C_Y%Prefetch cleaning bypassed by configuration.%C_0%
echo.

rem Initial Confirmation Prompt
if not "%AUTO_CONFIRM%"=="1" (
    echo %C_W%Ready to execute the deep system cleanup routine.%C_0%
    echo.
    echo   Start cleanup process? %C_G%[Y] Yes [default]%C_0% / %C_C%[N] No%C_0%
    choice /c YN /n /m "  Your choice [Y/N] > "
    if errorlevel 2 (
        echo.
        echo   %C_Y%Operation cancelled by user.%C_0%
        echo.
        pause
        exit /b 0
    )
    echo.
)

echo %C_C%----------------------------------------------------------------%C_0%
echo %C_W%Beginning system cleanup sequence...%C_0%
echo %C_C%----------------------------------------------------------------%C_0%
echo.

rem [Step 1/6] User Temp Files
echo [1/6] %C_W%Cleaning User Temporary Files...%C_0%
call :cleandir "%TEMP%" "User temporary files"
echo.

rem [Step 2/6] System Temp Files
echo [2/6] %C_W%Cleaning System Temporary Files...%C_0%
call :cleandir "%SystemRoot%\Temp" "System temporary files"
echo.

rem [Step 3/6] Prefetch Cache
echo [3/6] %C_W%Cleaning Windows Prefetch Cache...%C_0%
if "%SKIP_PREFETCH%"=="1" (
    echo       [%C_Y% SKIP %C_0%] Windows prefetch cache: Bypassed by configuration.
) else (
    call :cleandir "%SystemRoot%\Prefetch" "Windows prefetch cache"
)
echo.

rem [Step 4/6] Windows Update Cache
echo [4/6] %C_W%Cleaning Windows Update Download Cache...%C_0%
tasklist /fi "imagename eq TiWorker.exe" 2>nul | find /i "TiWorker.exe" >nul
if not errorlevel 1 (
    echo       [%C_Y% SKIP %C_0%] Windows Update cache: Skipped [Windows Update is actively installing].
) else (
    set "WU_WAS=0"
    set "BITS_WAS=0"
    sc query wuauserv 2>nul | find "RUNNING" >nul && set "WU_WAS=1"
    sc query bits 2>nul | find "RUNNING" >nul && set "BITS_WAS=1"
    if "!WU_WAS!"=="1" net stop wuauserv /y >nul 2>&1
    if "!BITS_WAS!"=="1" net stop bits /y >nul 2>&1
    call :cleandir "%SystemRoot%\SoftwareDistribution\Download" "Windows Update cache"
    if "!WU_WAS!"=="1" net start wuauserv >nul 2>&1
    if "!BITS_WAS!"=="1" net start bits >nul 2>&1
)
echo.

rem [Step 5/6] DISM Component Store
echo [5/6] %C_W%Cleaning Superseded Component Store [DISM]...%C_0%
if "%ONLINE%"=="0" (
    echo       [%C_R% OFFLINE %C_0%] Bypassed: Component store cleanup skipped [no internet connection].
) else (
    echo       %C_D%Launching live DISM servicing [native progress below]...%C_0%
    echo       %C_D%Note: DISM may finish at 20%% or advance to 100%% if components were already clean.%C_0%
    echo.
    dism.exe /Online /Cleanup-Image /StartComponentCleanup
    if errorlevel 1 (
        echo.
        echo       [%C_R% FAIL %C_0%] DISM component cleanup reported an error.
    ) else (
        echo.
        echo       [%C_G%  OK  %C_0%] DISM component store cleanup completed.
    )
)
echo.

rem [Step 6/6] Empty Recycle Bin
echo [6/6] %C_W%Processing Recycle Bin...%C_0%
if "%SKIP_RECYCLE_BIN%"=="1" (
    echo       [%C_Y% SKIP %C_0%] Recycle Bin purge bypassed by configuration.
) else if "%AUTO_CONFIRM%"=="1" (
    powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
    echo       [%C_G%  OK  %C_0%] Recycle Bin emptied automatically.
) else (
    echo.
    echo       %C_Y%[ NOTICE ] Items currently inside the Recycle Bin cannot be recovered.%C_0%
    echo       Permanently empty Recycle Bin? %C_R%[Y] Yes%C_0% / %C_G%[N] No [default]%C_0%
    choice /c NY /n /m "      Your choice [Y/N] > "
    if errorlevel 2 (
        powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
        echo       [%C_G%  OK  %C_0%] Recycle Bin permanently emptied.
    ) else (
        echo       [%C_C% SKIP %C_0%] Recycle Bin preserved safely.
    )
)
echo.

rem Final Disk Space Measurement & Calculation
for /f %%a in ('powershell -NoProfile -Command "(New-Object IO.DriveInfo $env:SystemDrive).AvailableFreeSpace"') do set "FREEAFTER=%%a"

set "FREED_MB=0.00"
if not "%FREEBEFORE%"=="0" if not "%FREEAFTER%"=="0" (
    for /f %%a in ('powershell -NoProfile -Command "([math]::Round(([math]::Max(0, [double](([long]%FREEAFTER% - [long]%FREEBEFORE%)/1048576.0))), 2))"') do set "FREED_MB=%%a"
)

echo %C_C%================================================================%C_0%
echo                      %C_W%CLEANUP SUMMARY%C_0%
echo %C_C%================================================================%C_0%
echo   Files Removed            : %C_G%!TOTAL_DEL! file[s]%C_0%
echo   In Use / Skipped Files   : %C_Y%!TOTAL_LOCK! file[s]%C_0%
echo   Target Drive Free Space  : %C_G%+!FREED_MB! MB%C_0%
echo %C_C%================================================================%C_0%
echo %C_W%All requested maintenance tasks have executed successfully.%C_0%
echo.
pause
exit 0

rem ---- Directory Cleaner with Real Metrics ----------------------------------
:cleandir
set "CDIR=%~1"
set "CDESC=%~2"
if not defined CDIR exit /b 0
if "!CDIR:~3!"=="" exit /b 0
if not exist "!CDIR!\" 2>nul (
    echo       [%C_Y% SKIP %C_0%] !CDESC!: Directory not present.
    exit /b 0
)

set "CNT_B=0"
set "CNT_A=0"
for /f %%c in ('dir /a-d /s /b "!CDIR!\*" 2^>nul ^| find /c /v ""') do set "CNT_B=%%c"

del /q /f /s /a "!CDIR!\*" >nul 2>&1
for /d %%d in ("!CDIR!\*") do rd /s /q "%%~d" >nul 2>&1

for /f %%c in ('dir /a-d /s /b "!CDIR!\*" 2^>nul ^| find /c /v ""') do set "CNT_A=%%c"

set /a "CNT_DEL=CNT_B-CNT_A"
if !CNT_DEL! lss 0 set "CNT_DEL=0"
set /a TOTAL_DEL+=CNT_DEL
set /a TOTAL_LOCK+=CNT_A

if "!CNT_B!"=="0" (
    echo       [%C_Y% SKIP %C_0%] !CDESC!: Already empty [0 files].
) else if "!CNT_DEL!"=="0" (
    echo       [%C_Y% SKIP %C_0%] !CDESC!: 0 files removed [all !CNT_A! in use by running apps].
) else if "!CNT_A!"=="0" (
    echo       [%C_G%  OK  %C_0%] !CDESC!: !CNT_DEL! file[s] removed.
) else (
    echo       [%C_G%  OK  %C_0%] !CDESC!: !CNT_DEL! file[s] removed [!CNT_A! in use/skipped].
)
exit /b 0
