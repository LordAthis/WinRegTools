# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---


#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Letiltja a Windows Search indexelési szolgáltatást.
.DESCRIPTION
    Kompatibilis: Windows XP (Indexing Service), Vista/7/8/10/11 (Windows Search)
    Futtatás: PowerShell ADMINKÉNT
.NOTES
    RTS Framework - LordAthis
    Verzió: 1.0
#>

$osVersion = [System.Environment]::OSVersion.Version
$osBuild   = $osVersion.Build
$osMajor   = $osVersion.Major

Write-Host ""
Write-Host "================================================" -ForegroundColor DarkYellow
Write-Host "   INDEXELÉSI SZOLGÁLTATÁS LETILTÁSA" -ForegroundColor DarkYellow
Write-Host "================================================" -ForegroundColor DarkYellow
Write-Host " OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host ""

function Stop-AndDisableService {
    param([string]$ServiceName, [string]$DisplayName = "")
    $label = if ($DisplayName) { $DisplayName } else { $ServiceName }
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        }
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  [LETILTVA] $label" -ForegroundColor Green
    } else {
        Write-Host "  [NINCS]    $label" -ForegroundColor DarkGray
    }
}

# ─── Windows XP: Indexing Service (cisvc) ────────────────────────────────────
if ($osMajor -lt 6) {
    Write-Host "[*] Windows XP - Indexing Service letiltása..." -ForegroundColor Yellow
    Stop-AndDisableService "cisvc" "Indexing Service (cisvc)"

    # XP registry
    $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\cisvc"
    if (Test-Path $regPath) {
        Set-ItemProperty -Path $regPath -Name "Start" -Value 4 -Force
        Write-Host "  [OK] Registry: cisvc Start=4 (Disabled)" -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "  KÉSZ! XP Indexing Service letiltva." -ForegroundColor Green
    exit 0
}

# ─── Windows Vista / 7 / 8 / 10 / 11: Windows Search (WSearch) ───────────────
Write-Host "[*] Windows Search (WSearch) szolgáltatás letiltása..." -ForegroundColor Yellow
Stop-AndDisableService "WSearch" "Windows Search (WSearch)"

# ─── Registry: indexelés tiltás ──────────────────────────────────────────────
Write-Host "[*] Registry beállítások..." -ForegroundColor Yellow

function Set-RegValue {
    param([string]$Path,[string]$Name,[object]$Value,[string]$Type="DWord")
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    Write-Host "  [OK] $(Split-Path $Path -Leaf)\$Name = $Value" -ForegroundColor Green
}

Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
             "PreventIndexingLowDiskSpaceMB" 0

Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows Search" `
             "SetupCompletedSuccessfully" 0

# W10/W11 extra
if ($osBuild -ge 10240) {
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
                 "SearchboxTaskbarMode" 0   # 0=el van rejtve, 1=ikon, 2=keresőmező

    # Ütemezett indexelési feladatok tiltása
    $indexTasks = @(
        "\Microsoft\Windows\Shell\IndexerAutomaticMaintenance"
    )
    foreach ($task in $indexTasks) {
        $t = Get-ScheduledTask -TaskPath (Split-Path $task -Parent) `
                               -TaskName  (Split-Path $task -Leaf) `
                               -ErrorAction SilentlyContinue
        if ($t) {
            Disable-ScheduledTask -TaskPath (Split-Path $task -Parent) `
                                  -TaskName  (Split-Path $task -Leaf) `
                                  -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  [LETILTVA] Feladat: $(Split-Path $task -Leaf)" -ForegroundColor Green
        }
    }
}

# ─── Meghajtók indexelésének kikapcsolása ─────────────────────────────────────
Write-Host "[*] Meghajtók indexelésének kikapcsolása..." -ForegroundColor Yellow
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match "^[A-Z]:\\" }
foreach ($drive in $drives) {
    $drvPath = $drive.Root.TrimEnd('\')
    try {
        $wmiDrive = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter='$drvPath'" `
                                  -ErrorAction SilentlyContinue
        if ($wmiDrive -and $wmiDrive.IndexingEnabled) {
            $wmiDrive.IndexingEnabled = $false
            $wmiDrive.Put() | Out-Null
            Write-Host "  [OK] $drvPath indexelés kikapcsolva" -ForegroundColor Green
        } else {
            Write-Host "  [--] $drvPath - már ki van kapcsolva vagy nem elérhető" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "  [HIBA] $drvPath : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "================================================" -ForegroundColor DarkYellow
Write-Host "  KÉSZ! Indexelési szolgáltatás letiltva." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor DarkYellow
Write-Host ""


# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
