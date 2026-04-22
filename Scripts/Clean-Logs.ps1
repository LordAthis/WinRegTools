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


# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kesz. Az energiagazdalkodasi korlatok feloldva." -ForegroundColor Gray
