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
