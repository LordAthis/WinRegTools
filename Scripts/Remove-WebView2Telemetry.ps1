# --- Ébren tartás és Laptop figyelmeztetés ---
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags) | Out-Null
# --- Ébren tartás és Laptop figyelmeztetés ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "================================================" -ForegroundColor Red
Write-Host "   VESZELYES MUVESZET: WEBVIEW2 TELJES TORLESE" -ForegroundColor Red
Write-Host "================================================" -ForegroundColor Red
Write-Host " FIGYELEM! A WebView2 runtime eltavolitasa miatt" -ForegroundColor Yellow
Write-Host " az alabbi programok AZONNAL MUKODESKEPTELENNE" -ForegroundColor Yellow
Write-Host " valhatnak: MS Office, Teams, WhatsApp, Xbox App!" -ForegroundColor Yellow
Write-Host " De meg sok mas kulso alkalmazas is hasznalhatatlanna vallhat!" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Red

# Rendszergazdai jogkör ellenőrzése
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] HIBA: A szkriptet RENDSZERGAZDAKENT kell futtatni!" -ForegroundColor Red
    Exit
}

# 1. WebView2 folyamatok kényszerített leállítása .NET-tel
Write-Host ""
Write-Host " WebView2 hatterfolyamatok leallitasa..." -ForegroundColor Yellow
[System.Diagnostics.Process]::GetProcessesByName("msedgewebview2") | ForEach-Object {
    try {
        $_.Kill()
        Write-Host "  [OK] WebView2 folyamat kilove." -ForegroundColor Green
    } catch {}
}

# 2. Hivatalos WebView2 csendes uninstaller meghívása
Write-Host ""
Write-Host " Gyari WebView2 uninstaller keresese es inditasa..." -ForegroundColor Yellow
$programFiles = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86)
$wvInstallerPattern = "$programFiles\Microsoft\EdgeWebView\Application\*\Installer\setup.exe"
$wvInstallers = Resolve-Path $wvInstallerPattern -ErrorAction SilentlyContinue

foreach ($installer in $wvInstallers) {
    if (Test-Path $installer.Path) {
        Write-Host "  [!] Uninstaller inditasa: $($installer.Path)" -ForegroundColor Yellow
        # Speciális kapcsolók a rejtett WebView2 kényszerített eltávolításához
        Start-Process -FilePath $installer.Path -ArgumentList "--uninstall --msedgewebview --system-level --force-uninstall" -Wait -NoNewWindow
        Write-Host "  [OK] Gyari uninstaller lefutott." -ForegroundColor Green
    }
}

# 3. Drasztikus takarítás a lemezről .NET alapokon (maradványok)
Write-Host ""
Write-Host " Makacs maradvany mappak vegleges gyomlalasa..." -ForegroundColor Yellow
$appDataLocal = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData)
$programData = [System.Environment]::GetEnvironmentVariable("ProgramData")

$wvFolders = @(
    "$programFiles\Microsoft\EdgeWebView",
    "$appDataLocal\Microsoft\EdgeWebView",
    "$programData\Microsoft\EdgeWebView"
)

foreach ($folder in $wvFolders) {
    if ([System.IO.Directory]::Exists($folder)) {
        try {
            [System.IO.Directory]::Delete($folder, $true)
            Write-Host "  [OK] Mappa sikeresen torolve: $folder" -ForegroundColor Green
        } catch {
            Write-Host "  [HIBA] Zarolva vagy nem torolheto: $folder" -ForegroundColor Red
        }
    }
}

# 4. Újratelepítés letiltása a Registry-ben (.NET)
Write-Host ""
Write-Host " WebView2 visszatelepulesenek blokkolasa..." -ForegroundColor Yellow
try {
    $edgeUpdateKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Microsoft\EdgeUpdate", $true)
    if ($edgeUpdateKey) {
        # Megakadályozza, hogy a Windows Update vagy más MS szoftver csendben visszatelepítse
        $edgeUpdateKey.SetValue("DoNotUpdateToEdgeWithChromium", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
        $edgeUpdateKey.Close()
        Write-Host "  [OK] Registry blokkolas aktivalva." -ForegroundColor Green
    }
} catch {
    Write-Host "  [HIBA] Nem sikerult beirni a tiltast a Registry-be!" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Red
Write-Host " A WebView2 drasztikus torlese kesz. UJRAINDITAS!" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Red

# Alváskezelés visszaállítása alaphelyzetbe
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset) | Out-Null
