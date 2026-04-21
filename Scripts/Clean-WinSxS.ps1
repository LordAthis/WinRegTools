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
Write-Host "   WINSXS / COMPONENT STORE TAKARÍTÁS" -ForegroundColor DarkCyan
Write-Host "================================================" -ForegroundColor DarkCyan
Write-Host " OS: $([System.Environment]>::OSVersion.VersionString)"
Write-Host ""

# XP: nem támogatott
if ($osMajor -lt 6) {
    Write-Warning "Windows XP - WinSxS takarítás nem alkalmazható. Leállás."
    exit 0
}

# Vista (6.0) - DISM nem elérhető
if ($osMajor -eq 6 -and $osMinor -eq 0) {
    Write-Warning "Windows Vista - DISM nem elérhető. Csak kézi Disk Cleanup lehetséges."
    Start-Process "cleanmgr.exe" -Wait
    exit 0
}

# ─── WinSxS méret lekérdezése ─────────────────────────────────────────────────
$winSxSPath = "$env:SystemRoot\WinSxS"
Write-Host "[*] WinSxS mappa jelenlegi méretének lekérdezése..." -ForegroundColor Yellow
try {
    $sizeBefore = (Get-ChildItem -Path $winSxSPath -Recurse -Force -ErrorAction SilentlyContinue |
                   Measure-Object -Property Length -Sum).Sum
    $sizeBeforeMB = [math]::Round($sizeBefore / 1MB, 1)
    Write-Host "  Méret takarítás ELŐTT: $sizeBeforeMB MB" -ForegroundColor Cyan
} catch {
    Write-Host "  Méret lekérdezés sikertelen (ez normális, ha a WinSxS védett)" -ForegroundColor DarkGray
}

# ─── 1. DISM: Komponenstár elemzés ───────────────────────────────────────────
Write-Host ""
Write-Host "[1] DISM - Component Store elemzés..." -ForegroundColor Yellow
dism /Online /Cleanup-Image /AnalyzeComponentStore

# ─── 2. DISM: Régi Windows frissítések eltávolítása ──────────────────────────
Write-Host ""
Write-Host "[2] DISM - Régi frissítési fájlok eltávolítása..." -ForegroundColor Yellow
dism /Online /Cleanup-Image /StartComponentCleanup /ResetBase

if ($LASTEXITCODE -ne 0) {
    Write-Host "  [FIGYELEM] DISM /ResetBase hibát adott vissza: $LASTEXITCODE" -ForegroundColor Yellow
    Write-Host "  Próba /ResetBase nélkül..." -ForegroundColor Yellow
    dism /Online /Cleanup-Image /StartComponentCleanup
}

# ─── 3. DISM: Visszaállítási pontok (SP backup) cleanup ──────────────────────
Write-Host ""
Write-Host "[3] DISM - Szervizcsomag biztonsági másolatok törlése (ha van)..." -ForegroundColor Yellow
dism /Online /Cleanup-Image /SPSuperseded 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "  Nincs szervizcsomag backup, vagy nem alkalmazható." -ForegroundColor DarkGray
}

# ─── 4. Windows Update gyorsítótár ───────────────────────────────────────────
Write-Host ""
Write-Host "[4] Windows Update cache törlése..." -ForegroundColor Yellow
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Stop-Service -Name cryptSvc -Force -ErrorAction SilentlyContinue
Stop-Service -Name bits     -Force -ErrorAction SilentlyContinue
Stop-Service -Name msiserver -Force -ErrorAction SilentlyContinue

$wuCachePath = "$env:SystemRoot\SoftwareDistribution\Download"
if (Test-Path $wuCachePath) {
    Remove-Item -Path "$wuCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] SoftwareDistribution\Download törölve" -ForegroundColor Green
}

Start-Service -Name wuauserv  -ErrorAction SilentlyContinue
Start-Service -Name cryptSvc  -ErrorAction SilentlyContinue
Start-Service -Name bits      -ErrorAction SilentlyContinue
Start-Service -Name msiserver -ErrorAction SilentlyContinue

# ─── 5. Disk Cleanup (Cleanmgr) automata módban ──────────────────────────────
Write-Host ""
Write-Host "[5] Disk Cleanup (cleanmgr) automata futtatás..." -ForegroundColor Yellow

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
Write-Host "[*] WinSxS mappa mérete takarítás UTÁN:" -ForegroundColor Yellow
try {
    $sizeAfter = (Get-ChildItem -Path $winSxSPath -Recurse -Force -ErrorAction SilentlyContinue |
                  Measure-Object -Property Length -Sum).Sum
    $sizeAfterMB  = [math]::Round($sizeAfter / 1MB, 1)
    $savedMB      = [math]::Round(($sizeBefore - $sizeAfter) / 1MB, 1)
    Write-Host "  Méret UTÁN : $sizeAfterMB MB" -ForegroundColor Cyan
    if ($savedMB -gt 0) {
        Write-Host "  Megtakarítás: $savedMB MB" -ForegroundColor Green
    }
} catch {
    Write-Host "  Méret lekérdezés sikertelen" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "================================================" -ForegroundColor DarkCyan
Write-Host "  KÉSZ! WinSxS takarítás befejezve." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor DarkCyan
Write-Host ""
