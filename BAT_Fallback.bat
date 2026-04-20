@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
title XP/W7 BAT Mod (PS nelkul)

:: ============================================================
:: RTS Framework - BAT fallback szkriptek
:: XP-re es PS nelkuli W7-re
:: Verzio 1.0
::
:: Nem igenyel PowerShell-t!
:: reg add, sc, net stop, wusa parancsokat hasznal.
:: ============================================================

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] ADMINISZTRATORI JOG SZUKSEGES!
    echo     Jobbklikk - Futtatas rendszergazdakent
    pause
    exit /b 1
)

:: OS detektálás
for /f "tokens=2*" %%a in (
    'reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul'
) do set OS_NAME=%%b

for /f "tokens=2*" %%a in (
    'reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentVersion 2^>nul'
) do set OS_VER=%%b

cls
echo.
echo  =====================================================
echo   RTS Framework - BAT mod (PS nelkul)
echo   Rendszer: %OS_NAME%
echo   Verzio  : %OS_VER%
echo  =====================================================
echo.

:MENU
echo.
echo   1. Indexelo szolgaltatas letiltasa
echo   2. Telemetria / GWX tiltasok
echo   3. W7 Karos KB eltavolitas (wusa)
echo   4. Windows Search cache torles
echo   5. BITS / WU korlatozas
echo   0. Kilepes
echo.
set /p BAT_CHOICE=" Valasztas (0-5): "

if "%BAT_CHOICE%"=="1" goto DISABLE_INDEXING
if "%BAT_CHOICE%"=="2" goto DISABLE_TELEMETRY
if "%BAT_CHOICE%"=="3" goto REMOVE_HARMFUL_KB
if "%BAT_CHOICE%"=="4" goto CLEAN_WINSEARCH
if "%BAT_CHOICE%"=="5" goto LIMIT_WU
if "%BAT_CHOICE%"=="0" goto :EOF
goto MENU

:: ─── 1. Indexelő letiltása ────────────────────────────────────────────────────
:DISABLE_INDEXING
echo.
echo  [*] Indexelo (WSearch / cisvc) letiltasa...

:: Windows 7/Vista: WSearch
sc stop WSearch >nul 2>&1
sc config WSearch start= disabled >nul 2>&1
if %errorlevel%==0 (
    echo  [OK] WSearch letiltva
) else (
    echo  [--] WSearch nem talalhato (XP?)
)

:: Windows XP: cisvc (Indexing Service)
sc stop cisvc >nul 2>&1
sc config cisvc start= disabled >nul 2>&1
if %errorlevel%==0 (
    echo  [OK] cisvc (XP Indexing Service) letiltva
) else (
    echo  [--] cisvc nem talalhato
)

:: SearchIndexer.exe leállítás
taskkill /f /im SearchIndexer.exe >nul 2>&1
echo  [OK] SearchIndexer.exe leallitva (ha futott)

echo.
echo  KESZ! Indexelo letiltva.
pause
goto MENU

:: ─── 2. Telemetria tiltások ───────────────────────────────────────────────────
:DISABLE_TELEMETRY
echo.
echo  [*] Telemetria registry tiltasok...

:: DiagTrack letiltás
sc stop DiagTrack >nul 2>&1
sc config DiagTrack start= disabled >nul 2>&1
echo  [OK] DiagTrack kezelte

:: dmwappushservice letiltás
sc stop dmwappushservice >nul 2>&1
sc config dmwappushservice start= disabled >nul 2>&1
echo  [OK] dmwappushservice kezelte

:: Registry telemetria tiltás
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
echo  [OK] AllowTelemetry=0

reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
echo  [OK] DataCollection policy

:: W10/W11 hirdetési azonosító tiltás
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo  [OK] AdvertisingInfo tiltva

:: W7/W10: Windows Update OS upgrade tiltás
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v DisableOSUpgrade /t REG_DWORD /d 1 /f >nul 2>&1
echo  [OK] DisableOSUpgrade=1

echo.
echo  KESZ! Telemetria tiltasok alkalmazva.
pause
goto MENU

:: ─── 3. Káros KB eltávolítás ──────────────────────────────────────────────────
:REMOVE_HARMFUL_KB
echo.
echo  [*] W7 karos KB-k eltavolitas wusa.exe-vel...
echo  (Minden KB-hoz var a befejezesre - ez idot vehet igenybe!)
echo.

set KB_LIST=3035583 2952664 3068708 3022345 3075249 3080149 3021917 3044374 2990214

for %%k in (%KB_LIST%) do (
    echo  [-] KB%%k eltavolitas...
    wusa.exe /uninstall /kb:%%k /quiet /norestart >nul 2>&1
    if !errorlevel!==0 (
        echo      [OK] KB%%k eltavolitva
    ) else if !errorlevel!==3010 (
        echo      [OK] KB%%k eltavolitva (ujrainditas kell)
    ) else (
        echo      [--] KB%%k nem volt telepitve vagy hiba
    )
)

echo.
echo  KESZ! Ujrainditas ajanlott.
pause
goto MENU

:: ─── 4. Windows Search cache törlés ──────────────────────────────────────────
:CLEAN_WINSEARCH
echo.
echo  [*] Windows Search adatbazis torles...

sc stop WSearch >nul 2>&1
timeout /t 3 /nobreak >nul

:: Windows 7 Search DB helye
set SEARCH_DB=%ProgramData%\Microsoft\Search\Data\Applications\Windows
if exist "%SEARCH_DB%" (
    del /f /q "%SEARCH_DB%\*.edb" 2>nul
    del /f /q "%SEARCH_DB%\*.jrs" 2>nul
    del /f /q "%SEARCH_DB%\*.log" 2>nul
    echo  [OK] Search adatbazis file-ok torolve
) else (
    echo  [--] Search DB mappa nem talalhato
)

:: WU cache törlés
net stop wuauserv >nul 2>&1
net stop cryptSvc >nul 2>&1
net stop bits     >nul 2>&1

if exist "%SystemRoot%\SoftwareDistribution\Download" (
    rd /s /q "%SystemRoot%\SoftwareDistribution\Download" 2>nul
    md "%SystemRoot%\SoftwareDistribution\Download" 2>nul
    echo  [OK] SoftwareDistribution\Download torolve
)

net start wuauserv >nul 2>&1
net start cryptSvc >nul 2>&1
net start bits     >nul 2>&1

echo.
echo  KESZ! Cache torolve, szolgaltatasok ujrainditva.
pause
goto MENU

:: ─── 5. BITS / WU korlátozás ─────────────────────────────────────────────────
:LIMIT_WU
echo.
echo  [*] Windows Update beallitas: csak ertesito mod...

:: AUOptions: 2 = Notify before download
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" /v AUOptions /t REG_DWORD /d 2 /f >nul 2>&1
echo  [OK] AUOptions=2 (csak ertesito)

:: BITS korlátozás
sc config bits start= demand >nul 2>&1
echo  [OK] BITS: igeny szerinti inditas

:: NoAutoUpdate GPO
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
echo  [OK] NoAutoUpdate=1

echo.
echo  KESZ! WU csak manualis ellenorzesre all.
pause
goto MENU

endlocal
