#Requires -RunAsAdministrator
<#
.SYNOPSIS
    KB Ellenőrző és Frissítés-kezelő szkript.
    Ellenőrzi a kötelező és káros KB-k állapotát, és elvégzi a szükséges
    eltávolításokat / jelzi a hiányzó szükséges frissítéseket.
.DESCRIPTION
    Kompatibilis: Windows 7, 8, 8.1, 10, 11
    Futtatás: PowerShell ADMINKÉNT
.NOTES
    RTS Framework - LordAthis Szervizem/Boltom
    Verzió: 1.0
#>

# ─── OS detektálás ────────────────────────────────────────────────────────────
$osVersion = [System.Environment]::OSVersion.Version
$osMajor   = $osVersion.Major
$osMinor   = $osVersion.Minor
$osBuild   = $osVersion.Build

$osKey = switch ($true) {
    ($osMajor -eq 5)                          { "Windows_XP" }
    ($osMajor -eq 6 -and $osMinor -eq 1)      { "Windows_7" }
    ($osMajor -eq 6 -and $osMinor -eq 2)      { "Windows_8" }
    ($osMajor -eq 6 -and $osMinor -eq 3)      { "Windows_81" }
    ($osMajor -eq 10 -and $osBuild -lt 22000) { "Windows_10" }
    ($osMajor -eq 10 -and $osBuild -ge 22000) { "Windows_11" }
    default                                    { "Unknown" }
}

Clear-Host
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    RTS Framework - KB Ellenorzo / Frissites-kezelo     ║" -ForegroundColor Cyan
Write-Host "║    LordAthis Szervizem/Boltom                          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host " OS       : $([System.Environment]::OSVersion.VersionString)" -ForegroundColor White
Write-Host " OS kulcs : $osKey" -ForegroundColor White
Write-Host " Datum    : $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
Write-Host ""

if ($osKey -eq "Unknown") {
    Write-Warning "Ismeretlen Windows verzio. A szkript leall."
    exit 1
}

# ─── JSON betöltése ───────────────────────────────────────────────────────────
$scriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsonPath   = Join-Path (Split-Path $scriptDir -Parent) "data\kb_lists.json"

# Ha nem találja relatívan, próbálkozzon a script mellől
if (-not (Test-Path $jsonPath)) {
    $jsonPath = Join-Path $scriptDir "kb_lists.json"
}
if (-not (Test-Path $jsonPath)) {
    $jsonPath = Join-Path $scriptDir "..\data\kb_lists.json"
}

if (-not (Test-Path $jsonPath)) {
    Write-Warning "kb_lists.json nem talalhato! Keresve: $jsonPath"
    Write-Warning "Belso adatokkal folytatom (W7 lista)..."
    $useBuiltin = $true
} else {
    Write-Host " KB lista betoltve: $jsonPath" -ForegroundColor DarkGray
    $useBuiltin = $false
    try {
        $kbData   = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
        $osConfig = $kbData.$osKey
    } catch {
        Write-Warning "JSON beolvasas sikertelen: $($_.Exception.Message)"
        $useBuiltin = $true
    }
}

# ─── Beépített listák (JSON nélküli fallback) ─────────────────────────────────
if ($useBuiltin -or $null -eq $osConfig) {
    Write-Host " [Beepitett W7 lista hasznalata]" -ForegroundColor DarkGray

    $requiredKBs = @(
        @{ KB="KB3020369"; Desc="Servicing Stack Update (ELOFELTETAL!)" },
        @{ KB="KB3125574"; Desc="Convenience Rollup (SP2-szeru csomag)" },
        @{ KB="KB3138612"; Desc="Windows Update Client - gyors WU szkenneles" },
        @{ KB="KB4474419"; Desc="SHA-2 Code Signing Support" },
        @{ KB="KB4490628"; Desc="Servicing Stack Update 2019" }
    )
    $harmfulKBs = @(
        @{ KB="KB3035583"; Desc="Get Windows 10 (GWX)" },
        @{ KB="KB2952664"; Desc="Telemetria elokezito" },
        @{ KB="KB3068708"; Desc="Telemetria" },
        @{ KB="KB3022345"; Desc="Telemetria (korabbi)" },
        @{ KB="KB3075249"; Desc="Telemetria (consent.exe)" },
        @{ KB="KB3080149"; Desc="Telemetria" },
        @{ KB="KB3021917"; Desc="W10 readiness diagnosztika" }
    )
} else {
    # JSON-ból olvasott listák
    $requiredKBs = @()
    if ($osConfig.required) {
        foreach ($item in $osConfig.required) {
            $requiredKBs += @{ KB=$item.kb; Desc=$item.desc }
        }
    }
    $harmfulKBs = @()
    if ($osConfig.harmful) {
        foreach ($item in $osConfig.harmful) {
            $harmfulKBs += @{ KB=$item.kb; Desc=$item.desc }
        }
    }
}

# ─── Telepített KB lista lekérése (egyszerre, gyorsabb) ──────────────────────
Write-Host "[*] Telepitett frissitesek lekerese..." -ForegroundColor Yellow
Write-Host "    (Ez eltarthat egy percig W7-en!)" -ForegroundColor DarkGray
$installedHotfixes = Get-HotFix -ErrorAction SilentlyContinue | Select-Object -ExpandProperty HotFixID
Write-Host "    Megtalalt frissitesek szama: $($installedHotfixes.Count)" -ForegroundColor DarkGray
Write-Host ""

# ─── KÖTELEZŐ KB-K ELLENŐRZÉSE ───────────────────────────────────────────────
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host " KOTELEZO / AJANLOTT FRISSITESEK ALLAPOTA" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

$missingRequired = @()

foreach ($item in $requiredKBs) {
    $kb = $item.KB
    if ($installedHotfixes -contains $kb) {
        Write-Host "  [✓ TELEPITVE] $kb - $($item.Desc)" -ForegroundColor Green
    } else {
        Write-Host "  [✗ HIANYZO ] $kb - $($item.Desc)" -ForegroundColor Red
        $missingRequired += $item
    }
}

Write-Host ""
if ($missingRequired.Count -gt 0) {
    Write-Host "  [!] $($missingRequired.Count) kotelező frissités HIÁNYZIK!" -ForegroundColor Red
    Write-Host "  Ezeket manuálisan kell telepíteni (WSUS Offline Update ajánlott)." -ForegroundColor Yellow
} else {
    Write-Host "  [OK] Minden kotelezo frissites telepitve van." -ForegroundColor Green
}

# ─── KÁROS KB-K ELLENŐRZÉSE ÉS ELTÁVOLÍTÁSA ──────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
Write-Host " KAROS FRISSITESEK ELLENORZESE" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Red
Write-Host ""

$foundHarmful = @()

foreach ($item in $harmfulKBs) {
    $kb = $item.KB
    if ($installedHotfixes -contains $kb) {
        Write-Host "  [! TALALT  ] $kb - $($item.Desc)" -ForegroundColor Red
        $foundHarmful += $item
    } else {
        Write-Host "  [✓ NINCS   ] $kb" -ForegroundColor DarkGray
    }
}

Write-Host ""

if ($foundHarmful.Count -eq 0) {
    Write-Host "  [OK] Nem talalhato karos frissites." -ForegroundColor Green
} else {
    Write-Host "  [!] $($foundHarmful.Count) karos frissites talalhato!" -ForegroundColor Red
    Write-Host ""
    $answer = Read-Host "  Eltavolitjam most? (I=Igen, N=Nem, csak jelentes)"

    if ($answer -eq "I" -or $answer -eq "i") {
        Write-Host ""
        Write-Host "  Eltavolitas indul..." -ForegroundColor Yellow
        $removedOK = 0
        $removedFail = 0

        foreach ($item in $foundHarmful) {
            $kbNum = $item.KB.Replace("KB","")
            Write-Host "  [-] $($item.KB) torlese..." -ForegroundColor Yellow

            $proc = Start-Process -FilePath "wusa.exe" `
                                  -ArgumentList "/uninstall /kb:$kbNum /quiet /norestart" `
                                  -Wait -PassThru -ErrorAction SilentlyContinue

            if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                Write-Host "      [OK] Eltavolitva" -ForegroundColor Green
                $removedOK++
            } else {
                Write-Host "      [!] Hiba (kod: $($proc.ExitCode)) - kezi eltavolitas szukseges" -ForegroundColor Red
                $removedFail++
            }
        }
        Write-Host ""
        Write-Host "  Osszesites: $removedOK eltavolitva, $removedFail sikertelen" -ForegroundColor Cyan
    }
}

# ─── ÖSSZEFOGLALÓ JELENTÉS ────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " OSSZESITO JELENTES" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  OS          : $osKey" -ForegroundColor White
Write-Host "  Telepitett  : $($installedHotfixes.Count) frissites" -ForegroundColor White
Write-Host "  Kotelező   : $($requiredKBs.Count - $missingRequired.Count) / $($requiredKBs.Count) telepitve" -ForegroundColor White
Write-Host "  Karos       : $($foundHarmful.Count) talalhato" -ForegroundColor White

if ($missingRequired.Count -gt 0) {
    Write-Host ""
    Write-Host "  HIANYZO FONTOS FRISSITESEK:" -ForegroundColor Yellow
    foreach ($item in $missingRequired) {
        Write-Host "    - $($item.KB): $($item.Desc)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  WSUS Offline Update tool: https://www.wsusoffline.net" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "  Jelentes mentve: $(Join-Path $env:TEMP 'RTS_KB_Report.txt')" -ForegroundColor DarkGray

# Jelentés mentése
$reportPath = Join-Path $env:TEMP "RTS_KB_Report.txt"
$report = @"
RTS Framework - KB Ellenorzo Jelentes
======================================
Datum    : $(Get-Date -Format 'yyyy-MM-dd HH:mm')
OS       : $([System.Environment]::OSVersion.VersionString)
OS kulcs : $osKey

KOTELEZO FRISSITESEK:
$(foreach ($item in $requiredKBs) {
    $status = if ($installedHotfixes -contains $item.KB) { "TELEPITVE" } else { "HIANYZO!" }
    "  [$status] $($item.KB) - $($item.Desc)"
})

KAROS FRISSITESEK:
$(foreach ($item in $harmfulKBs) {
    $status = if ($installedHotfixes -contains $item.KB) { "TELEPITVE - ELTAVOLITANDO!" } else { "nincs" }
    "  [$status] $($item.KB) - $($item.Desc)"
})
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8 -Force
Write-Host ""
