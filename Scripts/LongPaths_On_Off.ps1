# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---


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


# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
