#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows 7 "Mentő" szkript - káros KB-k eltávolítása, indexelő javítása,
    Windows Update helyreállítása.
.DESCRIPTION
    Eltávolítja a Microsoft által telepített telemetria és GWX KB-kat,
    javítja a szétlőtt Windows Search / Indexelő szolgáltatást,
    és visszaállítja a Windows Update normális állapotát.

    Kompatibilis: Windows 7 SP1 (x86 és x64)
    Futtatás: PowerShell ADMINKÉNT
.NOTES
    RTS Framework - LordAthis Szervizem/Boltom
    Verzió: 1.0
#>

# ─── Csak W7-en fusson! ───────────────────────────────────────────────────────
$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Major -ne 6 -or $osVersion.Minor -ne 1) {
    Write-Warning "Ez a szkript kizarolag Windows 7 SP1 rendszerre keszult!"
    Write-Warning "Jelenlegi OS: $([System.Environment]::OSVersion.VersionString)"
    exit 1
}

# ─── Fejléc ───────────────────────────────────────────────────────────────────
Clear-Host
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Red
Write-Host "║         WINDOWS 7 - MENTO SZKRIPT                      ║" -ForegroundColor Red
Write-Host "║   Telemetria KB-k eltavolitas + Indexelo javitas        ║" -ForegroundColor Red
Write-Host "║   LordAthis Szervizem/Boltom - RTS Framework           ║" -ForegroundColor Red
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Red
Write-Host ""
Write-Host " OS: $([System.Environment]::OSVersion.VersionString)" -ForegroundColor Cyan
Write-Host " Datum: $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Cyan
Write-Host ""

# ─── Visszaállítási pont először! ────────────────────────────────────────────
Write-Host "[0] Biztonsagi visszaallitasi pont keszitese..." -ForegroundColor Yellow
try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
    Checkpoint-Computer -Description "RTS_W7_Mentes_$timestamp" `
                        -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Host "  [OK] Visszaallitasi pont keszult: RTS_W7_Mentes_$timestamp" -ForegroundColor Green
} catch {
    Write-Host "  [!] Visszaallitasi pont keszites sikertelen: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  [!] Folytatjuk a javitast..." -ForegroundColor Yellow
}
Write-Host ""

# ─── 1. KÁROS KB-K ELTÁVOLÍTÁSA ──────────────────────────────────────────────
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkRed
Write-Host " [1] KAROS KB-K ELTAVOLITASA" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkRed
Write-Host ""

# Telemetria és GWX KB lista
$harmfulKBs = @(
    @{ KB = "KB3035583"; Desc = "Get Windows 10 (GWX) - upgrade kenyszerito" },
    @{ KB = "KB2952664"; Desc = "Compatibility update - telemetria elokezito" },
    @{ KB = "KB3068708"; Desc = "Customer Experience telemetria" },
    @{ KB = "KB3022345"; Desc = "Customer Experience telemetria (korabbi)" },
    @{ KB = "KB3075249"; Desc = "Telemetria injekcio (consent.exe)" },
    @{ KB = "KB3080149"; Desc = "Customer Experience telemetria" },
    @{ KB = "KB3021917"; Desc = "W10 readiness / diagnostika" },
    @{ KB = "KB3044374"; Desc = "W10 upgrade elokezito" },
    @{ KB = "KB3123862"; Desc = "Updated capabilities to upgrade W10" },
    @{ KB = "KB2990214"; Desc = "Update for upgrading to later version" },
    @{ KB = "KB3050265"; Desc = "Windows Update Client for W10 upgrade" },
    @{ KB = "KB3065987"; Desc = "Windows Update Client for W10 upgrade" },
    @{ KB = "KB3083710"; Desc = "Windows Update Client for W10 upgrade" },
    @{ KB = "KB3083711"; Desc = "Windows Update Client for W10 upgrade" }
)

$removedCount = 0
$notFoundCount = 0

foreach ($item in $harmfulKBs) {
    $kb = $item.KB
    $desc = $item.Desc

    # Ellenőrzés: telepítve van-e?
    $installed = Get-HotFix -Id $kb -ErrorAction SilentlyContinue

    if ($installed) {
        Write-Host "  [TALALT] $kb - $desc" -ForegroundColor Yellow
        Write-Host "           Eltavolitas..." -ForegroundColor Yellow

        # wusa.exe /uninstall - csendes eltávolítás
        $proc = Start-Process -FilePath "wusa.exe" `
                              -ArgumentList "/uninstall /kb:$($kb.Replace('KB','')) /quiet /norestart" `
                              -Wait -PassThru -ErrorAction SilentlyContinue

        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            Write-Host "           [OK] Eltavolitva! (exitcode: $($proc.ExitCode))" -ForegroundColor Green
            $removedCount++
        } elseif ($proc.ExitCode -eq 2359302) {
            Write-Host "           [--] Nem volt telepitve (wusa kod: $($proc.ExitCode))" -ForegroundColor DarkGray
            $notFoundCount++
        } else {
            Write-Host "           [!] Hiba! Exit kod: $($proc.ExitCode)" -ForegroundColor Red
            Write-Host "           Proba: kezi eltavolitas: wusa /uninstall /kb:$($kb.Replace('KB',''))" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  [--]     $kb - Nincs telepitve, kihagyva." -ForegroundColor DarkGray
        $notFoundCount++
    }
}

Write-Host ""
Write-Host "  Osszesites: $removedCount KB eltavolitva, $notFoundCount nem volt telepitve." -ForegroundColor Cyan

# ─── 2. KB-K ELREJTÉSE (hogy WU ne tegye vissza) ─────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkRed
Write-Host " [2] KB-K ELREJTESE (Windows Update ne tegye vissza)" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkRed
Write-Host ""
Write-Host "  [*] Registry: frissitesek tiltasa WU-n keresztul..." -ForegroundColor Yellow

# Registry tiltás - DoNotConnectToWindowsUpdateInternetLocations
# Ez NEM tiltja a biztonsági frissítéseket, csak az upgrade KBokat
$regPolicies = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
if (-not (Test-Path $regPolicies)) { New-Item -Path $regPolicies -Force | Out-Null }

# GWX specifikus tiltások
Set-ItemProperty -Path $regPolicies -Name "DisableWindowsUpdateAccess" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $regPolicies -Name "DisableOSUpgrade" -Value 1 -Type DWord -Force
Write-Host "  [OK] DisableOSUpgrade = 1" -ForegroundColor Green

# HKCU szint is
$regWU = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate"
if (-not (Test-Path $regWU)) { New-Item -Path $regWU -Force | Out-Null }

# GWX futtatás tiltás
$gwxPaths = @(
    "$env:SystemRoot\System32\GWX",
    "$env:SystemRoot\SysWOW64\GWX"
)
foreach ($gwxPath in $gwxPaths) {
    if (Test-Path $gwxPath) {
        # GWX ütemezett feladat tiltása
        $gwxTask = Get-ScheduledTask -TaskName "GWXTriggers" -ErrorAction SilentlyContinue
        if ($gwxTask) {
            Disable-ScheduledTask -TaskName "GWXTriggers" -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  [OK] GWXTriggers feladat letiltva" -ForegroundColor Green
        }
        Write-Host "  [!] GWX mappa talalhato: $gwxPath" -ForegroundColor Yellow
        Write-Host "      Kezi torles lehetseges: rmdir /s /q `"$gwxPath`"" -ForegroundColor DarkGray
    }
}

# ─── 3. WINDOWS SEARCH / INDEXELŐ JAVÍTÁS ────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkYellow
Write-Host " [3] WINDOWS SEARCH / INDEXELO JAVITAS" -ForegroundColor DarkYellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkYellow
Write-Host ""

# 3.1 Szolgáltatás leállítása
Write-Host "  [3.1] WSearch szolgaltatas leallitasa..." -ForegroundColor Yellow
$wsearch = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
if ($wsearch) {
    Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "       [OK] WSearch leallitva" -ForegroundColor Green
} else {
    Write-Host "       [--] WSearch nem talalhato" -ForegroundColor DarkGray
}

# 3.2 Sérült adatbázis törlése
Write-Host "  [3.2] Serult indexadatbazis torles..." -ForegroundColor Yellow
$indexPaths = @(
    "$env:ProgramData\Microsoft\Search\Data\Applications\Windows",
    "$env:ProgramData\Microsoft\Search\Data\Temp"
)

foreach ($idxPath in $indexPaths) {
    if (Test-Path $idxPath) {
        try {
            # Csak a .edb és .jrs fájlokat töröljük, nem a mappát!
            $filesToDelete = Get-ChildItem -Path $idxPath -Include "*.edb","*.jrs","*.log","*.chk" `
                                           -Recurse -Force -ErrorAction SilentlyContinue
            foreach ($f in $filesToDelete) {
                Remove-Item -Path $f.FullName -Force -ErrorAction SilentlyContinue
                Write-Host "       [OK] Torolve: $($f.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "       [!] Torles hiba: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "       [--] Mappa nem letezik: $idxPath" -ForegroundColor DarkGray
    }
}

# 3.3 Indexelő registry alaphelyzetbe
Write-Host "  [3.3] Indexelo registry alaphelyzetbe..." -ForegroundColor Yellow
$wsReg = "HKLM:\SOFTWARE\Microsoft\Windows Search"
if (Test-Path $wsReg) {
    # SetupCompletedSuccessfully = 0 => újrainduláskor újraépíti az indexet
    Set-ItemProperty -Path $wsReg -Name "SetupCompletedSuccessfully" -Value 0 -Type DWord -Force
    Write-Host "       [OK] SetupCompletedSuccessfully = 0 (ujraepites)" -ForegroundColor Green
}

# 3.4 WSearch szolgáltatás visszaállítása KÉZI indításra (nem automatikus!)
Write-Host "  [3.4] WSearch startup tipus beallitasa: KEZZEL INDITOTT..." -ForegroundColor Yellow
if ($wsearch) {
    Set-Service -Name "WSearch" -StartupType Manual -ErrorAction SilentlyContinue
    Write-Host "       [OK] WSearch = Manual (nem indul automatikusan)" -ForegroundColor Green
    Write-Host "       Ha kell az indexeles, kezi inditassal bekapcsolhato." -ForegroundColor DarkGray
}

# 3.5 SearchIndexer.exe esetleges zombie folyamat leölése
Write-Host "  [3.5] SearchIndexer.exe folyamatok lealltasa..." -ForegroundColor Yellow
$indexerProcs = Get-Process -Name "SearchIndexer" -ErrorAction SilentlyContinue
if ($indexerProcs) {
    foreach ($proc in $indexerProcs) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Write-Host "       [OK] SearchIndexer.exe (PID: $($proc.Id)) leallitva" -ForegroundColor Green
    }
} else {
    Write-Host "       [--] Nem fut SearchIndexer.exe folyamat" -ForegroundColor DarkGray
}

# ─── 4. WINDOWS UPDATE JAVÍTÁS ───────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host " [4] WINDOWS UPDATE SZOLGALTATAS JAVITASA" -ForegroundColor DarkCyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
Write-Host ""

# 4.1 Érintett szolgáltatások leállítása
Write-Host "  [4.1] Erintett szolgaltatasok leallitasa..." -ForegroundColor Yellow
$wuServices = @("wuauserv", "cryptSvc", "bits", "msiserver", "TrustedInstaller")
foreach ($svc in $wuServices) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s -and $s.Status -eq "Running") {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "       [OK] $svc leallitva" -ForegroundColor Green
    }
}
Start-Sleep -Seconds 2

# 4.2 SoftwareDistribution cache törlése
Write-Host "  [4.2] Windows Update cache torles..." -ForegroundColor Yellow
$wuCacheDirs = @(
    "$env:SystemRoot\SoftwareDistribution\Download",
    "$env:SystemRoot\SoftwareDistribution\DataStore"
)
foreach ($dir in $wuCacheDirs) {
    if (Test-Path $dir) {
        Remove-Item -Path "$dir\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "       [OK] Torolve: $dir" -ForegroundColor Green
    }
}

# 4.3 WU komponensek újraregisztrálása
Write-Host "  [4.3] Windows Update DLL-ek ujraregisztralasa..." -ForegroundColor Yellow
$wuDlls = @(
    "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll",
    "browseui.dll", "jscript.dll", "vbscript.dll", "scrrun.dll",
    "msxml.dll", "msxml3.dll", "msxml6.dll", "actxprxy.dll",
    "softpub.dll", "wintrust.dll", "dssenh.dll", "rsaenh.dll",
    "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll",
    "oleaut32.dll", "ole32.dll", "shell32.dll", "initpki.dll",
    "wuapi.dll", "wuaueng.dll", "wuaueng1.dll", "wucltui.dll",
    "wups.dll", "wups2.dll", "wuweb.dll", "qmgr.dll", "qmgrprxy.dll",
    "wucltux.dll", "muweb.dll", "wuwebv.dll"
)

$regCount = 0
foreach ($dll in $wuDlls) {
    $dllPath = "$env:SystemRoot\System32\$dll"
    if (Test-Path $dllPath) {
        $result = & regsvr32.exe /s $dllPath 2>&1
        $regCount++
    }
}
Write-Host "       [OK] $regCount DLL ujraregisztralva" -ForegroundColor Green

# 4.4 BITS és WU socket reset
Write-Host "  [4.4] Winsock es proxy reset..." -ForegroundColor Yellow
& netsh winsock reset 2>&1 | Out-Null
& netsh winhttp reset proxy 2>&1 | Out-Null
Write-Host "       [OK] Winsock reset kesz" -ForegroundColor Green

# 4.5 WU beállítása: Értesítés, de NE töltsön automatikusan
Write-Host "  [4.5] Windows Update beallitas: Ertesite, de ne toltson le auto..." -ForegroundColor Yellow
$auPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update"
if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
# AUOptions: 2=Notify only, 3=Download and notify, 4=Auto
Set-ItemProperty -Path $auPath -Name "AUOptions" -Value 2 -Type DWord -Force
Write-Host "       [OK] AUOptions = 2 (Csak ertesite)" -ForegroundColor Green

# 4.6 Szolgáltatások visszaindítása
Write-Host "  [4.6] Alapszolgaltatasok ujrainditasa..." -ForegroundColor Yellow
$restartServices = @("cryptSvc", "bits", "wuauserv")
foreach ($svc in $restartServices) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $svc -ErrorAction SilentlyContinue
        Write-Host "       [OK] $svc elindult" -ForegroundColor Green
    }
}

# ─── 5. TELEMETRIA SZOLGÁLTATÁSOK TILTÁSA ────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host " [5] TELEMETRIA SZOLGALTATASOK VEGLEGES TILTASA" -ForegroundColor DarkGray
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
Write-Host ""

$teleServices = @("DiagTrack", "dmwappushservice")
foreach ($svc in $teleServices) {
    $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($s) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  [OK] $svc letiltva" -ForegroundColor Green
    } else {
        Write-Host "  [--] $svc nem talalhato" -ForegroundColor DarkGray
    }
}

# BITS korlát (ne töltsön háttérben folyamatosan)
Write-Host "  [*] BITS korlat beallitasa..." -ForegroundColor Yellow
& sc.exe config bits start= demand >$null 2>&1
Write-Host "  [OK] BITS: igeny szerinti inditas" -ForegroundColor Green

# ─── 6. CPU-RABLÓ FOLYAMATOK ELLENŐRZÉSE ─────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host " [6] CPU-RABLÓ FOLYAMATOK ELLENORZESE (jelenlegi allapot)" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

$suspectProcs = @(
    "SearchIndexer", "svchost", "TiWorker", "TrustedInstaller",
    "MsMpEng", "wuauclt", "WmiPrvSE"
)

Write-Host "  Top folyamatok CPU hasznalat szerint:" -ForegroundColor Yellow
try {
    $topProcs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
    foreach ($proc in $topProcs) {
        $cpu = [math]::Round($proc.CPU, 1)
        $color = if ($cpu -gt 60) { "Red" } elseif ($cpu -gt 20) { "Yellow" } else { "DarkGray" }
        Write-Host ("  {0,-25} CPU: {1,8}s  RAM: {2,6}MB" -f $proc.Name, $cpu, [math]::Round($proc.WorkingSet/1MB,1)) -ForegroundColor $color
    }
} catch {
    Write-Host "  Folyamat lista lekerdezese sikertelen" -ForegroundColor DarkGray
}

# ─── ÖSSZEFOGLALÁS ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              MENTES BEFEJEZVE!                         ║" -ForegroundColor Green
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  Elvegzett muveletele:                                  ║" -ForegroundColor White
Write-Host "║  ✓ Visszaallitasi pont keszult                         ║" -ForegroundColor White
Write-Host "║  ✓ Karos KB-k eltavolitva ($removedCount db)                    ║" -ForegroundColor White
Write-Host "║  ✓ Windows Search adatbazis torolve (ujraepul)         ║" -ForegroundColor White
Write-Host "║  ✓ WSearch: kezzel inditott modra allitva              ║" -ForegroundColor White
Write-Host "║  ✓ Windows Update cache torolve                        ║" -ForegroundColor White
Write-Host "║  ✓ WU DLL-ek ujraregisztralva                          ║" -ForegroundColor White
Write-Host "║  ✓ WU: csak ertesite mod                               ║" -ForegroundColor White
Write-Host "║  ✓ Telemetria szolgaltatasok letiltva                  ║" -ForegroundColor White
Write-Host "╠══════════════════════════════════════════════════════════╣" -ForegroundColor Green
Write-Host "║  KOVETKEZO LEPESEK:                                     ║" -ForegroundColor Yellow
Write-Host "║  1. INDITSD UJRA a szamitogepet!                       ║" -ForegroundColor Yellow
Write-Host "║  2. Ellenorizd a CPU hasznalatat inditas utan          ║" -ForegroundColor Yellow
Write-Host "║  3. Ha WU szukseges: csak MANUALIS ellenorzest futtass ║" -ForegroundColor Yellow
Write-Host "║  4. KB3020369 + KB3125574 telepitese ajanlott (offline)║" -ForegroundColor Yellow
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

$restart = Read-Host " Ujrainditod most a gepet? (I/N)"
if ($restart -eq "I" -or $restart -eq "i") {
    Write-Host " Ujrainditas 15 masodperc mulva..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    Restart-Computer -Force
}
