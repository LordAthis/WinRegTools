# Kódolás kényszerítése az aktuális munkamenetben
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Ez a trükk: megmondjuk a PowerShellnek, hogy minden scriptet UTF8-ként olvasson be a lemezről
$PSDefaultParameterValues['*:Encoding'] = 'utf8'


#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Biztonságosan kitakarítja a WinSxS (Component Store) mappát.
.DESCRIPTION
    A WinSxS mappa tartalmazza a Windows komponenseket, korábbi frissítési
    fájlokat. DISM és Cleanmgr eszközökkel takarítjuk, NEM törlünk kézzel!

    Kompatibilis: Windows 7 SP1+, 8, 8.1, 10, 11
    XP: WinSxS nem létezik / más struktúra – szkript leáll.
    Futtatás: PowerShell ADMINKÉNT
.NOTES
    RTS Framework - LordAthis
    Verzió: 1.0
#>

$osVersion = [System.Environment]::OSVersion.Version
$osBuild   = $osVersion.Build
$osMajor   = $osVersion.Major
$osMinor   = $osVersion.Minor

Write-Host ""
Write-Host "================================================" -ForegroundColor DarkCyan
Write-Host "   WINSXS / COMPONENT STORE TAKARITAS" -ForegroundColor DarkCyan
Write-Host "================================================" -ForegroundColor DarkCyan
Write-Host " OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host ""

# XP: nem támogatott
if ($osMajor -lt 6) {
    Write-Warning "Windows XP - WinSxS takaritas nem alkalmazhato. Leallas."
    exit 0
}

# Vista (6.0) - DISM nem elérhető
if ($osMajor -eq 6 -and $osMinor -eq 0) {
    Write-Warning "Windows Vista - DISM nem elérhető. Csak kezi Disk Cleanup lehetseges."
    Start-Process "cleanmgr.exe" -Wait
    exit 0
}

# ─── WinSxS méret lekérdezése (ELŐTT) ─────────────────────────────────────────
$winSxSPath = "$env:SystemRoot\WinSxS"
$sizeBefore = 0  # Alaphelyzet
Write-Host "[*] WinSxS mappa jelenlegi meretenek lekerdezese..." -ForegroundColor Yellow
try {
    $sizeBefore = (Get-ChildItem -Path $winSxSPath -Recurse -Force -ErrorAction SilentlyContinue |
                   Measure-Object -Property Length -Sum).Sum
    $sizeBeforeMB = [math]::Round($sizeBefore / 1MB, 1)
    Write-Host "  Meret takaritas ELOTT: $sizeBeforeMB MB" -ForegroundColor Cyan
} catch {
    Write-Host "  Meret lekerdezes sikertelen (ez normalis, ha a WinSxS vedett)" -ForegroundColor DarkGray
}

# ─── 0. DISM: Rendszerfájlok javítása (Health Check & Restore) ───────────────
Write-Host ""
Write-Host "[0] DISM - Rendszerfajlok epsegenek ellenorzese es javitasa..." -ForegroundColor Yellow

# Ellenőrizzük, hogy van-e sérülés
dism /Online /Cleanup-Image /ScanHealth

# Ha a ScanHealth hibát talál, vagy biztosra akarunk menni, futtatjuk a javítást
Write-Host "  [*] Mely javitas es rendszerelemek helyreallitasa folyamatban..." -ForegroundColor Gray
dism /Online /Cleanup-Image /RestoreHealth



# ─── 1. DISM: Komponenstár elemzés ───────────────────────────────────────────
Write-Host ""
Write-Host "[1] DISM - Component Store elemzes..." -ForegroundColor Yellow
dism /Online /Cleanup-Image /AnalyzeComponentStore

# ─── 2. DISM: Régi Windows frissítések eltávolítása ──────────────────────────
Write-Host ""
Write-Host "[2] DISM - Regi frissitesi fajlok eltavolitasa..." -ForegroundColor Yellow
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FIGYELEM] DISM /ResetBase hibat adott vissza: $LASTEXITCODE" -ForegroundColor Yellow
    Write-Host "  Proba /ResetBase nelkul..." -ForegroundColor Yellow
    dism /Online /Cleanup-Image /StartComponentCleanup
}

# ─── 3. DISM: Visszaállítási pontok (SP backup) cleanup ──────────────────────
Write-Host ""
Write-Host "[3] DISM - Szervizcsomag biztonsagi masolatok torlese (ha van)..." -ForegroundColor Yellow
dism /Online /Cleanup-Image /SPSuperseded 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Nincs szervizcsomag backup, vagy nem alkalmazhato." -ForegroundColor DarkGray
}

# ─── 4. Windows Update gyorsítótár ───────────────────────────────────────────
Write-Host ""
Write-Host "[4] Windows Update cache torlese..." -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name cryptSvc -Force -ErrorAction SilentlyContinue
Stop-Service -Name bits     -Force -ErrorAction SilentlyContinue
Stop-Service -Name msiserver -Force -ErrorAction SilentlyContinue

$wuCachePath = "$env:SystemRoot\SoftwareDistribution\Download"
if (Test-Path $wuCachePath) {
    Remove-Item -Path "$wuCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] SoftwareDistribution\Download torolve" -ForegroundColor Green
}

Start-Service -Name wuauserv  -ErrorAction SilentlyContinue
Start-Service -Name cryptSvc  -ErrorAction SilentlyContinue
Start-Service -Name bits      -ErrorAction SilentlyContinue
Start-Service -Name msiserver -ErrorAction SilentlyContinue

# ─── 5. Disk Cleanup (Cleanmgr) automata módban ──────────────────────────────
Write-Host ""
Write-Host "[5] Disk Cleanup (cleanmgr) automata futtatas..." -ForegroundColor Yellow

# StateFlags 0x0001 = Windows Update Cleanup + Temp fájlok
$cleanmgrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$categories = @(
    "Update Cleanup",
    "Temporary Files",
    "Temporary Setup Files",
    "Windows Upgrade Log Files",
    "Device Driver Packages",
    "Previous Installations"
)
foreach ($cat in $categories) {
    $catPath = "$cleanmgrKey\$cat"
    if (Test-Path $catPath) {
        Set-ItemProperty -Path $catPath -Name "StateFlags0001" -Value 2 -Type DWord -Force
    }
}
Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -ErrorAction SilentlyContinue
Write-Host "  [OK] Disk Cleanup befejezve" -ForegroundColor Green


# ─── WinSxS méret újra ───────────────────────────────────────────────────────
Write-Host ""
Write-Host "[*] WinSxS mappa merete takaritas UTAN:" -ForegroundColor Yellow
try {
    $sizeAfter = (Get-ChildItem -Path $winSxSPath -Recurse -Force -ErrorAction SilentlyContinue |
                  Measure-Object -Property Length -Sum).Sum
    $sizeAfterMB  = [math]::Round($sizeAfter / 1MB, 1)
    $savedMB      = [math]::Round(($sizeBefore - $sizeAfter) / 1MB, 1)
    Write-Host "  Meret UTAN : $sizeAfterMB MB" -ForegroundColor Cyan
    if ($savedMB -gt 0) {
        Write-Host "  Megtakaritas: $savedMB MB" -ForegroundColor Green
    }
} catch {
    Write-Host "  Meret lekerdezes sikertelen" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor DarkCyan
Write-Host "  KESZ! WinSxS takaritas befejezve." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor DarkCyan
Write-Host ""
