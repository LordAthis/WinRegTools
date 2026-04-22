# --- Ébren tartás és Laptop figyelmeztetés ---
Write-Host "![FIGYELEM] Hosszu folyamat kovetkezik! Hasznalj TOLTOT!" -ForegroundColor Yellow
Write-Host "[*] Automatikus elalvas felfuggesztve..." -ForegroundColor Gray

# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru

# Futás alatt: Ébren tartás kényszerítése
$type::SetThreadExecutionState([uint32]0x80000001) 


Write-Host "--- Talca Hirek es Erdeklodes letiltasa ---" -ForegroundColor Cyan
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
if (-not (Test-Path $path)) { New-Item $path -Force }
Set-ItemProperty -Path $path -Name "ShellFeedsTaskbarViewMode" -Value 2 -Force
Write-Host "Kesz. (Kijelentkezes utan ervenyes)" -ForegroundColor Green



# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState([uint32]0x80000000)
Write-Host "Kesz. Az energiagazdalkodasi korlatok feloldva." -ForegroundColor Gray
