@echo off
:: Rendszergazdai jog ellenőrzése és emelése CMD-ben
net session >nul 2>&1
if %errorLevel% == 0 (
    :: Ha már admin, indítja a PowerShellt bypass módban, láthatatlan profillal
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launcher.ps1"
) else (
    :: Ha nem admin, újraindítja magát rendszergazdaként
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
