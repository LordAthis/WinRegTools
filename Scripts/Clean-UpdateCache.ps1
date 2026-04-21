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
