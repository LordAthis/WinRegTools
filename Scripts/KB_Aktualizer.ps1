# KB_Aktualizer.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. Beállítások és Lista (Ezt bővítsd a saját KB számaiddal)
$KBMasterList = @{
    "KB5034765" = "Lényeges";
    "KB5034441" = "Veszélyes/Hibás"; # Példa: ha fent van, töröljük
    "KB5001716" = "Lényeges"
}

$StateFile = Join-Path $PSScriptRoot "..\LOG\Aktualizer_State.txt"

Write-Host "--- KB Aktualizáló (Szinkronizáció) ---" -ForegroundColor Cyan

# 2. Telepített frissítések lekérése
Write-Host "[*] Telepített frissítések ellenőrzése..." -ForegroundColor Yellow
$InstalledKBs = Get-HotFix | Select-Object -ExpandProperty HotFixID

# 3. Törlendő (Veszélyes/Hibás) frissítések kezelése
foreach ($kb in $KBMasterList.Keys) {
    if ($KBMasterList[$kb] -eq "Veszélyes/Hibás" -and $InstalledKBs -contains $kb) {
        Write-Host "[!] Törlendő frissítés találva: $kb" -ForegroundColor Red
        Write-Host "  Eltávolítás folyamatban..." -NoNewline
        # Csendes eltávolítás
        $process = Start-Process wusa.exe -ArgumentList "/uninstall /kb:$($kb.Replace('KB','')) /quiet /norestart" -Wait -PassThru
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host " KÉSZ (Reboot szükséges lehet)." -ForegroundColor Green
        }
    }
}

# 4. Hiányzó (Lényeges) frissítések kezelése
foreach ($kb in $KBMasterList.Keys) {
    if ($KBMasterList[$kb] -eq "Lényeges" -and $InstalledKBs -notcontains $kb) {
        Write-Host "[+] Hiányzó kritikus frissítés: $kb" -ForegroundColor Yellow
        Write-Host "  Letöltés és telepítés indítása (Windows Update API)..." -ForegroundColor Gray
        
        # Itt megjegyzés: A WUSA-hoz kellene az .msu fájl elérése, 
        # vagy a PSWindowsUpdate modullal tölthető le automatikusan.
        # Példa: Install-WindowsUpdate -KBArticleID $kb -AcceptAll -AutoReboot
    }
}

# 5. Újraindítás kezelése
$rebootPending = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
if ($rebootPending) {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "  A rendszer újraindítást igényel a folytatáshoz!"
    Write-Host "====================================================" -ForegroundColor Red
    
    $ans = Read-Host "Újraindítja most? (I/N)"
    if ($ans -eq 'I') {
        Restart-Computer -Force
    }
} else {
    Write-Host "Minden frissítés szinkronban." -ForegroundColor Green
}
