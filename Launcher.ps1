# WinRegTools - Launcher.ps1
# Gyökérbe kerül, a scriptek a /Scripts/ mappában vannak.

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
    Write-Host "==============================================================================================" -ForegroundColor Cyan
    Write-Host "                                   WinRegTools - LordAthis                            " -ForegroundColor Cyan
    Write-Host "==============================================================================================" -ForegroundColor Cyan
    Write-Host " A  AJANLOTT [Nepszeru, Legfontosabb] beallitasok inditasa" -ForegroundColor Green
    Write-Host " K  Az 'A'-bol kimaradt, nekem fontos, szerintem jo"  -ForegroundColor Green
    Write-Host " B  Az 'A' + 'K' egyben"  -ForegroundColor Green
    Write-Host " T  Teljeskoru (Minden fontos pont, javitassal eltavolitas es visszatelepites)" -ForegroundColor Green

    Write-Host "`n ELOKESZITES " -ForegroundColor Yellow
    Write-Host " 0   Regi Visszaallitasi pontok torlese (csak az utolso marad)"
    Write-Host " 1   Napi tobb Visszaallitasi pont engedelyezese"
    Write-Host " 2   Visszaallitasi pont letrehozasa [A legvegen is erdemes meg egyet letrehozni!]"
    Write-Host "          Ehhez pedig be kell kapcsolni a napi tobb visszaallitasi pont engedelyezeset [1]!" -ForegroundColor Red
    
    Write-Host "`n RENDSZER ES TELJESITMENY OPTIMALIZALAS " -ForegroundColor Yellow
    Write-Host " 3   Hosszu nevek engedelyezese [LongPaths]"
    Write-Host " 4   Gyorsitja az Intezot: fajlkiterjesztes, 'Ez a gep' alapertelmezett a Gyorseleres helyett"
    Write-Host " 5   Edge Letiltasa es Torlese"    
    Write-Host " 6   Bing Keresesek Letiltasa"
    Write-Host " 7   Bing Start Menubol kitiltasa"
    Write-Host " 8   OneDrive eltavolitasa a rendszerbol"
    Write-Host " 9   Letiltja az automatikusan telepulo alkalmazasok [Candy Crush, Stb]"
    Write-Host " 10  A talcarol eltunteti az idojarast/hireket (Widgets)"
    Write-Host " 11  Telemetria Letiltasa"
    Write-Host " 12 Cortana Asszisztens teljes eltavolitasa"
    Write-Host " 13 Copilot es beepitett AI modulok eltavolitasa"
    Write-Host " 14 Edge WebView2 Telemetria es hatter-frissitesek letiltasa"
    
    Write-Host "`n TAKARITAS ES KARBANTARTAS  " -ForegroundColor Yellow
    Write-Host " 15  TEMP konyvtarak egysegesitese (C:\Temp) - a szemet felhalmozodasanak megelozese"  
    Write-Host " 16  A Windows Update Cache torlese"
    Write-Host " 17  WinSxS takaritas es Rendszerjavitas"
    Write-Host " 18  Log-takaritas - 30 napnal regebbi logok torlese"
    
    Write-Host "`n SPECIALIS JAVITASOK   " -ForegroundColor Yellow
    Write-Host " 19  RPC Hiba javitasa"
    Write-Host " 19A RPC Hiba Drasztikus javitasa, hibas Driver szolgaltatasok torlesevel" -ForegroundColor Magenta
    Write-Host " 5A  Edge WebView2 drasztikus teljes torlese (MS Office/Teams/Stb osszeomolhat!)" -ForegroundColor Red
    Write-Host " 20 Edge WebView2 Runtime tiszta ujratelepitese, biztositva a telemetria, kovetes tiltva!" -ForegroundColor Green
    Write-Host " 21  Lapozofajl urites leallitaskor [SwapDelete]"
    Write-Host " 22  Indexeles Letiltasa"
    Write-Host " 23  KB Checker - Frissitesek elemzese"
    Write-Host " 24  KB Checker - Aktualizalasa"
    Write-Host "`n A MUVELETEK BEFEJEZESEKOR ISMET ERDEMES VISSZAALLITASI PONTOT LETREHOZNI!!! [2-es pont]" -ForegroundColor Yellow
    
    Write-Host " X  Kilepes" -ForegroundColor Red
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
    Write-Host " CSAK SPECIALIS ESETBEN SZUKSEGES!!!" -ForegroundColor Yellow
    Write-Host " Y  MEGHAJTO (USB) IRASVEDELEM KEZELO - Felold es Zarol"
    Write-Host "----------------------------------------" -ForegroundColor DarkGray
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
    # - - - - - -   AKTUALIS RENDSZERALLAPOT   - - - - - -
    Write-Host ""
    Write-Host "- - - - - - - - - - - - - - - - -  AKTUALIS RENDSZERALLAPOT  - - - - - - - - - - - - - - - - -" -ForegroundColor DarkCyan
    
    # 1. RPC Ellenőrzés
    $rpc = Get-Service RpcSs -ErrorAction SilentlyContinue
    $rpcStatusText = if ($rpc) { $rpc.Status } else { "Nem talalható" }
    $rpcColor = if ($rpcStatusText -eq 'Running') { "Green" } else { "Red" }

    # 2. RP Limit Ellenőrzés
    $rpFreq = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
    $rpLimitVal = $rpFreq.SystemRestorePointCreationFrequency
    
    $rpText = "KORLATOZVA"
    $rpColor = "Yellow"
    if ($null -ne $rpLimitVal -and $rpLimitVal -eq 0) {
        $rpText = "FELOLDVA (0)"
        $rpColor = "Green"
    }

    # 3. KB Log dátum
    $lastKB = Get-ChildItem -Path $LogFolder -Filter "*KB_Checker.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $kbDate = if ($lastKB) { $lastKB.LastWriteTime.ToString("yyyy-MM-dd HH:mm") } else { "Nincs log" }

    # 4. Az első három pont kiiratása (1.-2.-3.)
    Write-Host "  RPC Szolgaltatas: " -NoNewline;
    Write-Host $rpcStatusText -ForegroundColor $rpcColor -NoNewline;

    Write-Host " - RPC Idokorlat: " -NoNewline;
    Write-Host $rpText -ForegroundColor $rpColor -NoNewline;

    Write-Host " - Utolso KB-check: " -NoNewline;
    Write-Host $kbDate -ForegroundColor Cyan

    Show-Menu # Ez írja ki a listát
    $choice = Read-Host "Valassz opciot (0-24 / A,X)"

    switch ($choice.ToUpper()) {
        "A" {
            Write-SessionLog "AJANLOTT beallitasok inditasa"
            # 1. Előkészítés
            Run-Script "Keep-LastRestorePoint.ps1"
            Run-Script "RestorePoint_24HourLimitRelease.ps1"
            Run-Script "Create-RestorePoint.ps1"
            # 2. Rendszer Teljesítmény és Optimalizálás
            Run-Script "LongPaths_On_Off.ps1"
            Run-Script "Optimize-Explorer.ps1"
            Run-Script "DisableAndClean-Edge.ps1"
            Run-Script "Disable-BingSearch.ps1"
            Run-Script "Disable-StartMenuBing.ps1"
            Run-Script "Disable-OneDrive.ps1"
            Run-Script "Disable-ConsumerFeatures.ps1"
            Run-Script "Disable-Widgets-News.ps1"
            Run-Script "Disable-Telemetry.ps1"
            Run-Script "DisableAndClean-Cortana.ps1"
            Run-Script "DisableAndClean-Copilot.ps1"
            Run-Script "Disable-WebView2Telemetry.ps1"
            # 3. Tisztítás és Karbantartás
            Run-Script "TempOptimizer.ps1"
            Run-Script "Clean-UpdateCache.ps1"
            Run-Script "Clean-WinSxS.ps1"
            Run-Script "Clean-Logs.ps1"
            # 4. Speciális Javítások
            Run-Script "RPCHelper_Fix.ps1"
            Run-Script "SwapDeleteToShutdown.ps1"
            # 5. Biztonság
            Run-Script "Create-RestorePoint.ps1"
            Write-Host "`n[KESZ] Az ajanlott beallitasok lefutottak!" -ForegroundColor Green
            Start-Sleep -Seconds 5
        }
        "K" {
            Write-SessionLog "KIMARADT (Szerintem jo) beallitasok inditasa"
            Run-Script "Disable-Indexing.ps1"
            Run-Script "KB_Checker.ps1"
            Run-Script "KB_Aktualizer.ps1"
        }
        "T" {
            Write-SessionLog "TELJESKORU drasztikus beallitasok es javitasok inditasa"
            # 1. Előkészítés
            Run-Script "Keep-LastRestorePoint.ps1"
            Run-Script "RestorePoint_24HourLimitRelease.ps1"
            Run-Script "Create-RestorePoint.ps1"
            # 2. Drasztikus Tisztítás (WebView2 legyalulása a tiszta alapokhoz)
            Run-Script "Remove-WebView2Telemetry.ps1"
            # 3. Rendszer Teljesítmény és Optimalizálás
            Run-Script "LongPaths_On_Off.ps1"
            Run-Script "Optimize-Explorer.ps1"
            Run-Script "DisableAndClean-Edge.ps1"
            Run-Script "Disable-BingSearch.ps1"
            Run-Script "Disable-StartMenuBing.ps1"
            Run-Script "Disable-OneDrive.ps1"
            Run-Script "Disable-ConsumerFeatures.ps1"
            Run-Script "Disable-Widgets-News.ps1"
            Run-Script "Disable-Telemetry.ps1"
            Run-Script "DisableAndClean-Cortana.ps1"
            Run-Script "DisableAndClean-Copilot.ps1"
            # 4. Tisztítás és Karbantartás
            Run-Script "TempOptimizer.ps1"
            Run-Script "Clean-UpdateCache.ps1"
            Run-Script "Clean-WinSxS.ps1"
            Run-Script "Clean-Logs.ps1"
            # 5. Speciális és Drasztikus Javítások (RPCHelper drasztikus verzió)
            Run-Script "RPCHelper_Drastic_Fix.ps1"
            Run-Script "SwapDeleteToShutdown.ps1"
            Run-Script "Disable-Indexing.ps1"
            # 6. WebView2 Tiszta Újratelepítése a láncolat végén
            Run-Script "Restore-WebView2Runtime.ps1"
            # 7. Biztonság
            Run-Script "Create-RestorePoint.ps1"
            Write-Host "`n[KESZ] A teljeskoru drasztikus javitasok lefutottak!" -ForegroundColor Green
            Start-Sleep -Seconds 5
        }
        "0"   { Run-Script "Keep-LastRestorePoint.ps1" }
        "1"   { Run-Script "RestorePoint_24HourLimitRelease.ps1" }
        "2"   { Run-Script "Create-RestorePoint.ps1" }
        "3"   { Run-Script "LongPaths_On_Off.ps1" }
        "4"   { Run-Script "Optimize-Explorer.ps1" }
        "5"   { Run-Script "DisableAndClean-Edge.ps1" }
        "5A"  { Run-Script "Remove-WebView2Telemetry.ps1" }
        "6"   { Run-Script "Disable-BingSearch.ps1" }
        "7"   { Run-Script "Disable-StartMenuBing.ps1" }
        "8"   { Run-Script "Disable-OneDrive.ps1" }
        "9"   { Run-Script "Disable-ConsumerFeatures.ps1" }
        "10"  { Run-Script "Disable-Widgets-News.ps1" }
        "11"  { Run-Script "Disable-Telemetry.ps1" }
        "12" { Run-Script "DisableAndClean-Cortana.ps1" }
        "13" { Run-Script "DisableAndClean-Copilot.ps1" }
        "14" { Run-Script "Disable-WebView2Telemetry.ps1" }
        "15"  { Run-Script "TempOptimizer.ps1" }
        "16"  { Run-Script "Clean-UpdateCache.ps1" }
        "17"  { Run-Script "Clean-WinSxS.ps1" }
        "18"  { Run-Script "Clean-Logs.ps1" }
        "19"  { Run-Script "RPCHelper_Fix.ps1" }
        "19A" { Run-Script "RPCHelper_Drastic_Fix.ps1" }
        "20" { Run-Script "Restore-WebView2Runtime.ps1" }
        "21"  { Run-Script "SwapDeleteToShutdown.ps1" }
        "22"  { Run-Script "Disable-Indexing.ps1" }
        "23"  { Run-Script "KB_Checker.ps1" }
        "24"  { Run-Script "KB_Aktualizer.ps1" }
        "25"  { Write-Host " Ez a menupont meg nincs implementalva." -ForegroundColor DarkGray }
        "26"  { Write-Host " Ez a menupont meg nincs implementalva." -ForegroundColor DarkGray }
        "27"  { Write-Host " Ez a menupont meg nincs implementalva." -ForegroundColor DarkGray }
        "Y"   { Run-Script "RemoveDiskProtect.ps1" }
        "X"   {
            Write-SessionLog "Kilepes"
            Write-Host "Viszlat!" -ForegroundColor Cyan
            exit
        }
        default {
            Write-Host "  Ervenytelen valasztas: '$choice'" -ForegroundColor Red
        }
    }

} while ($true)
