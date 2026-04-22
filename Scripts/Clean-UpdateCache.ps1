# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---



# Clean-UpdateCache.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "--- Windows Update Cache törlése ---" -ForegroundColor Cyan

$services = @("wuauserv", "cryptSvc", "bits", "msiserver")

Write-Host "[*] Szolgáltatások leállítása..." -ForegroundColor Yellow
foreach ($svc in $services) {
    if ((Get-Service $svc).Status -eq 'Running') {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Write-Host "  - $svc leállítva" -ForegroundColor Gray
    }
}

$wuCachePath = "$env:SystemRoot\SoftwareDistribution\Download"
if (Test-Path $wuCachePath) {
    Write-Host "[*] Cache fájlok törlése..." -ForegroundColor Yellow
    Remove-Item -Path "$wuCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] SoftwareDistribution\Download kiürítve" -ForegroundColor Green
}

Write-Host "[*] Szolgáltatások újraindítása..." -ForegroundColor Yellow
foreach ($svc in $services) {
    Start-Service -Name $svc -ErrorAction SilentlyContinue
}

Write-Host "Kész!" -ForegroundColor Green


# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
