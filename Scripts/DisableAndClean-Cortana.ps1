# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags) | Out-Null
# --- Ébren tartás és Laptop figyelmeztetés ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "     CORTANA ASSZISZTENS TELJES ELTAVOLITASA" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Rendszergazdai jogkör ellenőrzése
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] HIBA: A szkriptet RENDSZERGAZDAKENT kell futtatni!" -ForegroundColor Red
    Exit
}

# 1. Cortana háttérfolyamatok leállítása .NET segítségével
Write-Host " Cortana hatterfolyamatok leallitasa..." -ForegroundColor Yellow
[System.Diagnostics.Process]::GetProcessesByName("Cortana") | ForEach-Object {
    try {
        $_.Kill()
        Write-Host "  [OK] Cortana folyamat kilove." -ForegroundColor Green
    } catch {}
}

# 2. Cortana Modern App (UWP) csomagok eltávolítása minden felhasználónál
Write-Host ""
Write-Host " Cortana UWP csomagok kigyomlalasa..." -ForegroundColor Yellow
$cortanaPackage = "*Microsoft.549981C3F5F10*" # Ez a Cortana hivatalos AppX azonosítója

# Felhasználói példányok törlése
Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $cortanaPackage } | ForEach-Object {
    try {
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host "  [OK] Cortana alkalmazas eltavolitva." -ForegroundColor Green
    } catch {
        Write-Host "  [HIBA] Nem sikerult eltavolitani a Cortana csomagot!" -ForegroundColor Red
    }
}

# Rendszer-szintű előkészített csomag törlése (hogy új profiloknál se jöjjön vissza)
Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $cortanaPackage } | ForEach-Object {
    try {
        Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop
        Write-Host "  [OK] Elokeszitett Cortana csomag torolve." -ForegroundColor Green
    } catch {}
}

# 3. Cortana és hangalapú keresés rendszerszintű letiltása a Registry-ben (.NET)
Write-Host ""
Write-Host " Cortana funkciok vegleges letiltasa a Registry-ben..." -ForegroundColor Yellow
try {
    # Windows Search házirendek (Cortana letiltása a keresőben)
    $searchPolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\Windows\Windows Search", $true)
    if ($searchPolicyKey) {
        $searchPolicyKey.SetValue("AllowCortana", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $searchPolicyKey.Close()
        Write-Host "  [OK] AllowCortana házirend letiltva." -ForegroundColor Green
    }

    # Beszéd- és hangalapú adatgyűjtés (Online Speech) tiltása a magánszféra védelmében
    $speechPolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\Windows\Speech", $true)
    if ($speechPolicyKey) {
        $speechPolicyKey.SetValue("AllowSpeechModelUpdate", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $speechPolicyKey.Close()
        Write-Host "  [OK] Hangalapu adatgyujtes leallitva." -ForegroundColor Green
    }
} catch {
    Write-Host "  [HIBA] Nem sikerult minden Registry korlatozast beirni!" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " A Cortana eltavolitasa kesz. UJRAINDITAS JAVASOLT!" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan

# Alváskezelés visszaállítása alaphelyzetbe
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset) | Out-Null
