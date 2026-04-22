# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---


# Clean-Logs.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$LogPath = Join-Path $PSScriptRoot "..\LOG"
$Days = 30

Write-Host "--- Log fájlok takarítása ($Days napnál régebbiek) ---" -ForegroundColor Cyan

if (Test-Path $LogPath) {
    $OldFiles = Get-ChildItem -Path $LogPath -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$Days) }
    
    if ($OldFiles) {
        foreach ($file in $OldFiles) {
            Write-Host "  Törlés: $($file.Name)" -ForegroundColor Gray
            Remove-Item $file.FullName -Force
        }
        Write-Host "[OK] Takarítás kész." -ForegroundColor Green
    } else {
        Write-Host "Nincs torlendo regi log fajl." -ForegroundColor Gray
    }
}


# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
