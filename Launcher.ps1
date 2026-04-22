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
    Write-Host " A  AJANLOTT (Nepszeru) beallitasok inditasa"-ForegroundColor Green
    Write-Host " 1  Hosszu nevek (LongPaths)"
    Write-Host " 2  Lapozofajl urites (SwapDelete)"
    Write-Host " 3  RPC Hiba javitasa"
    Write-Host " 3A  RPC Hiba Drasztikus javitasa, hibas Driver szolgaltatasok torlesevel kiegeszitve" -ForegroundColor Magenta
    Write-Host " 4  A Windows Update Cache torlese (Lemezterulet felszabaditasa) - Az 5-os pont futtatása esetén felesleges!" -ForegroundColor Magenta
    Write-Host " 5  WinSxS takaritas es Rendszerjavitas"
    Write-Host " 6  Bing Keresések Letiltasa"
    Write-Host " 7  Indexeles Letiltasa"
    Write-Host " 8  Bing Start Menubol kitiltasa"
    Write-Host " 9  Telemetria Letiltasa"
    Write-Host " 10  KB Checker - Frissitesek elemzese"
    Write-Host " 11  KB Checker - Aktualizalasa"
    Write-Host " 15  A talcarol eltunteti az idojarast/hireket"
    Write-Host " 16  Gyorsitja az Intezot: fajlkiterjesztesek mutatasa, 'Ez a gep' az alapertelmezett a Gyorseleres helyett"
    Write-Host " 17  Letiltja az automatikusan telepulo 'Candy Crush' es egyeb szemeteket"
    Write-Host " 18  "
    Write-Host " 19  "
    Write-Host " 20  "
    Write-Host " 21  "
    Write-Host " 12  Log-takaritas (30 napnal regebbi logok torlese)"
    Write-Host " 13  Napi tobb 'Visszaallitasi pont' engedelyezese"
    Write-Host " 14  Visszaallitasi pont letrehozasa"
    Write-Host " X  Kilepes" -ForegroundColor Red
    Write-Host "----------------------------------------"
}

# ─── Script hívó ──────────────────────────────────────────────────────────────
function Run-Script ([string]$FileName) {
    $Path = Join-Path $ScriptFolder $FileName
    if (Test-Path $Path) {
        Write-Host ""
        Write-Host ">>> Futtatas: $FileName" -ForegroundColor Magenta
        Write-SessionLog "Inditas: $FileName"
        try {
            & $Path
            Write-Host ">>> Befejezve: $FileName" -ForegroundColor Green
            Write-SessionLog "Kesz: $FileName"
        } catch {
            Write-Host ">>> HIBA ($FileName): $($_.Exception.Message)" -ForegroundColor Red
            Write-SessionLog "HIBA: $FileName | $($_.Exception.Message)"
        }
    } else {
        Write-Host "  [!!] Fajl nem talalhato: $Path" -ForegroundColor Red
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
    # --- AKTUALIS RENDSZERALLAPOT (Javított) ---
    Write-Host "--- AKTUALIS RENDSZERALLAPOT ---" -ForegroundColor DarkCyan
    
    # 1. RPC Ellenőrzés
    $rpc = Get-Service RpcSs -ErrorAction SilentlyContinue
    $rpcStatusText = if ($rpc) { $rpc.Status } else { "Nem talalható" }
    $rpcColor = if ($rpcStatusText -eq 'Running') { "Green" } else { "Red" }
    Write-Host "  RPC Szolgaltatas : " -NoNewline; Write-Host $rpcStatusText -ForegroundColor $rpcColor

    # 2. RP Limit Ellenőrzés
    $rpFreq = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
    $rpLimitVal = $rpFreq.SystemRestorePointCreationFrequency
    
    $rpText = "KORLATOZVA"
    $rpColor = "Yellow"
    if ($null -ne $rpLimitVal -and $rpLimitVal -eq 0) {
        $rpText = "FELOLDVA (0)"
        $rpColor = "Green"
    }
    Write-Host "  RP Idokorlat    : " -NoNewline; Write-Host $rpText -ForegroundColor $rpColor

    # 3. KB Log dátum
    $lastKB = Get-ChildItem -Path $LogFolder -Filter "*KB_Checker.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $kbDate = if ($lastKB) { $lastKB.LastWriteTime.ToString("yyyy-MM-dd HH:mm") } else { "Nincs log" }
    Write-Host "  Utolso KB-check : " -NoNewline; Write-Host $kbDate -ForegroundColor Cyan
    Write-Host ""


    Show-Menu # Ez írja ki a listát
    $choice = Read-Host "Valassz opciot (0-10 / X)"

    switch ($choice.ToUpper()) {
        "0" {
            Write-SessionLog "Az osszes futtatasa indul"
            Run-Script "LongPaths_On_Off.ps1"
            Run-Script "SwapDeleteToShutdown.ps1"
            Run-Script "RPCHelper_Fix.ps1"
            Run-Script "RestorePoint_24HourLimitRelease.ps1"
            Run-Script "Clean-UpdateCache.ps1"
            Run-Script "Clean-WinSxS.ps1"
            Run-Script "Disable-BingSearch.ps1"
            Run-Script "Disable-Indexing.ps1"
            Run-Script "Disable-StartMenuBing.ps1"
            Run-Script "Disable-Telemetry.ps1"
            Run-Script "KB_Checker.ps1"
            Run-Script "KB_Aktualizer.ps1"
            Run-Script "Clean-Logs.ps1"
            Run-Script "Create-RestorePoint.ps1"
        }
        "A" {
            Write-SessionLog "AJANLOTT (Nepszeru) beallitasok inditasa"
            # 1. Előkészítés
            Run-Script "RestorePoint_24HourLimitRelease.ps1"
            # 2. Optimalizálás
            Run-Script "LongPaths_On_Off.ps1"
            Run-Script "Disable-BingSearch.ps1"
            Run-Script "Disable-Telemetry.ps1"
            Run-Script "Optimize-Explorer.ps1"
            Run-Script "Disable-ConsumerFeatures.ps1"
            # 3. Tisztítás
            Run-Script "Clean-UpdateCache.ps1"
            Run-Script "Clean-WinSxS.ps1"
            # 4. Biztonság
            Run-Script "Create-RestorePoint.ps1"
            Write-Host "`n[KESZ] Az ajanlott beallitasok lefutottak!" -ForegroundColor Green
            Start-Sleep -Seconds 5
        }
        "1"  { Run-Script "LongPaths_On_Off.ps1" }
        "2"  { Run-Script "SwapDeleteToShutdown.ps1" }
        "3"  { Run-Script "RPCHelper_Fix.ps1" }
        "3A"  { Run-Script "RPCHelper_Drastic_Fix.ps1" }
        "4"  { Run-Script "Clean-UpdateCache.ps1" }
        "5"  { Run-Script "Clean-WinSxS.ps1" }
        "6"  { Run-Script "Disable-BingSearch.ps1" }
        "7"  { Run-Script "Disable-Indexing.ps1" }
        "8"  { Run-Script "Disable-StartMenuBing.ps1" }
        "9"  { Run-Script "Disable-Telemetry.ps1" }
        "10"  { Run-Script "KB_Checker.ps1" }
        "11"  { Run-Script "KB_Aktualizer.ps1" }
        "12" { Run-Script "Clean-Logs.ps1" }
        "13" { Run-Script "RestorePoint_24HourLimitRelease.ps1" }
        "14" { Run-Script "Create-RestorePoint.ps1" }
        "15" { Run-Script "Disable-Widgets-News.ps1" }
        "16" { Run-Script "Optimize-Explorer.ps1" }
        "17" { Run-Script "Disable-ConsumerFeatures.ps1" }
        "18" { Run-Script "" }
        "19" { Run-Script "" }
        "20" { Run-Script "" }
        "21" { Run-Script "" }
        "22" { Run-Script "" }
        "23" { Run-Script "" }
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
