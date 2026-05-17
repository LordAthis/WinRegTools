# --- Ébren tartás és Laptop figyelmeztetés ---
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags) | Out-Null
# --- Ébren tartás és Laptop figyelmeztetés ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   MICROSOFT COPILOT ES AI MODULOK ELTAVOLITASA" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Rendszergazdai jogkör ellenőrzése
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] HIBA: A szkriptet RENDSZERGAZDAKENT kell futtatni!" -ForegroundColor Red
    Exit
}

# 1. Copilot és AI szolgáltatói csomagok eltávolítása minden felhasználónál
Write-Host " Copilot Modern App (UWP) csomagok kigyomlalasa..." -ForegroundColor Yellow
$copilotPackages = @("*Copilot*", "*WindowsAI*", "*BingChat*")

foreach ($pkg in $copilotPackages) {
    # Először eltávolítjuk a jelenleg telepített felhasználói példányokat
    Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $pkg } | ForEach-Object {
        try {
            Remove-AppxPackage -Package $_.PackageFullName -AllUsers -ErrorAction Stop
            Write-Host "  [OK] Csomag eltavolitva: $($_.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  [HIBA] Nem sikerult torolni a csomagot: $($_.Name)" -ForegroundColor Red
        }
    }
    # Töröljük a rendszer-szintű előkészített (provisioned) csomagot is, hogy új felhasználónál ne települjön vissza
    Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $pkg } | ForEach-Object {
        try {
            Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop
            Write-Host "  [OK] Rendszerszintu elokeszitett csomag torolve: $($_.DisplayName)" -ForegroundColor Green
        } catch {}
    }
}

# 2. Copilot és AI funkciók teljes letiltása a Registry-ben (.NET)
Write-Host ""
Write-Host " Windows Copilot es AI funkciok rendszerszintu letiltasa..." -ForegroundColor Yellow
try {
    # Fő Windows házirend kulcs megnyitása/létrehozása
    $copilotPolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot", $true)
    if ($copilotPolicyKey) {
        # Copilot teljes kikapcsolása a Windowsban
        $copilotPolicyKey.SetValue("TurnOffWindowsCopilot", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
        $copilotPolicyKey.Close()
        Write-Host "  [OK] Windows Copilot policy letiltva." -ForegroundColor Green
    }

    # Keresőbe épített AI asszisztens és javaslatok letiltása Explorer szinten
    $explorerPolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\Windows\Explorer", $true)
    if ($explorerPolicyKey) {
        $explorerPolicyKey.SetValue("DisableSearchBoxSuggestions", 1, [Microsoft.Win32.RegistryValueKind]::DWord)
        $explorerPolicyKey.Close()
        Write-Host "  [OK] Keresomezo AI javaslatok letiltva." -ForegroundColor Green
    }

    # Edge oldalsávba épített AI (Hubs) letiltása
    $edgePolicyKey = [Microsoft.Win32.Registry]::LocalMachine.CreateSubKey("SOFTWARE\Policies\Microsoft\Edge", $true)
    if ($edgePolicyKey) {
        $edgePolicyKey.SetValue("HubsSidebarEnabled", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $edgePolicyKey.Close()
        Write-Host "  [OK] Edge AI oldalsav letiltva." -ForegroundColor Green
    }
} catch {
    Write-Host "  [HIBA] Nem sikerult minden AI korlatozast beirni a Registry-be!" -ForegroundColor Red
}

# 3. Tálca gomb eltávolítása a felhasználói profilokból (Registry felület tisztítás)
Write-Host ""
Write-Host " Talcan levo Copilot gomb elrejtese az aktualis felhasznalonal..." -ForegroundColor Yellow
try {
    $advancedKey = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced", $true)
    if ($advancedKey) {
        # Érték 0-ra állítása eltünteti a tálcáról az ikont
        $advancedKey.SetValue("ShowCopilotButton", 0, [Microsoft.Win32.RegistryValueKind]::DWord)
        $advancedKey.Close()
        Write-Host "  [OK] Talca gomb elrejtve." -ForegroundColor Green
    }
} catch {
    Write-Host "  [HIBA] Nem sikerult modositani a felhasznaloi talca beallitast!" -ForegroundColor Red
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " A Copilot eltavolitasa kesz. UJRAINDITAS JAVASOLT!" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan

# Alváskezelés visszaállítása alaphelyzetbe
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset) | Out-Null
