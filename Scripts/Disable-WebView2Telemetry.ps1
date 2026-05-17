# --- Ébren tartás és Laptop figyelmeztetés ---
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags) | Out-Null
# --- Ébren tartás és Laptop figyelmeztetés ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   WEBVIEW2 TELEMETRIA ES FRISSITES LETILTASA" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Rendszergazdai jogkör ellenőrzése
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] HIBA: A szkriptet RENDSZERGAZDAKENT kell futtatni!" -ForegroundColor Red
    Exit
}

# 1. Telemetria és adatgyűjtés tiltása a Registry-ben (.NET)
Write-Host " WebView2 telemetria es adatgyujtes letiltasa..." -ForegroundColor Yellow
try {
    $edgePolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\Edge", $true)
    if ($edgePolicyKey) {
        # Kijelölt diagnosztikai adatok küldésének teljes letiltása (0)
        $edgePolicyKey.SetValue("MetricsReportingEnabled", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $edgePolicyKey.Close()
        Write-Host "  [OK] Diagnosztikai adatkuldes letiltva." -ForegroundColor Green
    }
} catch {
    Write-Host "  [HIBA] Nem sikerult beirni a telemetria tiltast a Registry-be!" -ForegroundColor Red
}

# 2. Automatikus WebView2 frissítések letiltása (.NET)
Write-Host ""
Write-Host " WebView2 hatter-frissitesek leallitasa..." -ForegroundColor Yellow
try {
    $updatePolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\EdgeUpdate", $true)
    if ($updatePolicyKey) {
        # Kikapcsolja a WebView2 önálló frissítési ciklusait (0 = Updates disabled)
        $updatePolicyKey.SetValue("Update{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $updatePolicyKey.Close()
        Write-Host "  [OK] WebView2 automatikus frissitese kikapcsolva." -ForegroundColor Green
    }
} catch {
    Write-Host "  [HIBA] Nem sikerult beirni a frissites-tiltast!" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " A telemetria tiltasa kesz. UJRAINDITAS JAVASOLT!" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan

# Alváskezelés visszaállítása alaphelyzetbe
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset) | Out-Null
