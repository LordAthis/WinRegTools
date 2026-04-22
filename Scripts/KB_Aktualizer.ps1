# KB_Aktualizer.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. OS beazonosítása a fájlnévhez és a JSON kulcshoz
$osVersion = [System.Environment]::OSVersion.Version
$osKey = ""
$fileNamePart = ""

if ($osVersion.Major -eq 10) {
    if ($osVersion.Build -ge 22000) { $osKey = "Windows_11"; $fileNamePart = "W11" }
    else { $osKey = "Windows_10"; $fileNamePart = "W10" }
}
elseif ($osVersion.Major -eq 6) {
    if ($osVersion.Minor -eq 1) { $osKey = "Windows_7"; $fileNamePart = "W7" }
    elseif ($osVersion.Minor -eq 3) { $osKey = "Windows_81"; $fileNamePart = "W81" }
}

$JsonFile = Join-Path $PSScriptRoot "..\data\KB_Lists$fileNamePart.json"

if (-not (Test-Path $JsonFile)) {
    Write-Host "[!!] Hiányzó fájl: $JsonFile" -ForegroundColor Red
    return
}

# 2. JSON beolvasása és a konkrét OS szekció kinyerése
try {
    $RawData = Get-Content $JsonFile -Raw | ConvertFrom-Json
    $KBData = $RawData.$osKey  # Itt dinamikusan hivatkozunk pl. a "Windows_10" kulcsra
} catch {
    Write-Host "[!!] Hiba a JSON feldolgozásakor!" -ForegroundColor Red
    return
}

Write-Host "--- KB Szinkronizáció ($osKey) ---" -ForegroundColor Cyan

# 3. Telepített KB-k listája
$InstalledKBs = Get-HotFix | Select-Object -ExpandProperty HotFixID

# 4. KÁROS (harmful) frissítések takarítása
foreach ($item in $KBData.harmful) {
    if ($InstalledKBs -contains $item.kb) {
        Write-Host "[!] Eltávolítás: $($item.kb) - $($item.desc)" -ForegroundColor Red
        $kbNum = $item.kb.Replace("KB","")
        # Automata eltávolítás
        Start-Process wusa.exe -ArgumentList "/uninstall /kb:$kbNum /quiet /norestart" -Wait
        Write-Host "    Kész." -ForegroundColor Gray
    }
}

# 5. KÖTELEZŐ (required) frissítések ellenőrzése
foreach ($item in $KBData.required) {
    if ($InstalledKBs -notcontains $item.kb) {
        Write-Host "[+] Hiányzó kötelező: $($item.kb)" -ForegroundColor Yellow
        # Ide jöhet a telepítő parancsod
    }
}

Write-Host "Művelet véget ért." -ForegroundColor Cyan
