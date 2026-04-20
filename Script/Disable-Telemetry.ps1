#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Letiltja a Windows telemetriát és adatgyűjtési szolgáltatásokat.
.DESCRIPTION
    Kompatibilis: Windows 7, 8, 10, 11
    XP: nem alkalmazható (nincs telemetria szolgáltatás)
    Futtatás: PowerShell ADMINKÉNT
.NOTES
    RTS Framework - LordAthis
    Verzió: 1.0
#>

$osVersion = [System.Environment]::OSVersion.Version
$osBuild   = $osVersion.Build
$osMajor   = $osVersion.Major

Write-Host ""
Write-Host "================================================" -ForegroundColor Red
Write-Host "   TELEMETRIA ÉS ADATGYŰJTÉS LETILTÁSA" -ForegroundColor Red
Write-Host "================================================" -ForegroundColor Red
Write-Host " OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host ""

if ($osMajor -lt 6) {
    Write-Warning "Windows XP - nincs telemetria szolgáltatás. Leállás."
    exit 0
}

function Set-RegValue {
    param([string]$Path,[string]$Name,[object]$Value,[string]$Type="DWord")
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    Write-Host "  [OK] $(Split-Path $Path -Leaf)\$Name = $Value" -ForegroundColor Green
}

function Stop-AndDisableService {
    param([string]$ServiceName)
    $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($svc) {
        Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
        Set-Service  -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "  [LETILTVA] Szolgáltatás: $ServiceName" -ForegroundColor Green
    } else {
        Write-Host "  [NINCS]    Szolgáltatás: $ServiceName" -ForegroundColor DarkGray
    }
}

# ─── REGISTRY TELEMETRIA ─────────────────────────────────────────────────────
Write-Host "[*] Registry telemetria értékek..." -ForegroundColor Yellow

# Telemetria szint: 0 = Biztonsági (csak Enterprise/LTSC), 1 = Alap
Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
             "AllowTelemetry" 0

Set-RegValue "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
             "AllowTelemetry" 0

Set-RegValue "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
             "AllowTelemetry" 0

# ─── TELEMETRIA SZOLGÁLTATÁSOK ───────────────────────────────────────────────
Write-Host "[*] Telemetria szolgáltatások leállítása/tiltása..." -ForegroundColor Yellow

# DiagTrack = Connected User Experiences and Telemetry
Stop-AndDisableService "DiagTrack"

# dmwappushservice = WAP Push Message Routing (telemetria segéd)
Stop-AndDisableService "dmwappushservice"

# WerSvc = Windows Error Reporting
Stop-AndDisableService "WerSvc"

# PcaSvc = Program Compatibility Assistant
Stop-AndDisableService "PcaSvc"

# ─── ÜTEMEZETT FELADATOK ─────────────────────────────────────────────────────
Write-Host "[*] Telemetria ütemezett feladatok letiltása..." -ForegroundColor Yellow

$tasks = @(
    "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
    "\Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "\Microsoft\Windows\Autochk\Proxy",
    "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
    "\Microsoft\Windows\Feedback\Siuf\DmClient",
    "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload",
    "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
)

foreach ($task in $tasks) {
    $t = Get-ScheduledTask -TaskPath (Split-Path $task -Parent) `
                           -TaskName  (Split-Path $task -Leaf) `
                           -ErrorAction SilentlyContinue
    if ($t) {
        Disable-ScheduledTask -TaskPath (Split-Path $task -Parent) `
                              -TaskName  (Split-Path $task -Leaf) `
                              -ErrorAction SilentlyContinue | Out-Null
        Write-Host "  [LETILTVA] Feladat: $(Split-Path $task -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "  [NINCS]    Feladat: $(Split-Path $task -Leaf)" -ForegroundColor DarkGray
    }
}

# ─── W10 / W11 EXTRA ─────────────────────────────────────────────────────────
if ($osBuild -ge 10240) {
    Write-Host "[*] Windows 10/11 extra adatgyűjtés tiltás..." -ForegroundColor Yellow

    # Hirdetési azonosító
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" `
                 "Enabled" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" `
                 "DisabledByGroupPolicy" 1

    # Activity History (Idővonal)
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
                 "EnableActivityFeed" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" `
                 "PublishUserActivities" 0

    # Feedback kérések tiltása
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" `
                 "NumberOfSIUFInPeriod" 0
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
                 "DoNotShowFeedbackNotifications" 1

    # Location tracking tiltás (policy)
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors" `
                 "DisableLocation" 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Red
Write-Host "  KÉSZ! Telemetria letiltva." -ForegroundColor Green
Write-Host "  Újraindítás ajánlott." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Red
Write-Host ""
