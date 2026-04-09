@echo off
setlocal enabledelayedexpansion
title WinRegTools - Mester Script

:: Rendszer ellenorzése (Verzio lekérése)
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j

:: Ha Win 6.1 (Win7) vagy nagyobb, induljon a PowerShell modul
if "%VERSION:~0,3%" GEQ "6.1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "Script\Master_Script.ps1"
    exit /b
)

:RETR_MENU
cls
echo ========================================
echo   WinRegTools - RETRO MOD (Legacy OS)
echo ========================================
echo 1. 48-Bit LBA BE (EnableBigLba)
echo 2. 48-Bit LBA KI
echo 3. Lapozofajl torlese leallaskor BE
echo 4. Kilepes
echo ----------------------------------------
set /p opt="Valassz opciot: "

if "%opt%"=="1" regedit /s reg\48BitLBA_On.reg & echo Keszi! & pause & goto RETRO_MENU
if "%opt%"=="2" regedit /s reg\48BitLBA_Off.reg & echo Kesz! & pause & goto RETRO_MENU
if "%opt%"=="3" regedit /s reg\SwapDeleteToShutdown.reg & echo Kesz! & pause & goto RETRO_MENU
if "%opt%"=="4" exit
goto RETRO_MENU
