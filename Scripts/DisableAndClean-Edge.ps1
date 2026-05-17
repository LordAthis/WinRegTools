# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags) | Out-Null
# --- Ébren tartás és Laptop figyelmeztetés ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   MICROSOFT EDGE ELTAVOLITASA ES LETILTASA" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Rendszergazdai jogkör ellenőrzése
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] HIBA: A szkriptet RENDSZERGAZDAKENT kell futtatni!" -ForegroundColor Red
    Exit
}

# 1. Edge folyamatok drasztikus leállítása .NET segítségével
Write-Host "[1] Microsoft Edge folyamatok leallitasa..." -ForegroundColor Yellow
$edgeProcesses = @("msedge", "MicrosoftEdge", "MicrosoftEdgeCP")
foreach ($proc in $edgeProcesses) {
    # .NET-en keresztül kérjük le és lőjük le a folyamatokat
    [System.Diagnostics.Process]::GetProcessesByName($proc) | ForEach-Object {
        try {
            $_.Kill()
            Write-Host "  [OK] Folyamat leallitva: $proc" -ForegroundColor Green
        } catch {}
    }
}

# 2. Edge-hez kapcsolódó szolgáltatások és frissítők letiltása .NET-tel
Write-Host ""
Write-Host "[2] Edge szolgaltatasok letiltasa .NET-en keresztul..." -ForegroundColor Yellow
$edgeServices = @("edgeupdate", "edgeupdatem", "MicrosoftEdgeElevationService")

$servicesKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Services", $true)
foreach ($svc in $edgeServices) {
    if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
        try {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            $svcKey = $servicesKey.OpenSubKey($svc, $true)
            if ($svcKey) {
                # Start = 4 jelenti a Letiltott (Disabled) állapotot
                $svcKey.SetValue("Start", 4, [Microsoft.Win32.RegistryValueKind]::DWord)
                $svcKey.Close()
                Write-Host "  [OK] Szolgaltatas letiltva: $svc" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [HIBA] Nem sikerult letiltani a(z) $svc szolgaltatast!" -ForegroundColor Red
        }
    }
}
if ($servicesKey) { $servicesKey.Close() }

# 3. Ütemezett feladatok eltávolítása
Write-Host ""
Write-Host "[3] Edge utemezett feladatok eltavolitasa..." -ForegroundColor Yellow
Get-ScheduledTask -TaskPath "\" -ErrorAction SilentlyContinue | Where-Object { $_.TaskName -like "*Edge*" } | ForEach-Object {
    try {
        Unregister-ScheduledTask -TaskName $_.TaskName -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "  [OK] Utemezett feladat torolve: $($_.TaskName)" -ForegroundColor Green
    } catch {}
}

# 4. Beépített uninstaller meghívása (ha létezik hivatalos útvonalon)
Write-Host ""
Write-Host "[4] Hivatalos Edge Uninstaller keresese es inditasa..." -ForegroundColor Yellow
$programFiles = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86)
$installerPattern = "$programFiles\Microsoft\Edge\Application\*\Installer\setup.exe"
$installers = Resolve-Path $installerPattern -ErrorAction SilentlyContinue

foreach ($installer in $installers) {
    if (Test-Path $installer.Path) {
        Write-Host "  [!] Uninstaller inditasa: $($installer.Path)" -ForegroundColor Yellow
        # Csendes, kényszerített eltávolítás rendszerszinten
        Start-Process -FilePath $installer.Path -ArgumentList "--uninstall --system-level --force-uninstall" -Wait -NoNewWindow
        Write-Host "  [OK] Uninstaller lefutott." -ForegroundColor Green
    }
}

# 5. Maradvány mappák és adatok törlése a lemezről
Write-Host ""
Write-Host "[5] Maradvany fajlok es mappak takaritasa..." -ForegroundColor Yellow
$userProfile = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::UserProfile)
$appDataLocal = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)

$targetFolders = @(
    "$programFiles\Microsoft\Edge",
    "$programFiles\Microsoft\EdgeUpdate",
    "$programFiles\Microsoft\EdgeWebView",
    "$appDataLocal\Microsoft\Edge",
    "$userProfile\Desktop\Microsoft Edge.lnk" # Asztali ikon ha megmaradt volna
)

foreach ($folder in $targetFolders) {
    if (Test-Path $folder) {
        try {
            # .NET alapú könyvtár/fájl törlés a makacs maradványok ellen
            if ([System.IO.Directory]::Exists($folder)) {
                [System.IO.Directory]::Delete($folder, $true)
            } elseif ([System.IO.File]::Exists($folder)) {
                [System.IO.File]::Delete($folder)
            }
            Write-Host "  [OK] Sikeresen torolve: $folder" -ForegroundColor Green
        } catch {
            Write-Host "  [HIBA] Nem sikerult torolni, valoszinuleg zarolt: $folder" -ForegroundColor Red
        }
    }
}

# 6. Re-installáció és automatikus frissítés végleges letiltása Registry-ben (.NET)
Write-Host ""
Write-Host "[6] Edge automatikus visszatelepitesenek letiltasa (Registry)..." -ForegroundColor Yellow
try {
    $edgeUpdateKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Microsoft\EdgeUpdate", $true)
    if ($edgeUpdateKey) {
        # Letiltja, hogy a Windows Update önhatalmúan visszarakja a sima Edge-et Chromium alapon
        $edgeUpdateKey.SetValue("DoNotUpdateToEdgeWithChromium", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
        $edgeUpdateKey.Close()
        Write-Host "  [OK] Registry frissites-gatlo beallitva." -ForegroundColor Green
    }
} catch {
    Write-Host "  [HIBA] Nem sikerult beirni a Registry frissites-gatlo kulcsot!" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " Az Edge pucolasa befejezodott. UJRAINDITAS JAVASOLT!" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan

# Alváskezelés visszaállítása alaphelyzetbe
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset) | Out-Null
