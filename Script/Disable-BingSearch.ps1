#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Kikapcsolja a Bing keresőt a Windows keresőből (Start menü / Tálca).
.DESCRIPTION
    Kompatibilis: Windows 7, 8, 10, 11
    XP: nem támogatott (registry kulcs nem létezik)
    Futtatás: PowerShell ADMINKÉNT
.NOTES
    RTS Framework - LordAthis
    Verzió: 1.0
#>

# ─── Verzió detektálás ───────────────────────────────────────────────────────
$osVersion = [System.Environment]::OSVersion.Version
$osMajor   = $osVersion.Major
$osBuild   = $osVersion.Build

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   BING KERESÉS LETILTÁSA" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " OS: $([System.Environment]::OSVersion.VersionString)"
Write-Host ""

# Windows XP (5.x) - nem támogatott
if ($osMajor -lt 6) {
    Write-Warning "Windows XP nem támogatott ehhez a beállításhoz. A szkript leáll."
    exit 0
}

# ─── Függvény: Registry kulcs biztonságos írása ──────────────────────────────
function Set-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
        Write-Host "  [LÉTREHOZVA] $Path" -ForegroundColor Yellow
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force
    Write-Host "  [OK] $Path\$Name = $Value" -ForegroundColor Green
}

# ─── Windows 10 / 11 (Build 10240+) ─────────────────────────────────────────
if ($osBuild -ge 10240) {
    Write-Host "[*] Windows 10/11 Bing letiltása..." -ForegroundColor Yellow

    # Tálcakeresés Bing letiltása
    Set-RegValue `
        -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
        -Name "BingSearchEnabled" `
        -Value 0

    # Cortana webes keresés letiltása
    Set-RegValue `
        -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
        -Name "CortanaConsent" `
        -Value 0

    # Allow search highlights (W11 újság/top stories letiltása)
    Set-RegValue `
        -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" `
        -Name "IsDynamicSearchBoxEnabled" `
        -Value 0

    # GPO szintű tiltás (minden felhasználóra)
    Set-RegValue `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "DisableWebSearch" `
        -Value 1

    Set-RegValue `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "ConnectedSearchUseWeb" `
        -Value 0

    # W11 Start menü Bing ajánlások letiltása
    if ($osBuild -ge 22000) {
        Write-Host "[*] Windows 11 Start menü Bing ajánlások letiltása..." -ForegroundColor Yellow
        Set-RegValue `
            -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
            -Name "Start_SearchFiles" `
            -Value 0

        Set-RegValue `
            -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" `
            -Name "DisableSearchBoxSuggestions" `
            -Value 1
    }
}
# ─── Windows 7 / 8 / 8.1 ─────────────────────────────────────────────────────
elseif ($osMajor -ge 6) {
    Write-Host "[*] Windows 7/8 Bing letiltása (ahol alkalmazható)..." -ForegroundColor Yellow

    Set-RegValue `
        -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Search" `
        -Name "SearchInternet" `
        -Value 0

    # IE alapú Bing az Intézőben
    Set-RegValue `
        -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" `
        -Name "DisableWebSearch" `
        -Value 1
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  KÉSZ! Változtatások életbe lépéséhez" -ForegroundColor Green
Write-Host "  ÚJRAINDÍTÁS ajánlott (vagy kijelentkezés)." -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
