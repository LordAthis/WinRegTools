# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---


Write-Host "--- Talca Hirek es Erdeklodes letiltasa ---" -ForegroundColor Cyan
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
if (-not (Test-Path $path)) { New-Item $path -Force }
Set-ItemProperty -Path $path -Name "ShellFeedsTaskbarViewMode" -Value 2 -Force
Write-Host "Kesz. (Kijelentkezes utan ervenyes)" -ForegroundColor Green


# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
