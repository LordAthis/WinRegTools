@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1
title RTS Framework - Launcher

:: ============================================================
:: RTS Framework - Universal Launcher
:: LordAthis Szervizem/Boltom
:: Verziő: 1.0
::
:: Feladat: OS detektálás, PS ellenőrzés/ajánlás/telepítés,
::          majd meghívja a megfelelő PS1 vagy BAT szkriptet
::          admin joggal + ExecutionPolicy Bypass
:: ============================================================

:: ─── Admin jogosultság ellenőrzés ────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [!] Ez a szkript ADMINISZTRATORI JOGOT igenyel!
    echo  [!] Jobbklikk a fajlon: "Futtatas rendszergazdakent"
    echo.
    pause
    exit /b 1
)

:: ─── Ha már admin, és PS1 fájlnevet kapott argumentumként ────────────────────
:: Használat: RTS_Launcher.bat script.ps1
:: Ebben az esetben csak indítja a megadott PS1-et

if not "%~1"=="" (
    if /i "%~x1"==".ps1" (
        call :LAUNCH_PS1 "%~1"
        exit /b
    )
    if /i "%~x1"==".bat" (
        call "%~1"
        exit /b
    )
)

:: ─── Interaktív menü ──────────────────────────────────────────────────────────
cls
echo.
echo  ╔══════════════════════════════════════════════════╗
echo  ║       RTS Framework - Universal Launcher        ║
echo  ║       LordAthis Szervizem / Boltom              ║
echo  ╚══════════════════════════════════════════════════╝
echo.

:: ─── OS verzió detektálás ────────────────────────────────────────────────────
call :DETECT_OS

echo  Rendszer : !OS_NAME!
echo  Build    : !OS_BUILD!
echo  PS alap  : !PS_BUILTIN!
echo.

:: ─── PowerShell ellenőrzés ───────────────────────────────────────────────────
call :CHECK_PS
echo  PS talalt: !PS_FOUND! !PS_VERSION_STR!
echo.

:: ─── PS telepítés ajánlat (ha szükséges) ─────────────────────────────────────
if "!PS_FOUND!"=="NEM" (
    call :OFFER_PS_INSTALL
)

if "!PS_FOUND!"=="ELAVULT" (
    call :OFFER_PS_UPGRADE
)

:: ─── Szkript kiválasztó menü ─────────────────────────────────────────────────
:MENU
echo.
echo  ┌─────────────────────────────────────────────────┐
echo  │  Melyik szkriptet futtassam?                    │
echo  ├─────────────────────────────────────────────────┤
echo  │  1. Bing keresés letiltása                      │
echo  │  2. Start menü Bing / online javaslatok tiltás  │
echo  │  3. Telemetria letiltása                        │
echo  │  4. Indexelési szolgáltatás letiltása           │
echo  │  5. WinSxS / Component Store takarítás         │
echo  │  6. Rendszer-visszaállítási pont létrehozása    │
echo  │  7. W7 Mentő szkript (KB eltávolítás + javítás)│
echo  │  8. KB ellenőrző / frissítés kezelő            │
echo  │  0. Kilépés                                     │
echo  └─────────────────────────────────────────────────┘
echo.
set /p CHOICE=" Valasztod (0-8): "

if "%CHOICE%"=="1" call :RUN_SCRIPT "01_Disable-BingSearch"
if "%CHOICE%"=="2" call :RUN_SCRIPT "02_Disable-StartMenuBing"
if "%CHOICE%"=="3" call :RUN_SCRIPT "03_Disable-Telemetry"
if "%CHOICE%"=="4" call :RUN_SCRIPT "04_Disable-Indexing"
if "%CHOICE%"=="5" call :RUN_SCRIPT "05_Clean-WinSxS"
if "%CHOICE%"=="6" call :RUN_SCRIPT "06_Create-RestorePoint"
if "%CHOICE%"=="7" call :RUN_SCRIPT "07_W7_Rescue"
if "%CHOICE%"=="8" call :RUN_SCRIPT "08_KB_Checker"
if "%CHOICE%"=="0" goto :EOF

goto MENU

:: ══════════════════════════════════════════════════════════════════════════════
:: FÜGGVÉNYEK
:: ══════════════════════════════════════════════════════════════════════════════

:DETECT_OS
    set OS_NAME=Ismeretlen Windows
    set OS_BUILD=0
    set PS_BUILTIN=Nincs

    :: Windows verziő lekérése ver paranccsal (XP-től működik)
    for /f "tokens=4-5 delims=. " %%a in ('ver') do (
        set VER_MAJ=%%a
        set VER_MIN=%%b
    )

    :: WMI-val pontosabb lekérés (W7+)
    for /f "tokens=2 delims==" %%a in (
        'wmic os get version /value 2^>nul ^| find "="'
    ) do set OS_FULL_VER=%%a

    :: Vagy reg query Caption
    for /f "tokens=2*" %%a in (
        'reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul'
    ) do set OS_NAME=%%b

    for /f "tokens=2*" %%a in (
        'reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuild 2^>nul'
    ) do set OS_BUILD=%%b

    :: PS beépített verzió becslés OS alapján
    if "!VER_MAJ!"=="5" set PS_BUILTIN=Nincs (XP)
    if "!VER_MAJ!"=="6" (
        if "!VER_MIN!"=="0" set PS_BUILTIN=Nincs (Vista)
        if "!VER_MIN!"=="1" set PS_BUILTIN=2.0 (W7)
        if "!VER_MIN!"=="2" set PS_BUILTIN=3.0 (W8)
        if "!VER_MIN!"=="3" set PS_BUILTIN=4.0 (W8.1)
    )
    if "!VER_MAJ!"=="10" set PS_BUILTIN=5.1 (W10/W11)
goto :EOF

:CHECK_PS
    set PS_FOUND=NEM
    set PS_VERSION_STR=
    set PS_MAJOR=0

    :: PS5.1 helye (W10/W11 + WMF 5.1)
    if exist "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" (
        for /f "tokens=*" %%v in (
            '"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "$PSVersionTable.PSVersion.Major" 2^>nul'
        ) do set PS_MAJOR=%%v

        if !PS_MAJOR! geq 5 (
            set PS_FOUND=IGEN
            set PS_VERSION_STR=(verzio: !PS_MAJOR!.x - megfelelo)
        ) else if !PS_MAJOR! geq 4 (
            set PS_FOUND=IGEN
            set PS_VERSION_STR=(verzio: !PS_MAJOR!.x - megfelelo)
        ) else if !PS_MAJOR! geq 2 (
            set PS_FOUND=ELAVULT
            set PS_VERSION_STR=(verzio: !PS_MAJOR!.x - frissites ajanlott)
        ) else (
            set PS_FOUND=NEM
        )
    )
goto :EOF

:OFFER_PS_INSTALL
    echo.
    echo  ┌─────────────────────────────────────────────────────────┐
    echo  │  [!] PowerShell NEM talalhato ezen a rendszeren!       │
    echo  │                                                         │
    echo  │  A szkriptek PS nelkul korlatozott modon futnak.       │
    echo  │  Ajanlott PS verzio telepitese:                        │
    echo  ├─────────────────────────────────────────────────────────┤
    if "!VER_MAJ!"=="5" (
        echo  │  Windows XP eseten: WMF 2.0 (PS 2.0)                  │
        echo  │  MINIMUM RAM: 512 MB                                    │
        echo  │  Letoltes: microsoft.com/download/details.aspx?id=16818 │
        echo  │  FONTOS: Csak SP3-on, es csak ha van eleg RAM!         │
    )
    if "!VER_MAJ!"=="6" if "!VER_MIN!"=="0" (
        echo  │  Windows Vista eseten: WMF 2.0 (PS 2.0)               │
        echo  │  Letoltes: microsoft.com/download/details.aspx?id=16818 │
    )
    echo  ├─────────────────────────────────────────────────────────┤
    echo  │  1. Folytatom PS nelkul (BAT mod)                       │
    echo  │  2. Megnyitom a letoltesi linket (ha van net)           │
    echo  │  0. Kilepes                                             │
    echo  └─────────────────────────────────────────────────────────┘
    echo.
    set /p PS_CHOICE=" Valasztas: "
    if "%PS_CHOICE%"=="2" (
        start "" "https://www.microsoft.com/download/details.aspx?id=16818"
        echo  [*] Telepites utan inditsd ujra ezt a szkriptet!
        pause
        exit /b
    )
    if "%PS_CHOICE%"=="0" exit /b
    :: Folytatás BAT módban
    set PS_FOUND=BAT_ONLY
goto :EOF

:OFFER_PS_UPGRADE
    echo.
    echo  ┌─────────────────────────────────────────────────────────┐
    echo  │  [!] PowerShell ELAVULT verzio talalhato (!PS_MAJOR!.x) │
    echo  ├─────────────────────────────────────────────────────────┤
    if "!VER_MAJ!"=="6" if "!VER_MIN!"=="1" (
        echo  │  Windows 7 - Ajanlott: WMF 4.0 (PS 4.0)               │
        echo  │  Legjobb  : WMF 5.1 (PS 5.1) - csak ha 1GB+ RAM van!  │
        echo  │  WMF 4.0  : microsoft.com/download/details.aspx?id=40855│
        echo  │  WMF 5.1  : microsoft.com/download/details.aspx?id=54616│
    )
    echo  ├─────────────────────────────────────────────────────────┤
    echo  │  1. Folytatom meglevo PS-sel (korlatok lehetnek)        │
    echo  │  2. Megnyitom a WMF 4.0 letoltesi oldalt                │
    echo  │  3. Megnyitom a WMF 5.1 letoltesi oldalt                │
    echo  │  0. Kilepes                                             │
    echo  └─────────────────────────────────────────────────────────┘
    echo.
    set /p UPG_CHOICE=" Valasztas: "
    if "%UPG_CHOICE%"=="2" (
        start "" "https://www.microsoft.com/download/details.aspx?id=40855"
        echo  [*] Telepites utan inditsd ujra ezt a szkriptet!
        pause
        exit /b
    )
    if "%UPG_CHOICE%"=="3" (
        start "" "https://www.microsoft.com/download/details.aspx?id=54616"
        echo  [*] Telepites utan inditsd ujra ezt a szkriptet!
        pause
        exit /b
    )
    if "%UPG_CHOICE%"=="0" exit /b
goto :EOF

:RUN_SCRIPT
    set SCRIPT_BASE=%~1
    set SCRIPT_DIR=%~dp0

    :: PS1 verzió próbálkozás
    set PS1_PATH=!SCRIPT_DIR!ps1\!SCRIPT_BASE!.ps1

    :: BAT fallback
    set BAT_PATH=!SCRIPT_DIR!bat\!SCRIPT_BASE!.bat

    if "!PS_FOUND!"=="IGEN" (
        if exist "!PS1_PATH!" (
            call :LAUNCH_PS1 "!PS1_PATH!"
            goto :EOF
        )
    )

    if "!PS_FOUND!"=="ELAVULT" (
        if exist "!PS1_PATH!" (
            echo.
            echo  [!] Elavult PS verzioval futtatom a szkriptet.
            echo  [!] Egyes funkciok nem mukodhetek!
            echo.
            call :LAUNCH_PS1 "!PS1_PATH!"
            goto :EOF
        )
    )

    :: BAT fallback
    if exist "!BAT_PATH!" (
        echo  [*] PS nem elerheto, BAT mod...
        call "!BAT_PATH!"
        goto :EOF
    )

    echo.
    echo  [!] A szkript nem talalhato: !SCRIPT_BASE!
    echo  [!] Keresve: !PS1_PATH!
    echo  [!]          !BAT_PATH!
    echo.
    pause
goto :EOF

:LAUNCH_PS1
    :: Admin bypass indítás - ez a fő launcher-logika
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File %1
    if %errorlevel% neq 0 (
        echo.
        echo  [!] A szkript hibat adott vissza (kod: %errorlevel%)
        echo  [!] Ellenorizd a PS1 fajlt es a jogosultsagokat!
        echo.
    )
goto :EOF

endlocal
