# Innen a Script elejére

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
    Kikapcsolja a Start menü Bing/online javaslatait és reklám tartalmait.
.DESCRIPTION
    Kompatibilis: Windows 10, 11
    Windows 7/8: részleges (IE keresési ajánlások)
    XP: nem támogatott
    Futtatás: PowerShell ADMINKÉNT
.NOTES
    RTS Framework - LordAthis
    Verzió: 1.0
#>

$osVersion = [System.Environment]::OSVersion.Version
$osBuild   = $osVersion.Build
$osMajor   = $osVersion.Major

Write-Host ""
Write-Host "================================================" -ForegroundColor Magenta
Write-Host "   START MENÜ BING / ONLINE JAVASLATOK TILTÁS" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta
Write-Host " OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host ""

if ($osMajor -lt 6) {
    Write-Warning "Windows XP nem támogatott. Leállás."
    exit 0
}

function Set-RegValue {
    param([string]$Path,[string]$Name,[object]$Value,[string]$Type="DWord")
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    Write-Host "  [OK] $(Split-Path $Path -Leaf)\$Name = $Value" -ForegroundColor Green
}

# ─── W10 / W11 ───────────────────────────────────────────────────────────────
if ($osBuild -ge 10240) {

    Write-Host "[*] Start menü online tartalom letiltása..." -ForegroundColor Yellow

    # Online keresési javaslatok tiltása
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
                 "BingSearchEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
                 "AllowSearchToUseLocation" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
                 "DisableDeviceMetadataBasedSearch" 1

    # Start menü alkalmazásajánlók (W10)
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                 "SystemPaneSuggestionsEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                 "SubscribedContent-338388Enabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                 "SubscribedContent-338389Enabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                 "OemPreInstalledAppsEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                 "PreInstalledAppsEnabled" 0
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                 "SilentInstalledAppsEnabled" 0

    # Tálca javaslatok
    Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                 "ShowSyncProviderNotifications" 0

    # GPO: webes keresés tiltás
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
                 "DisableWebSearch" 1
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
                 "ConnectedSearchUseWeb" 0

    # W11 specifikus
    if ($osBuild -ge 22000) {
        Write-Host "[*] Windows 11 Start menü extra tiltások..." -ForegroundColor Yellow

        # Start menü reklám alkalmazások
        Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                     "SubscribedContent-338393Enabled" 0
        Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                     "SubscribedContent-353694Enabled" 0
        Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" `
                     "SubscribedContent-353696Enabled" 0

        # Tálca widget (hírfolyam / Bing News)
        Set-RegValue "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                     "TaskbarDa" 0

        # Keresőmező javaslat tiltás
        Set-RegValue "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" `
                     "DisableSearchBoxSuggestions" 1
    }
}
# ─── W7 / W8 ─────────────────────────────────────────────────────────────────
elseif ($osMajor -eq 6) {
    Write-Host "[*] Windows 7/8 Start menü internet-keresés letiltása..." -ForegroundColor Yellow
    Set-RegValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
                 "DisableWebSearch" 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Magenta
Write-Host "  KÉSZ! Kijelentkezés / újraindítás szükséges." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Magenta
Write-Host ""



# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kész. Az energiagazdálkodási korlátok feloldva." -ForegroundColor Gray
