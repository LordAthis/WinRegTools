[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   WinRegTools - MODERN MOD (NT6+) " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "0. Mind - Az összes pont végrehajtása, sorban"
    Write-Host "1. Hosszú nevek (LongPaths) kezelése"
    Write-Host "2. Lapozófájl ürítés (SwapDelete) kezelése"
    Write-Host "3. RPC Hiba javítása"
    Write-Host "4. WinSxS Hiba javítása-takarítása (Feleslegesen felhalmozott telepítő fájlok törlése"
    Write-Host "5. Bring Keresések Letíltása"
    Write-Host "6. Indexelés Letiíltása"
    Write-Host "7. Bring StartMenüből kitíltásaa"
    Write-Host "8. Telemertia Letíltása"
    Write-Host "9. KB Checker - Windows Frissítések elemzése (Hiányzó fontos, és Felesleges, mert káros)"
    Write-Host "10. Visszaállítási pont létrehozása"
    Write-Host "X. Kilépés" -ForegroundColor Red
    Write-Host "----------------------------------------"
}

do {
    Show-Menu
    $choice = Read-Host "Válassz opciót"
    switch ($choice) {
        "1" { & "$PSScriptRoot\LongPaths_On_Off.ps1" }
        "2" { & "$PSScriptRoot\SwapDeleteToShutdown.ps1" }
        "3" { & "$PSScriptRoot\RPCHelper_Fix.ps1" }
        "4" { & "$PSScriptRoot\Clean-WinSxS.ps1" }
        "5" { & "$PSScriptRoot\Disable-BingSearch.ps1" }
        "6" { & "$PSScriptRoot\Disable-Indexing.ps1" }
        "7" { & "$PSScriptRoot\Disable-StartMenuBring.ps1" }
        "8" { & "$PSScriptRoot\Disable-Telemerty.ps1" }
        "9" { & "$PSScriptRoot\KB_Checker.ps1" }
        "10" { & "$PSScriptRoot\Create-RestorePoint.ps1" }
        "x" { exit }
    }
} while ($true)
