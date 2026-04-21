# Update-KBList.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$LogPath = Join-Path $PSScriptRoot "..\LOG"
# Megkeressük a legfrissebb KB logot
$LatestLog = Get-ChildItem -Path $LogPath -Filter "*KB_Checker*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

Write-Host "--- KB Lista Aktualizálása ---" -ForegroundColor Cyan

if ($null -eq $LatestLog) {
    Write-Host "[-] Nem található KB Checker log. Előbb futtasd a 10-es menüpontot!" -ForegroundColor Red
    return
}

Write-Host "[*] Forrás log: $($LatestLog.Name)" -ForegroundColor Gray

# Itt a log feldolgozása következik (példa):
$LogContent = Get-Content $LatestLog.FullName
# Itt fogod tudni kinyerni a szükséges adatokat és frissíteni a listát
# Pl.: $KBs = $LogContent | Select-String "KB\d+"

Write-Host "[!] Az aktualizálási logika fejlesztés alatt (a log formátumától függően)." -ForegroundColor Yellow
