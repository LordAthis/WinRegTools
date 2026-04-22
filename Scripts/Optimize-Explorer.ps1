# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---


Write-Host "--- Fajlkezelo optimalizalasa ---" -ForegroundColor Cyan
# Fájlkiterjesztések mutatása
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
# "Ez a gép" megnyitása a Gyorselérés helyett
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
Write-Host "Kesz." -ForegroundColor Green


# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
