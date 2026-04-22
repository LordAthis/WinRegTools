# --- Ébren tartás és Laptop figyelmeztetés ---
Write-Host "![FIGYELEM] Hosszu folyamat kovetkezik! Hasznalj TOLTOT!" -ForegroundColor Yellow
Write-Host "[*] Automatikus elalvas felfuggesztve..." -ForegroundColor Gray

# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru

# Futás alatt: Ébren tartás kényszerítése
$type::SetThreadExecutionState([uint32]0x80000001) 


Write-Host "--- Fajlkezelo optimalizalasa ---" -ForegroundColor Cyan
# Fájlkiterjesztések mutatása
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
# "Ez a gép" megnyitása a Gyorselérés helyett
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "LaunchTo" -Value 1
Write-Host "Kesz." -ForegroundColor Green


# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState([uint32]0x80000000)
Write-Host "Kesz. Az energiagazdalkodasi korlatok feloldva." -ForegroundColor Gray
