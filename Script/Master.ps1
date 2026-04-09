[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   WinRegTools - MODERN MOD (NT6+) " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "1. Hosszú nevek (LongPaths) kezelése"
    Write-Host "2. Lapozófájl ürítés (SwapDelete) kezelése"
    Write-Host "3. RPC Hiba javítása"
    Write-Host "3. Kilépés"
    Write-Host "----------------------------------------"
}

do {
    Show-Menu
    $choice = Read-Host "Válassz opciót"
    switch ($choice) {
        "1" { & "$PSScriptRoot\LongPaths_On_Off.ps1" }
        "2" { & "$PSScriptRoot\SwapDeleteToShutdown.ps1" }
        "3" { & "$PSScriptRoot\RPCHelper_Fix.ps1" }
        "4" { exit }
    }
} while ($true)
