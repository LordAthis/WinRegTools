# Kódolás kényszerítése az aktuális munkamenetben
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Ez a trükk: megmondjuk a PowerShellnek, hogy minden scriptet UTF8-ként olvasson be a lemezről
$PSDefaultParameterValues['*:Encoding'] = 'utf8'


[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# Elérési út definiálása (mivel a gyökérbe került, a scriptek a /Scripts-ben vannak)
$ScriptFolder = Join-Path $PSScriptRoot "Scripts"

function Show-Menu {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   WinRegTools - MODERN MOD (NT6+) " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "0. Mind - Az összes pont végrehajtása sorban" -ForegroundColor Yellow
    Write-Host "1. Hosszú nevek (LongPaths) kezelése"
    Write-Host "2. Lapozófájl ürítés (SwapDelete) kezelése"
    Write-Host "3. RPC Hiba javítása"
    Write-Host "4. WinSxS Hiba javítása-takarítása"
    Write-Host "5. Bing Keresések Letiltása"
    Write-Host "6. Indexelés Letiltása"
    Write-Host "7. Bing StartMenüből kitiltása"
    Write-Host "8. Telemetria Letiltása"
    Write-Host "9. KB Checker - Windows Frissítések elemzése"
    Write-Host "10. Visszaállítási pont létrehozása"
    Write-Host "X. Kilépés" -ForegroundColor Red
    Write-Host "----------------------------------------"
}

# Segédfüggvény a scriptek hívásához
function Run-Script ([string]$FileName) {
    $Path = Join-Path $ScriptFolder $FileName
    if (Test-Path $Path) {
        Write-Host "`n>>> Futtatás: $FileName..." -ForegroundColor Magenta
        & $Path
        Write-Host ">>> Befejezve: $FileName" -ForegroundColor Green
    } else {
        Write-Warning "Hiba: A fájl nem található: $Path"
    }
}

# Tisztítás csak az indításkor
Clear-Host

do {
    Show-Menu
    $choice = Read-Host "Válassz opciót"
    
    switch ($choice) {
        "0" { 
            # Sorrendben lefuttat mindent (kivéve a 9-es elemzőt és 10-es pontot, ha akarod)
            Run-Script "LongPaths_On_Off.ps1"
            Run-Script "SwapDeleteToShutdown.ps1"
            Run-Script "RPCHelper_Fix.ps1"
            Run-Script "Clean-WinSxS.ps1"
            Run-Script "Disable-BingSearch.ps1"
            Run-Script "Disable-Indexing.ps1"
            Run-Script "Disable-StartMenuBring.ps1"
            Run-Script "Disable-Telemerty.ps1"
        }
        "1" { Run-Script "LongPaths_On_Off.ps1" }
        "2" { Run-Script "SwapDeleteToShutdown.ps1" }
        "3" { Run-Script "RPCHelper_Fix.ps1" }
        "4" { Run-Script "Clean-WinSxS.ps1" }
        "5" { Run-Script "Disable-BingSearch.ps1" }
        "6" { Run-Script "Disable-Indexing.ps1" }
        "7" { Run-Script "Disable-StartMenuBring.ps1" }
        "8" { Run-Script "Disable-Telemerty.ps1" }
        "9" { Run-Script "KB_Checker.ps1" }
        "10" { Run-Script "Create-RestorePoint.ps1" }
        "x" { exit }
        default { Write-Host "Érvénytelen választás!" -ForegroundColor Red }
    }

    # Megállítjuk a folyamatot, hogy olvasható legyen az eredmény
    Write-Host "`nA művelet véget ért. Nyomj meg egy gombot a menühöz való visszatéréshez..." -ForegroundColor Gray
    $null = [Console]::ReadKey($true)
    # Itt NEM hívunk Clear-Host-ot, így a menü alá fog töltődni az újabb kör, 
    # de ha túl sok a szöveg, a Show-Menu-be betehetsz egy elválasztót.

} while ($true)
