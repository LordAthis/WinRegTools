# --- Ébren tartás és Laptop figyelmeztetés ---
Write-Host "![FIGYELEM] Hosszu folyamat kovetkezik! Hasznalj TOLTOT!" -ForegroundColor Yellow
Write-Host "[*] Automatikus elalvas felfuggesztve..." -ForegroundColor Gray

# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru

# Futás alatt: Ébren tartás kényszerítése
$type::SetThreadExecutionState([uint32]0x80000001) 


Write-Host "--- Windows fogyasztoi elmenyek letiltasa ---" -ForegroundColor Cyan
$path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
if (-not (Test-Path $path)) { New-Item $path -Force }
Set-ItemProperty -Path $path -Name "DisableWindowsConsumerFeatures" -Value 1
Write-Host "Kesz." -ForegroundColor Green

# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState([uint32]0x80000000)
Write-Host "Kesz. Az energiagazdalkodasi korlatok feloldva." -ForegroundColor Gray
