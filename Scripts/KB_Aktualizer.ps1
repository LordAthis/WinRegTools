# KB_Aktualizer.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. OS verzió azonosítása a megfelelő JSON kiválasztásához
$osName = switch -Regex ([System.Environment]::OSVersion.Version.ToString()) {
    "^10\.0\.22" { "W11" }
    "^10\.0\.19" { "W10" }
    "^6\.3"      { "W81" }
    "^6\.1"      { "W7" }
    default      { "Unknown" }
}

$JsonFile = Join-Path $PSScriptRoot "..\data\kb_lists$osName.json"

if (-not (Test-Path $JsonFile)) {
    Write-Host "[!!] Nem található a referencia lista: $JsonFile" -ForegroundColor Red
    return
}

# 2. JSON beolvasása
try {
    $KBData = Get-Content $JsonFile -Raw | ConvertFrom-Json
} catch {
    Write-Host "[!!] Hiba a JSON beolvasása közben!" -ForegroundColor Red
    return
}

Write-Host "--- KB Szinkronizáció ($osName) ---" -ForegroundColor Cyan

# 3. Telepített frissítések lekérdezése a gépben
$InstalledKBs = Get-HotFix | Select-Object -ExpandProperty HotFixID

# 4. KÁROS (harmful) frissítések eltávolítása
foreach ($item in $KBData.harmful) {
    $kb = $item.kb
    if ($InstalledKBs -contains $kb) {
        Write-Host "[!] Káros frissítés találva: $kb ($($item.desc))" -ForegroundColor Red
        Write-Host "  Eltávolítás: $($item.reason)" -ForegroundColor Gray
        
        # WUSA hívás az eltávolításhoz
        $kbNum = $kb.Replace("KB","")
        $proc = Start-Process wusa.exe -ArgumentList "/uninstall /kb:$kbNum /quiet /norestart" -Wait -PassThru
        
        if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
            Write-Host "  [OK] Sikeresen elküldve az eltávolító." -ForegroundColor Green
        }
    }
}

# 5. KÖTELEZŐ (required) frissítések ellenőrzése és pótlása
foreach ($item in $KBData.required) {
    $kb = $item.kb
    if ($InstalledKBs -notcontains $kb) {
        Write-Host "[+] Hiányzó kötelező frissítés: $kb" -ForegroundColor Yellow
        # Itt jöhet a telepítési logika (pl. ha van .msu fájl a /data/updates mappában)
        # Add-WindowsPackage -Online -PackagePath "..\data\updates\$kb.msu"
    }
}

Write-Host "Kész." -ForegroundColor Cyan
