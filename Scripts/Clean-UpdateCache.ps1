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


# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kész. Az energiagazdalkodasi korlatok feloldva." -ForegroundColor Gray
