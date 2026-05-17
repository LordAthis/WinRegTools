# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
# [Out-Null] hozzáadása, hogy a felesleges visszatérési szám ne íródjon ki a konzolra
$type::SetThreadExecutionState($flags) | Out-Null
# --- Ébren tartás és Laptop figyelmeztetés ---

# RPCHelper_Fix.ps1 - LordAthis - Ultimate RPC & Service Recovery (.NET mod)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   RPC ES RENDSZERSZOLGALTATAS HELYREALLITAS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# Rendszergazdai jogkör ellenőrzése
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] HIBA: A szkriptet RENDSZERGAZDAKENT kell futtatni!" -ForegroundColor Red
    Exit
}

# 1. Ismert káros/hibás szolgáltatások és driverek eltávolítása (pl. Intel Ipsm)
Write-Host "[1] Specifikus hibaforrasok keresese es driver torles..." -ForegroundColor Yellow
$badServices = @("Ipsm", "Intel(R) Power Sharing Manager")

# Megnyitjuk a Services kulcsot írásra az eltávolításhoz
$servicesKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Services", $true)

foreach ($badSvc in $badServices) {
    if (Get-Service -Name $badSvc -ErrorAction SilentlyContinue) {
        Write-Host "  [!] $badSvc talalva! Eltavolitas..." -ForegroundColor Red
        Stop-Service -Name $badSvc -Force -ErrorAction SilentlyContinue
        
        try {
            # .NET alapú drasztikus törlés a Registry-ből (sc.exe delete helyett)
            if ($servicesKey.OpenSubKey($badSvc)) {
                $servicesKey.DeleteSubKeyTree($badSvc, $false)
                Write-Host "  [OK] $badSvc driver/szolgaltatas sikeresen torolve." -ForegroundColor Green
            }
        } catch {
            Write-Host "  [HIBA] Nem sikerult torolni a(z) $badSvc kulcsot a Registry-bol!" -ForegroundColor Red
        }
    }
}

# 2. Kritikus RPC és DCOM szolgáltatások helyreállítása .NET-en keresztül
Write-Host ""
Write-Host "[2] Alapveto RPC szolgaltatasok ellenorzese..." -ForegroundColor Yellow
$rpcServices = @{
    "RpcSs"        = 2;  # Automatic
    "RpcEptMapper" = 2;  # Automatic
    "DcomLaunch"   = 2;  # Automatic
    "RpcLocator"   = 3   # Manual
}

foreach ($svc in $rpcServices.Keys) {
    try {
        # Beállítás .NET-en keresztül, ami kikerüli a sima Set-Service tiltását
        $svcKey = $servicesKey.OpenSubKey($svc, $true)
        if ($svcKey) {
            $svcKey.SetValue("Start", $rpcServices[$svc], [Microsoft.Win32.RegistryValueKind]::DWord)
            $svcKey.Close()
        }

        # Elindítás, ha szükséges (kivéve az RpcLocator-t)
        $status = Get-Service -Name $svc -ErrorAction Stop
        if ($status.Status -ne 'Running' -and $svc -ne "RpcLocator") {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        }
        Write-Host "  [OK] $svc beallitva." -ForegroundColor Green
    } catch {
        Write-Host "  [!!] $svc nem erheto el vagy modosithato!" -ForegroundColor Red
    }
}
if ($servicesKey) { $servicesKey.Close() }

# 3. WMI (Windows Management Instrumentation) javítás
Write-Host ""
Write-Host "[3] WMI (RPC alapfeltetel) ellenorzese..." -ForegroundColor Yellow
try {
    $wmiStatus = Get-Service -Name winmgmt -ErrorAction Stop
    if ($wmiStatus.Status -ne 'Running') {
        Write-Host "  [!] WMI nem fut. Ujrainditas..." -ForegroundColor Yellow
        Restart-Service -Name winmgmt -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  [OK] WMI szolgaltatas aktiv." -ForegroundColor Green
} catch {
    Write-Host "  [HIBA] A WMI szolgaltatas nem erhető el!" -ForegroundColor Red
}

# 4. Registry és Hálózati protokoll tisztítás .NET alapokon
Write-Host ""
Write-Host "[4] Halozati reteg es Registry alaphelyzetbe allitasa..." -ForegroundColor Yellow

# RPC Internet korlátozások törlése .NET-tel
$rpcKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Rpc", $true)
if ($rpcKey) {
    $subKeys = $rpcKey.GetSubKeyNames()
    if ($subKeys -contains "Internet") {
        try {
            $rpcKey.DeleteSubKeyTree("Internet", $false)
            Write-Host "  [OK] RPC Internet korlatozasok torolve." -ForegroundColor Green
        } catch {
            Write-Host "  [HIBA] Nem sikerult torolni az Internet korlatozasokat!" -ForegroundColor Red
        }
    } else {
        Write-Host "  [OK] Nincsenek tisztitando RPC korlatozasok." -ForegroundColor Green
    }
    $rpcKey.Close()
}

# Hálózati stack reset
netsh winsock reset | Out-Null
netsh int ip reset | Out-Null
ipconfig /flushdns | Out-Null
Write-Host "  [OK] Winsock, IP es DNS gyorsitotar uritve." -ForegroundColor Green

# 5. Rendszerfájl ellenőrzés (háttérben indítva)
Write-Host ""
Write-Host "[5] Gyors fajlrendszer ellenorzes inditasa (sfc)..." -ForegroundColor Yellow
sfc /verifyonly | Out-Null
Write-Host "  [OK] Ellenorzes lefutott." -ForegroundColor Green

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " A javitasok vegeztek. UJRAINDITAS JAVASOLT!" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan

# Alváskezelés visszaállítása alaphelyzetbe
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset) | Out-Null
