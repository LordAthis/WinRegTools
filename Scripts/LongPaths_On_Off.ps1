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


# UTF-8 kódolás kényszerítése a kimeneten
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Rendszergazdai jog ellenőrzése és kérése
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$path = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$name = "LongPathsEnabled"

# Aktuális állapot lekérdezése
$currentVal = Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
$status = if ($currentVal.$name -eq 1) { "BEKAPCSOLVA" } else { "KIKAPCSOLVA" }

Write-Host "--- Hosszú elérési utak (MAX_PATH) állapota ---" -ForegroundColor Cyan
Write-Host "Jelenlegi állapot: $status" -ForegroundColor Yellow

$choice = Read-Host "Szeretnéd megváltoztatni? (I/N)"
if ($choice -eq "I" -or $choice -eq "i") {
    $newVal = if ($currentVal.$name -eq 1) { 0 } else { 1 }
    Set-ItemProperty -Path $path -Name $name -Value $newVal
    Write-Host "Változtatás sikeres! Új állapot: $(if ($newVal -eq 1) {'BE'} else {'KI'})" -ForegroundColor Green
} else {
    Write-Host "Nem történt módosítás."
}
Pause


# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kész. Az energiagazdálkodási korlátok feloldva." -ForegroundColor Gray
