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


#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Létrehoz egy rendszer-visszaállítási pontot automatikus dátum+beállítás névvel.
.DESCRIPTION
    A visszaállítási pont neve: "RTS_Beallitas_YYYY-MM-DD_HH-mm"
    Kompatibilis: Windows XP, 7, 8, 10, 11
    Futtatás: PowerShell ADMINKÉNT
.NOTES
    RTS Framework - LordAthis
    Verzió: 1.0
#>

$osVersion = [System.Environment]::OSVersion.Version
$osBuild   = $osVersion.Build
$osMajor   = $osVersion.Major

Write-Host ""
Write-Host "================================================" -ForegroundColor White
Write-Host "   RENDSZER-VISSZAÁLLÍTÁSI PONT LÉTREHOZÁSA" -ForegroundColor White
Write-Host "================================================" -ForegroundColor White
Write-Host " OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host ""

# ─── Dátum alapú automatikus név ─────────────────────────────────────────────
$timestamp  = Get-Date -Format "yyyy-MM-dd_HH-mm"
$pointName  = "RTS_Beallitas_$timestamp"

Write-Host "  Visszaállítási pont neve: " -NoNewline
Write-Host $pointName -ForegroundColor Cyan
Write-Host ""

# ─── System Protection engedélyezése (ha ki van kapcsolva) ───────────────────
Write-Host "[*] System Protection ellenőrzése..." -ForegroundColor Yellow

$systemDrive = $env:SystemDrive  # általában C:

# W10/W11/W8: Enable-ComputerRestore
if ($osMajor -ge 6) {
    try {
        Enable-ComputerRestore -Drive "$systemDrive\" -ErrorAction Stop
        Write-Host "  [OK] System Protection engedélyezve: $systemDrive" -ForegroundColor Green
    } catch {
        Write-Host "  [FIGYELEM] Enable-ComputerRestore: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    # VSS / System Restore szolgáltatás ellenőrzés
    $vssSvc = Get-Service -Name "VSS" -ErrorAction SilentlyContinue
    if ($vssSvc -and $vssSvc.StartType -eq "Disabled") {
        Set-Service -Name "VSS" -StartupType Manual
        Start-Service -Name "VSS" -ErrorAction SilentlyContinue
        Write-Host "  [OK] VSS szolgáltatás beindítva" -ForegroundColor Green
    }

    $srSvc = Get-Service -Name "wbengine" -ErrorAction SilentlyContinue
    if ($srSvc -and $srSvc.StartType -eq "Disabled") {
        Set-Service -Name "wbengine" -StartupType Manual -ErrorAction SilentlyContinue
    }
}

# ─── W10/W11 esetén frekvencia korlát feloldása ───────────────────────────────
# W10/W11 alapból 24 óránként engedi csak (SystemRestorePointFrequency)
if ($osBuild -ge 10240) {
    $srFreqPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    if (-not (Test-Path $srFreqPath)) { New-Item -Path $srFreqPath -Force | Out-Null }
    Set-ItemProperty -Path $srFreqPath -Name "SystemRestorePointFrequency" -Value 0 -Type DWord -Force
    Write-Host "  [OK] SystemRestorePointFrequency = 0 (korlát feloldva)" -ForegroundColor Green
}

# ─── Visszaállítási pont létrehozása ─────────────────────────────────────────
Write-Host ""
Write-Host "[*] Visszaállítási pont létrehozása: '$pointName'..." -ForegroundColor Yellow

$created = $false

# 1. Módszer: Checkpoint-Computer (W7+)
if ($osMajor -ge 6) {
    try {
        Checkpoint-Computer -Description $pointName `
                            -RestorePointType "MODIFY_SETTINGS" `
                            -ErrorAction Stop
        $created = $true
        Write-Host "  [OK] Checkpoint-Computer: sikeresen létrehozva!" -ForegroundColor Green
    } catch {
        Write-Host "  [!] Checkpoint-Computer hiba: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 2. Módszer: WMI (XP kompatibilis, fallback)
if (-not $created) {
    Write-Host "  [*] WMI módszer próbálkozás..." -ForegroundColor Yellow
    try {
        $sr = Get-WmiObject -Namespace "root\default" -Class "SystemRestore" -ErrorAction Stop
        $result = $sr.CreateRestorePoint($pointName, 12, 100)  # 12=MODIFY_SETTINGS, 100=BEGIN_SYSTEM_CHANGE
        if ($result.ReturnValue -eq 0) {
            $created = $true
            Write-Host "  [OK] WMI: Visszaállítási pont létrehozva!" -ForegroundColor Green
        } else {
            Write-Host "  [!] WMI visszatérési kód: $($result.ReturnValue)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [!] WMI hiba: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 3. Módszer: vssadmin (XP / fallback)
if (-not $created) {
    Write-Host "  [*] vssadmin árnyékmásolat próba..." -ForegroundColor Yellow
    try {
        $vssResult = & vssadmin create shadow /for=$systemDrive\ 2>&1
        Write-Host "  vssadmin: $vssResult" -ForegroundColor DarkGray
        $created = $true
    } catch {
        Write-Host "  [!] vssadmin hiba: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ─── Eredmény ─────────────────────────────────────────────────────────────────
Write-Host ""
if ($created) {
    # Legutóbbi visszaállítási pontok listázása
    Write-Host "[*] Létező visszaállítási pontok:" -ForegroundColor Yellow
    try {
        $restorePoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
        if ($restorePoints) {
            $restorePoints | Select-Object -Last 5 |
                Format-Table @{L="Dátum";E={$_.ConvertToDateTime($_.CreationTime).ToString("yyyy-MM-dd HH:mm")}},
                             Description -AutoSize
        }
    } catch {
        Write-Host "  Listázás nem elérhető" -ForegroundColor DarkGray
    }

    Write-Host "================================================" -ForegroundColor White
    Write-Host "  KÉSZ! Visszaállítási pont létrehozva:" -ForegroundColor Green
    Write-Host "  $pointName" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor White
} else {
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "  HIBA: Nem sikerült létrehozni a visszaállítási" -ForegroundColor Red
    Write-Host "  pontot. Ellenőrizd a System Protection és VSS" -ForegroundColor Red
    Write-Host "  szolgáltatás állapotát!" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
}
Write-Host ""


# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kész. Az energiagazdálkodási korlátok feloldva." -ForegroundColor Gray
