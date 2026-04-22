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


# KB_Aktualizer.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 1. OS és Fájlkezelés
$osVersion = [System.Environment]::OSVersion.Version
$osKey = ""; $fileNamePart = ""

if ($osVersion.Major -eq 10) {
    if ($osVersion.Build -ge 22000) { $osKey = "Windows_11"; $fileNamePart = "W11" }
    else { $osKey = "Windows_10"; $fileNamePart = "W10" }
}
elseif ($osVersion.Major -eq 6 -and $osVersion.Minor -eq 1) { $osKey = "Windows_7"; $fileNamePart = "W7" }
elseif ($osVersion.Major -eq 5 -and $osVersion.Minor -eq 1) { $osKey = "Windows_Xp"; $fileNamePart = "Xp" }

$JsonFile = Join-Path $PSScriptRoot "..\data\KB_Lists$fileNamePart.json"
$UpdateStorage = Join-Path $PSScriptRoot "..\data\KB"

if (-not (Test-Path $JsonFile)) { Write-Host "[!!] Lista nem található: $JsonFile" -ForegroundColor Red; return }
if (-not (Test-Path $UpdateStorage)) { New-Item -ItemType Directory -Path $UpdateStorage -Force | Out-Null }

$KBData = (Get-Content $JsonFile -Raw | ConvertFrom-Json).$osKey
$InstalledKBs = Get-HotFix | Select-Object -ExpandProperty HotFixID

# Szükséges a Windows Update Session az elrejtéshez/kereséshez
$UpdateSession = New-Object -ComObject Microsoft.Update.Session
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

Write-Host "--- KB Szinkronizáció és Tiltólista ($osKey) ---" -ForegroundColor Cyan

# 2. KÁROS frissítések eltávolítása és TILTÁSA
foreach ($item in $KBData.harmful) {
    $kbID = $item.kb
    if ($InstalledKBs -contains $kbID) {
        Write-Host "[!] Eltávolítás: $kbID ($($item.reason))" -ForegroundColor Red
        $kbNum = $kbID.Replace("KB","")
        Start-Process wusa.exe -ArgumentList "/uninstall /kb:$kbNum /quiet /norestart" -Wait
    }
    
    # TILTÓLISTÁRA TÉTEL (Elrejtés a Windows Update elől)
    Write-Host "[*] $kbID hozzáadása a tiltólistához (elrejtés)..." -ForegroundColor Gray
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0 and IsHidden=0 and Title string '$kbID'")
    foreach ($update in $SearchResult.Updates) {
        $update.IsHidden = $true
        Write-Host "  [OK] $kbID elrejtve." -ForegroundColor Green
    }
}

# 3. KÖTELEZŐ frissítések pótlása (Helyi -> Letöltés -> Telepítés)
foreach ($item in $KBData.required) {
    $kbID = $item.kb
    if ($InstalledKBs -notcontains $kbID) {
        Write-Host "[+] Hiányzó kötelező: $kbID" -ForegroundColor Yellow
        $localFile = Join-Path $UpdateStorage "$kbID.msu"
        
        if (Test-Path $localFile) {
            Write-Host "  Telepítés helyi fájlból..." -ForegroundColor Gray
            Start-Process wusa.exe -ArgumentList "`"$localFile`" /quiet /norestart" -Wait
        } else {
            Write-Host "  [!] Helyi fájl nincs. Letöltés indítása (WinUpd API)..." -ForegroundColor Blue
            # Megjegyzés: A közvetlen API letöltés bonyolultabb, de a keresést lefuttatjuk
            $SearchResult = $UpdateSearcher.Search("BundleContains '$kbID'")
            if ($SearchResult.Updates.Count -gt 0) {
                 Write-Host "  Frissítés megtalálva az online kiszolgálón. Kérlek telepítsd manuálisan vagy használd a PSWindowsUpdate modult." -ForegroundColor Cyan
            }
        }
    }
}

Write-Host "Művelet véget ért." -ForegroundColor Cyan


# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kész. Az energiagazdálkodási korlátok feloldva." -ForegroundColor Gray
