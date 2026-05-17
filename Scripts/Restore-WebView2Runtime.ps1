# --- Ébren tartás és Laptop figyelmeztetés ---
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags) | Out-Null
# --- Ébren tartás és Laptop figyelmeztetés ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   WEBVIEW2 FUTTATOKORNYEZET REINSTALL / UPDATE" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Rendszergazdai jogkör ellenőrzése
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] HIBA: A szkriptet RENDSZERGAZDAKENT kell futtatni!" -ForegroundColor Red
    Exit
}

# 1. Előző blokkolások feloldása a Registry-ben az újratelepítés idejére (.NET)
Write-Host " Telepitesi blokkolasok ideiglenes feloldasa..." -ForegroundColor Yellow
$servicesKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Services", $true)
$edgeUpdateKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\EdgeUpdate", $true)

# Ha korábban le lettek tiltva az edgeupdate szolgáltatások, most visszaállítjuk Manuálisra (3)
$edgeServices = @("edgeupdate", "edgeupdatem")
foreach ($svc in $edgeServices) {
    if ($servicesKey) {
        $svcKey = $servicesKey.OpenSubKey($svc, $true)
        if ($svcKey) {
            $svcKey.SetValue("Start", 3, [Microsoft.Win32.RegistryValueKind]::DWord)
            $svcKey.Close()
        }
    }
}
# Átmenetileg töröljük a visszatelepítést gátló kulcsot, különben az installer hibával leáll
if ($edgeUpdateKey) {
    try {
        $edgeUpdateKey.DeleteValue("DoNotUpdateToEdgeWithChromium", $false)
    } catch {}
}

# 2. Hivatalos Microsoft Evergreen Bootstrapper letöltése
Write-Host ""
Write-Host " Legfrissebb WebView2 Bootstrapper letoltese a Microsoft-tol..." -ForegroundColor Yellow
$downloadUrl = "https://microsoft.com"
$tempInstaller = Join-Path $env:TEMP "MicrosoftEdgeWebview2Setup.exe"

try {
    # .NET WebClient alapú letöltés Invoke-WebRequest helyett (gyorsabb és stabilabb)
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, $tempInstaller)
    Write-Host "  [OK] Telepito sikeresen letoltve." -ForegroundColor Green
} catch {
    Write-Host "  [HIBA] Nem sikerult letolteni a telepitofajlt!" -ForegroundColor Red
    Exit
}

# 3. Csendes és kényszerített telepítés indítása
Write-Host ""
Write-Host " Tiszta ujratelepites es frissites inditasa hatterben..." -ForegroundColor Yellow
if (Test-Path $tempInstaller) {
    # /silent kapcsoló az első helyen kötelező a Microsoft bugok elkerülése végett
    $installArgs = "/silent /install"
    $process = Start-Process -FilePath $tempInstaller -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 1223) {
        Write-Host "  [OK] WebView2 Runtime sikeresen ujratelepitve / frissitve." -ForegroundColor Green
    } else {
        Write-Host "  [!] A telepites lefutott, de egyedi koddal tert vissza: $($process.ExitCode)" -ForegroundColor Yellow
    }
    
    # Ideiglenes fájl takarítása
    try { [System.IO.File]::Delete($tempInstaller) } catch {}
}

# 4. Kémkedés és telemetria AZONNALI visszazárása (.NET)
Write-Host ""
Write-Host " Adatgyujtes es kovetes ujbuli letiltasa (Registry)..." -ForegroundColor Yellow
try {
    # Telemetria zsilip lezárása
    $edgePolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\Edge", $true)
    if ($edgePolicyKey) {
        $edgePolicyKey.SetValue("MetricsReportingEnabled", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $edgePolicyKey.Close()
    }
    
    # Önhatalmú frissítési ciklusok letiltása (csak az alkalmazások hívhatják meg a motort)
    $updatePolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\EdgeUpdate", $true)
    if ($updatePolicyKey) {
        $updatePolicyKey.SetValue("Update{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $updatePolicyKey.Close()
    }

    # Visszatelepítés-gátló kulcs újbóli élesítése a jövőbeli Windows Update-ek ellen
    if ($edgeUpdateKey) {
        $edgeUpdateKey.SetValue("DoNotUpdateToEdgeWithChromium", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
    }
    Write-Host "  [OK] Vedelmi es telemetria-tiltasi szintek visszaallitva." -ForegroundColor Green
} catch {
    Write-Host "  [HIBA] Nem sikerult minden telemetria kulcsot visszazarani!" -ForegroundColor Red
}

# Erőforrások lezárása
if ($servicesKey) { $servicesKey.Close() }
if ($edgeUpdateKey) { $edgeUpdateKey.Close() }

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " A WebView2 helyreallitasa kesz. UJRAINDITAS JAVASOLT!" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan

# Alváskezelés visszaállítása alaphelyzetbe
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset) | Out-Null
