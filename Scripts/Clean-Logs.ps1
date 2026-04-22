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
        Write-Host "Nincs törlendő régi log fájl." -ForegroundColor Gray
    }
}
