# WinRegTools - Launcher.ps1
# Gyökerbe kerül, a scriptek a /Scripts/ mappában vannak.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Admin önfuttatás
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ScriptFolder = Join-Path $PSScriptRoot "Scripts"

# ─── LOG mappa létrehozása (ha még nincs) ─────────────────────────────────────
$LogFolder = Join-Path $PSScriptRoot "LOG"
if (-not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}

# ─── Launcher saját log ───────────────────────────────────────────────────────
$LauncherLog = Join-Path $LogFolder "$(Get-Date -Format 'yyyy-MM-dd')_Launcher_session.log"
function Write-SessionLog ([string]$msg) {
    "[$(Get-Date -Format 'HH:mm:ss')] $msg" | Out-File -FilePath $LauncherLog -Encoding UTF8 -Append
}
Write-SessionLog "=== Session indult | OS: $([Environment]::OSVersion.VersionString) | User: $($env:USERNAME)@$($env:COMPUTERNAME) ==="

# ─── Menü ─────────────────────────────────────────────────────────────────────
function Show-Menu {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   WinRegTools - LordAthis             " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " 0  Mind - Az osszes pont sorban" -ForegroundColor Yellow
    Write-Host " 1  Hosszu nevek (LongPaths)"
    Write-Host " 2  Lapozofajl urites (SwapDelete)"
    Write-Host " 3  RPC Hiba javitasa"
    Write-Host " 3a  RPC Hiba Drasztikus javitasa, hibas Driver szolgaltatasok torlesevel kiegeszitve"
    Write-Host " 4  A Windows Update Cache törlése (Lemezterület felszabadítása)"
    Write-Host " 5  WinSxS takaritas"
    Write-Host " 6  Bing Keresések Letiltasa"
    Write-Host " 7  Indexeles Letiltasa"
    Write-Host " 8  Bing Start Menubol kitiltasa"
    Write-Host " 9  Telemetria Letiltasa"
    Write-Host " 10  KB Checker - Frissitesek elemzese"
    Write-Host " 11  KB Checker - Aktualizálása"
    Write-Host " 12  Visszaallitasi pont letrehozasa"
    Write-Host " 13  Napi több 'Visszaallitasi pont' engedélyezése"
    Write-Host " X  Kilepes" -ForegroundColor Red
    Write-Host "----------------------------------------"
}

# ─── Script hívó ──────────────────────────────────────────────────────────────
function Run-Script ([string]$FileName) {
    $Path = Join-Path $ScriptFolder $FileName
    if (Test-Path $Path) {
        Write-Host ""
        Write-Host ">>> Futtatás: $FileName" -ForegroundColor Magenta
        Write-SessionLog "Indítás: $FileName"
        try {
            & $Path
            Write-Host ">>> Befejezve: $FileName" -ForegroundColor Green
            Write-SessionLog "Kész: $FileName"
        } catch {
            Write-Host ">>> HIBA ($FileName): $($_.Exception.Message)" -ForegroundColor Red
            Write-SessionLog "HIBA: $FileName | $($_.Exception.Message)"
        }
    } else {
        Write-Host "  [!!] Fájl nem talalhato: $Path" -ForegroundColor Red
        Write-SessionLog "Nem talalhato: $Path"
    }
    # Üzenetek maradnak, menü alájuk töltődik
    Write-Host ""
    Write-Host "Nyomj meg egy gombot a folytatashoz..." -ForegroundColor DarkGray
    $null = [Console]::ReadKey($true)
}

# ─── Főciklus ─────────────────────────────────────────────────────────────────
Clear-Host

do {
    Show-Menu
    $choice = Read-Host "Valassz opciót (0-10 / X)"

    switch ($choice.ToUpper()) {
        "0" {
            Write-SessionLog "Mind futtatasa indul"
            Run-Script "LongPaths_On_Off.ps1"
            Run-Script "SwapDeleteToShutdown.ps1"
            Run-Script "RPCHelper_Fix.ps1"
            Run-Script "Clean-UpdateCache.ps1"
            Run-Script "RestorePoint_24HourLimitRelease.ps1"
            Run-Script "Clean-UpdateCache.ps1"
            Run-Script "Clean-WinSxS.ps1"
            Run-Script "Disable-BingSearch.ps1"
            Run-Script "Disable-Indexing.ps1"
            Run-Script "Disable-StartMenuBing.ps1"
            Run-Script "Disable-Telemetry.ps1"
            Run-Script "KB_Checker.ps1"
            Run-Script "KB_Aktualizer.ps1"
            Run-Script "Create-RestorePoint.ps1"
        }
        "1"  { Run-Script "LongPaths_On_Off.ps1" }
        "2"  { Run-Script "SwapDeleteToShutdown.ps1" }
        "3"  { Run-Script "RPCHelper_Fix.ps1" }
        "3a"  { Run-Script "RPCHelper_Drastic_Fix.ps1" }
        "4"  { Run-Script "Clean-UpdateCache.ps1" }
        "5"  { Run-Script "Clean-WinSxS.ps1" }
        "6"  { Run-Script "Disable-BingSearch.ps1" }
        "7"  { Run-Script "Disable-Indexing.ps1" }
        "8"  { Run-Script "Disable-StartMenuBing.ps1" }
        "9"  { Run-Script "Disable-Telemetry.ps1" }
        "10"  { Run-Script "KB_Checker.ps1" }
        "11"  { Run-Script "KB_Aktualizer.ps1" }
        "12" { Run-Script "Create-RestorePoint.ps1" }
        "13" { Run-Script "RestorePoint_24HourLimitRelease.ps1" }
        "X"  {
            Write-SessionLog "Kilepes"
            Write-Host "Viszlat!" -ForegroundColor Cyan
            exit
        }
        default {
            Write-Host "  Ervenytelen valasztas: '$choice'" -ForegroundColor Red
        }
    }

} while ($true)
