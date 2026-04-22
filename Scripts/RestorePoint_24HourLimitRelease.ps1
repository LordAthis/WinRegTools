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


# Kódolás kényszerítése az aktuális munkamenetben
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# --- ÖN-EMELTETÉS (Admin check) ---
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Nincs rendszergazdai jogosultság. Újraindítás emelt szinten..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- FŐ PROGRAM ---
$path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
$name = "SystemRestorePointCreationFrequency"
$value = 0

# Ellenőrizzük, létezik-e az útvonal (biztonsági játék)
if (-not (Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}

Write-Host "`n--- Rendszer-visszaállítási korlát feloldása ---" -ForegroundColor Cyan

try {
    Write-Host "Regisztrációs adatbázis módosítása folyamatban..." -NoNewline
    
    Set-ItemProperty -Path $path -Name $name -Value $value -Force -ErrorAction Stop
    
    Write-Host " KÉSZ." -ForegroundColor Green
    Write-Host "A 24 órás limit sikeresen kikapcsolva (Érték: 0)." -ForegroundColor Gray
}
catch {
    Write-Host " HIBA!" -ForegroundColor Red
    Write-Host "Nem sikerült a módosítás." -ForegroundColor Yellow
    Write-Host "Hibaüzenet: $($_.Exception.Message)"
}

Write-Host "Művelet befejezve, kilépés 3 másodperc múlva..." -ForegroundColor Cyan
Start-Sleep -Seconds 3



# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kész. Az energiagazdálkodási korlátok feloldva." -ForegroundColor Gray
