# --- 1. ADMIN JOG ÉS LOG KÖRNYEZET ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$LogFile = "$env:TEMP\WinNewsDisable_Log.txt"
"--- Log inditva: $(Get-Date) ---" | Out-File $LogFile

function Write-Step($msg, $color = "White") {
    $txt = "[$(Get-Date -Format "HH:mm:ss")] $msg"
    Write-Host $txt -ForegroundColor $color
    $txt | Out-File $LogFile -Append
}

Write-Step "--- RENDSZERSZINTU ELLENORZES ES TILTAS ---" Cyan

# --- 2. REGISTRY MECHAJTOK CSATOLASA ---
if (!(Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
    New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null
}

# --- 3. CSOMAGOK ELTAVOLITASA ES ELLENORZESE ---
$targetPkg = "*WebExperience*"
Write-Step "Csomag keresese: $targetPkg..."
$pkg = Get-AppxPackage -AllUsers $targetPkg

if ($pkg) {
    Write-Step "Csomag megtalalva, torles..." Yellow
    try {
        Get-AppxPackage -AllUsers $targetPkg | Remove-AppxPackage -AllUsers -ErrorAction Stop
        Get-AppxProvisionedPackage -Online | Where-Object {$_.PackageName -like $targetPkg} | Remove-AppxProvisionedPackage -Online -ErrorAction Stop
        Write-Step "  [OK] Torlesi parancs sikeres." Green
    } catch {
        Write-Step "  [HIBA] Nem sikerult a teljes torles: $($_.Exception.Message)" Red
    }
} else {
    Write-Step "  [INFO] A csomag nincs a rendszerben." Gray
}

# --- 4. REGISTRY POLICIES ELLENORZESE ---
$regChecks = @(
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"; Name="EnableFeeds"; Value=0; Desc="Win10 Hirek"},
    @{Path="HKLM:\SOFTWARE\Policies\Microsoft\Dsh"; Name="AllowNewsAndInterests"; Value=0; Desc="Win11/10 Hirek Policy"}
)

$globalSuccess = $true

foreach ($reg in $regChecks) {
    Write-Step "Ellenorzes: $($reg.Desc)..."
    if (-not (Test-Path $reg.Path)) { New-Item -Path $reg.Path -Force | Out-Null }
    
    Set-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -Type DWord -Force
    
    $val = (Get-ItemProperty -Path $reg.Path -Name $reg.Name -ErrorAction SilentlyContinue).$($reg.Name)
    if ($val -eq $reg.Value) {
        Write-Step "  [OK] Registry ertek beallitva." Green
    } else {
        Write-Step "  [KRITIKUS HIBA] A Registry nem tartotta meg az erteket!" Red
        $globalSuccess = $false
    }
}

# Felhasznaloi profilok kényszerítése
$users = Get-ChildItem "HKU:\" | Where-Object { $_.Name -match "S-1-5-21-\d+-\d+-\d+-\d+$" }
foreach ($u in $users) {
    $feedPath = "HKU:\$($u.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Feeds"
    if (Test-Path $feedPath) {
        Set-ItemProperty -Path $feedPath -Name "ShellFeedsTaskbarViewMode" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
    }
}

# --- 5. ZARO ELLENORZES ---
Write-Step "Explorer ujrainditasa..." Yellow
Stop-Process -Name explorer -Force
Start-Sleep -Seconds 2

if ($globalSuccess) {
    Write-Step "=== KESZ: A beallitasok sikeresen ervenyesitve lettek. ===" Green
} else {
    Write-Step "=== FIGYELEM: Nehany beallitas nem sikerult! Ellenorizd a naplot: $LogFile ===" Red
}

# --- 6. ÚJRAINDÍTÁS KÉRÉSE ---
Write-Host ""
$choice = Read-Host "A tökéletes eredmény érdekében érdemes újraindítani a gépet. Újraindítunk? (I/N)"

if ($choice -eq "I" -or $choice -eq "i") {
    Write-Host "Újraindítás folyamatban..." -ForegroundColor Yellow
    Restart-Computer
} else {
    Write-Host "Az újraindítás elhalasztva. A változások teljes körűen a következő belépéskor érvényesülnek." -ForegroundColor Gray
}

