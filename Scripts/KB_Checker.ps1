# --- Ébren tartás és Laptop figyelmeztetés ---
Write-Host "![FIGYELEM] Hosszu folyamat kovetkezik!" -ForegroundColor Yellow
Write-Host "Kerlek, ha Laptopot hasznalsz, csatlakoztasd a TOLTOT!" -ForegroundColor Cyan

# Megakadályozzuk az elalvást a folyamat alatt
$pos = [Console]::CursorPosition
Write-Host "[*] Automatikus elalvas felfuggesztve a szkript futasa alatt..." -ForegroundColor Gray

# Beállítjuk a folyamatos ébrenlétet (ES_SYSTEM_REQUIRED | ES_CONTINUOUS)
$signature = @'
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint SetThreadExecutionState(uint esFlags);
'@
$type = Add-Type -MemberDefinition $signature -Name "Win32SleepPrevention" -Namespace "Win32" -PassThru
$type::SetThreadExecutionState(0x80000001) # ES_CONTINUOUS | ES_SYSTEM_REQUIRED


# KB_Checker.ps1
# WinRegTools - LordAthis
# Csak a listában szereplő KB-kat ellenőrzi (NEM az összes frissítést!)
# Try-Catch minden lekérdezésnél, nincs automatikus böngésző-megnyitás.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ─── Logger betöltése ─────────────────────────────────────────────────────────
$loggerPath = Join-Path $PSScriptRoot "_Logger.ps1"
if (Test-Path $loggerPath) {
    . $loggerPath
} else {
    # Fallback ha valaki önállóan futtatja
    function Write-LogOK    { param([string]$m) Write-Host "  [OK]   $m" -ForegroundColor Green }
    function Write-LogWarn  { param([string]$m) Write-Host "  [!!]   $m" -ForegroundColor Yellow }
    function Write-LogError { param([string]$m) Write-Host "  [HIBA] $m" -ForegroundColor Red }
    function Write-LogSkip  { param([string]$m) Write-Host "  [--]   $m" -ForegroundColor DarkGray }
    function Write-LogInfo  { param([string]$m) Write-Host "  [*]    $m" -ForegroundColor Cyan }
    function Write-LogSection { param([string]$t) Write-Host "`n--- $t ---" -ForegroundColor Magenta }
    function Close-Log {}
    $script:LogFile = $null
}

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

# ─── Fejléc ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  KB Checker - Frissites-kezelő        " -ForegroundColor Cyan
Write-Host "  WinRegTools - LordAthis               " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OS    : $([System.Environment]::OSVersion.VersionString)" -ForegroundColor White
Write-Host "  Build : $osKey" -ForegroundColor White
Write-Host "  Datum : $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor White
Write-Host ""

if ($osKey -eq "Unknown") {
    Write-LogError "Ismeretlen Windows verzio, a script leall."
    Close-Log
    return
}

# ─── KB listák – OS-enként beépítve (nincs külső JSON függőség!) ──────────────
# Struktúra: @{ KB="KBxxxxxxx"; Desc="Leírás"; Critical=$true/$false }

$kbDatabase = @{

    "Windows_10" = @{
        Required = @()   # W10-en nincs kötelező egyedi KB, a WU kezeli
        Harmful  = @(
            @{ KB="KB4524244"; Desc="Visszavont frissites - boot hibakat okoz";     Critical=$true }
            @{ KB="KB3035583"; Desc="Get Windows 10 (GWX) - ha maradt volna";      Critical=$false }
        )
    }

    "Windows_11" = @{
        Required = @()
        Harmful  = @(
            @{ KB="KB4524244"; Desc="Visszavont frissites - boot hibakat okoz";     Critical=$true }
        )
    }

    "Windows_81" = @{
        Required = @(
            @{ KB="KB2919355"; Desc="Windows 8.1 Update 1 - alapfrissites";         Critical=$true }
        )
        Harmful  = @(
            @{ KB="KB3035583"; Desc="Get Windows 10 (GWX)";                         Critical=$true }
            @{ KB="KB2976978"; Desc="Telemetria elokezito (W8.1)";                  Critical=$true }
            @{ KB="KB3068708"; Desc="Telemetria";                                   Critical=$true }
        )
    }

    "Windows_8" = @{
        Required = @()
        Harmful  = @(
            @{ KB="KB3035583"; Desc="Get Windows 10 (GWX)";                         Critical=$true }
            @{ KB="KB2976978"; Desc="Telemetria elokezito (W8)";                    Critical=$true }
        )
    }

    "Windows_7" = @{
        Required = @(
            @{ KB="KB3020369"; Desc="Servicing Stack Update - ELOFELTETAL!";        Critical=$true }
            @{ KB="KB3125574"; Desc="Convenience Rollup (SP2-szeru csomag)";        Critical=$true }
            @{ KB="KB3138612"; Desc="WU Client - gyors WU szkenneles";              Critical=$true }
            @{ KB="KB4474419"; Desc="SHA-2 Code Signing Support";                   Critical=$true }
            @{ KB="KB4490628"; Desc="Servicing Stack Update 2019";                  Critical=$true }
        )
        Harmful  = @(
            @{ KB="KB3035583"; Desc="Get Windows 10 (GWX)";                         Critical=$true }
            @{ KB="KB2952664"; Desc="Telemetria elokezito";                         Critical=$true }
            @{ KB="KB3068708"; Desc="Telemetria";                                   Critical=$true }
            @{ KB="KB3022345"; Desc="Telemetria (korabbi verzio)";                  Critical=$true }
            @{ KB="KB3075249"; Desc="Telemetria - consent.exe injekcio";            Critical=$true }
            @{ KB="KB3080149"; Desc="Telemetria";                                   Critical=$true }
            @{ KB="KB3021917"; Desc="W10 readiness / diagnostika";                  Critical=$false }
            @{ KB="KB3044374"; Desc="W10 upgrade elokezito";                        Critical=$false }
            @{ KB="KB2990214"; Desc="W10 upgrade elokezito (korabbi)";              Critical=$false }
        )
    }

    "Windows_XP" = @{
        Required = @(
            @{ KB="KB2347290"; Desc="SHA-2 Code Signing support";                   Critical=$true }
        )
        Harmful  = @(
            @{ KB="KB898461";  Desc="Windows Genuine Advantage - nag screen";       Critical=$false }
        )
    }
}

# Aktuális OS listájának kiválasztása
if ($kbDatabase.ContainsKey($osKey)) {
    $requiredKBs = $kbDatabase[$osKey].Required
    $harmfulKBs  = $kbDatabase[$osKey].Harmful
} else {
    $requiredKBs = @()
    $harmfulKBs  = @()
    Write-LogWarn "Nincs KB lista ehhez az OS-hez: $osKey"
}

# ─── Segédfüggvény: egyetlen KB ellenőrzése ───────────────────────────────────
# Get-HotFix -Id KB... CSAK azt a KB-t kérdezi le, nem az összeset!
# Sokkal gyorsabb, mint Get-HotFix (az összes).

function Test-KBInstalled ([string]$KBId) {
    try {
        $result = Get-HotFix -Id $KBId -ErrorAction Stop
        return $true
    } catch [System.ArgumentException] {
        # "Cannot find the requested hotfix" - nincs telepítve, ez normális
        return $false
    } catch {
        # WMI hiba, zárolás, egyéb - nem tudjuk eldönteni
        return $null  # null = ismeretlen
    }
}

# ─── KÖTELEZŐ KB-K ELLENŐRZÉSE ───────────────────────────────────────────────
Write-LogSection "KOTELEZO / AJANLOTT FRISSITESEK"

$missingRequired = @()
$unknownRequired = @()

if ($requiredKBs.Count -eq 0) {
    Write-LogSkip "Ennél az OS verziónál nincs definiált kötelező KB lista."
} else {
    foreach ($item in $requiredKBs) {
        $installed = Test-KBInstalled $item.KB
        if ($installed -eq $true) {
            Write-LogOK "$($item.KB) - $($item.Desc)"
        } elseif ($installed -eq $false) {
            $label = if ($item.Critical) { "[KRITIKUS - HIANYZO]" } else { "[HIANYZO]" }
            Write-Host "  $label $($item.KB) - $($item.Desc)" -ForegroundColor Red
            if ($script:LogFile) { "  $label $($item.KB) - $($item.Desc)" | Out-File $script:LogFile -Append }
            $missingRequired += $item
        } else {
            Write-LogWarn "$($item.KB) - Lekerdezés sikertelen (WMI hiba / zarolva)"
            $unknownRequired += $item
        }
    }
}

Write-Host ""
if ($missingRequired.Count -gt 0) {
    Write-LogWarn "$($missingRequired.Count) fontos frissites HIANYZO!"
    Write-LogInfo "Telepiteshez hasznalj WSUS Offline Update-et: https://www.wsusoffline.net"
} elseif ($requiredKBs.Count -gt 0) {
    Write-LogOK "Minden kotelező frissites megvan."
}
if ($unknownRequired.Count -gt 0) {
    Write-LogWarn "$($unknownRequired.Count) frissites allapota ismeretlen (lekerdezes sikertelen)."
}

# ─── KÁROS KB-K ELLENŐRZÉSE ──────────────────────────────────────────────────
Write-LogSection "KAROS FRISSITESEK ELLENORZESE"

$foundHarmful = @()
$queryFailed  = @()

if ($harmfulKBs.Count -eq 0) {
    Write-LogSkip "Ennél az OS verziónál nincs definiált káros KB lista."
} else {
    foreach ($item in $harmfulKBs) {
        $installed = Test-KBInstalled $item.KB
        if ($installed -eq $true) {
            Write-Host "  [TALALT!] $($item.KB) - $($item.Desc)" -ForegroundColor Red
            if ($script:LogFile) { "  [TALALT!] $($item.KB) - $($item.Desc)" | Out-File $script:LogFile -Append }
            $foundHarmful += $item
        } elseif ($installed -eq $false) {
            Write-LogSkip "$($item.KB) - nincs telepitve"
        } else {
            Write-LogWarn "$($item.KB) - Lekerdezés sikertelen"
            $queryFailed += $item
        }
    }
}

# ─── ELTÁVOLÍTÁS ─────────────────────────────────────────────────────────────
Write-Host ""

if ($foundHarmful.Count -eq 0 -and $queryFailed.Count -eq 0) {
    Write-LogOK "Nem talalhato karos frissites."
} else {
    if ($queryFailed.Count -gt 0) {
        Write-LogWarn "$($queryFailed.Count) KB allapota nem volt lekerdezhetö (WMI hiba)."
        Write-LogInfo "Kesi ellenorzes ajanlott: 'wmic qfe list brief'"
    }

    if ($foundHarmful.Count -gt 0) {
        Write-Host "  $($foundHarmful.Count) karos frissites talalhato!" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Eltavolitjam most? [I / N]" -ForegroundColor Yellow -NoNewline
        $answer = Read-Host " "

        if ($answer -eq "I" -or $answer -eq "i") {
            Write-LogSection "ELTAVOLITAS"
            $removedOK   = 0
            $removedFail = 0

            foreach ($item in $foundHarmful) {
                $kbNum = $item.KB -replace "KB",""
                Write-LogInfo "$($item.KB) eltavolitas..."

                try {
                    $proc = Start-Process -FilePath "wusa.exe" `
                                          -ArgumentList "/uninstall /kb:$kbNum /quiet /norestart" `
                                          -Wait -PassThru -ErrorAction Stop

                    switch ($proc.ExitCode) {
                        0       { Write-LogOK "$($item.KB) sikeresen eltavolitva";              $removedOK++ }
                        3010    { Write-LogOK "$($item.KB) eltavolitva - ujrainditas szukseges"; $removedOK++ }
                        2359302 { Write-LogSkip "$($item.KB) - nem volt telepitve (wusa)";      }
                        default { Write-LogError "$($item.KB) - hiba (kod: $($proc.ExitCode))"; $removedFail++ }
                    }
                } catch {
                    Write-LogError "$($item.KB) - wusa.exe nem futtatható: $($_.Exception.Message)"
                    $removedFail++
                }
            }

            Write-Host ""
            Write-Host "  Osszesites: $removedOK eltavolitva, $removedFail sikertelen" -ForegroundColor Cyan
            if ($script:LogFile) { "  Osszesites: $removedOK eltavolitva, $removedFail sikertelen" | Out-File $script:LogFile -Append }

            if ($removedOK -gt 0) {
                Write-LogWarn "Ujrainditas ajanlott az eltavolitas utan!"
            }
        } else {
            Write-LogInfo "Eltavolitas kihagyva (csak jelentes mod)."
        }
    }
}

# ─── ÖSSZEFOGLALÓ ─────────────────────────────────────────────────────────────
Write-LogSection "OSSZESITO JELENTES"
Write-Host "  OS              : $osKey" -ForegroundColor White
Write-Host "  Kotelezo KB-k   : $($requiredKBs.Count - $missingRequired.Count) / $($requiredKBs.Count) telepitve" -ForegroundColor White
Write-Host "  Karos KB-k      : $($foundHarmful.Count) talalhato" -ForegroundColor White

# ─── LOG FÁJLBA MENTÉS ────────────────────────────────────────────────────────
if ($script:LogFile) {
    # Összefoglaló szöveges blokk a log végére
    @"

OSSZESITO:
  OS           : $osKey ($([System.Environment]::OSVersion.VersionString))
  Kotelezo     : $($requiredKBs.Count - $missingRequired.Count) / $($requiredKBs.Count) telepitve
  Karos talalt : $($foundHarmful.Count)
  Ismeretlen   : $($unknownRequired.Count + $queryFailed.Count)
"@ | Out-File -FilePath $script:LogFile -Encoding UTF8 -Append

    Write-Host ""
    Write-Host "  Log mentve: $script:LogFile" -ForegroundColor DarkGray
}

Close-Log


# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kész. Az energiagazdálkodási korlátok feloldva." -ForegroundColor Gray
