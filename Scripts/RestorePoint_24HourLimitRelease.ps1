# Kódolás kényszerítése az aktuális munkamenetben
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Ez a trükk: megmondjuk a PowerShellnek, hogy minden scriptet UTF8-ként olvasson be a lemezről
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# RestorePoint_24HourLimitRelease.ps1

$path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
$name = "SystemRestorePointCreationFrequency"
$value = 0

Write-Host "--- Rendszer-visszaállítási korlát feloldása ---" -ForegroundColor Cyan

try {
    Write-Host "Regisztrációs adatbázis módosítása folyamatban..." -NoNewline
    
    # Itt javítottam az idézőjelet a Path végén
    Set-ItemProperty -Path $path -Name $name -Value $value -Force -ErrorAction Stop
    
    Write-Host " KÉSZ." -ForegroundColor Green
    Write-Host "A 24 órás limit sikeresen kikapcsolva (Érték: 0)." -ForegroundColor Gray
}
catch {
    Write-Host " HIBA!" -ForegroundColor Red
    Write-Host "Nem sikerült a módosítás. Ellenőrizd a rendszergazdai jogosultságot!" -ForegroundColor Yellow
    Write-Host "Hibaüzenet: $($_.Exception.Message)"
}

Write-Host "Művelet befejezve, kilépés..." -ForegroundColor Cyan
