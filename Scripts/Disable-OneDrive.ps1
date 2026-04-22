# Disable-OneDrive.ps1 - LordAthis RTS Framework
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- RTS Framework - Sleep Prevention (Stabil) ---
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags) | Out-Null

Write-Host "--- ONEDRIVE ELTAVOLITASA ES LETILTASA ---" -ForegroundColor Cyan

# 1. OneDrive folyamatok leallitasa
Write-Host "[*] OneDrive folyamatok leallitasa..." -ForegroundColor Yellow
Stop-Process -Name "OneDrive" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# 2. Uninstall futtatasa
Write-Host "[*] OneDrive eltavolitasa a rendszerbol..." -ForegroundColor Yellow
$osType = [Environment]::Is64BitOperatingSystem
$uninstallPath = if ($osType) { "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" } else { "$env:SystemRoot\System32\OneDriveSetup.exe" }

if (Test-Path $uninstallPath) {
    Start-Process $uninstallPath -ArgumentList "/uninstall" -Wait
    Write-Host "  [OK] Uninstall folyamat lefutott." -ForegroundColor Green
} else {
    Write-Host "  [-] OneDriveSetup nem talalhato." -ForegroundColor Gray
}

# 3. Registry tiltas es Intezo ikon elrejtese
Write-Host "[*] Registry tiltasok beallitasa..." -ForegroundColor Yellow

$policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
if (-not (Test-Path $policyPath)) { New-Item $policyPath -Force | Out-Null }
Set-ItemProperty -Path $policyPath -Name "DisableFileSyncNGSC" -Value 1 -Type DWord -Force

$clsid = "{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
$regPath = "HKCU:\Software\Classes\CLSID\$clsid"
if (Test-Path $regPath) {
    Set-ItemProperty -Path $regPath -Name "System.IsPinnedToNameSpaceTree" -Value 0 -Type DWord -Force
    Write-Host "  [OK] OneDrive ikon elrejtve." -ForegroundColor Green
}

Write-Host "--- KESZ ---" -ForegroundColor Green

# --- Sleep State visszaallitasa ---
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset) | Out-Null
