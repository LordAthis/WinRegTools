# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "--- RPC Szolgaltatasok es Hibak Javitasa ---" -ForegroundColor Cyan

# Rendszergazdai jogkör ellenőrzése
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[!] HIBA: A szkriptet RENDSZERGAZDAKENT kell futtatni!" -ForegroundColor Red
    Exit
}

# 1. Kritikus RPC szolgáltatások listája és indítási típusuk (.NET Registry-hez az Automatikus = 2)
$rpcServices = @{
    "RpcSs"        = 2;  # Remote Procedure Call (RPC)
    "RpcEptMapper" = 2;  # RPC Endpoint Mapper
    "DcomLaunch"   = 2   # DCOM Server Process Launcher
}

Write-Host "[*] Szolgaltatasok ellenorzese es javitasa .NET-en keresztul..." -ForegroundColor Yellow

# .NET Registry kulcs megnyitása írásra a HKLM\SYSTEM\CurrentControlSet\Services útvonalon
$servicesKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SYSTEM\CurrentControlSet\Services", $true)

foreach ($svc in $rpcServices.Keys) {
    try {
        # Szolgáltatás állapotának ellenőrzése a normál szolgáltatáskezelővel
        $status = Get-Service -Name $svc -ErrorAction Stop
        
        # .NET-en keresztül megnyitjuk a szolgáltatás saját alkulcsát
        $svcKey = $servicesKey.OpenSubKey($svc, $true)
        if ($svcKey) {
            # Beállítjuk a Start DWORD értékét 2-re (Automatikus)
            $svcKey.SetValue("Start", $rpcServices[$svc], [Microsoft.Win32.RegistryValueKind]::DWord)
            $svcKey.Close()
        }

        # Ha nem fut, megpróbáljuk elindítani
        if ($status.Status -ne 'Running') {
            Write-Host "  [!] $svc inditasa..." -ForegroundColor Yellow
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        } else {
            Write-Host "  [OK] $svc fut es automatikusra van allitva." -ForegroundColor Green
        }
    } catch {
        Write-Host "  [HIBA] Nem sikerult modositani a(z) $svc szolgaltatast!" -ForegroundColor Red
    }
}
if ($servicesKey) { $servicesKey.Close() }

# 2. Registry javítás: RPC Endpoint Mapper portok és korlátozások törlése .NET-tel
# Megnyitjuk a HKLM\SOFTWARE\Microsoft\Rpc kulcsot írási joggal
$rpcKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Rpc", $true)

if ($rpcKey) {
    # Ellenőrizzük, hogy létezik-e az Internet alkulcs
    $subKeys = $rpcKey.GetSubKeyNames()
    if ($subKeys -contains "Internet") {
        Write-Host "[*] RPC halozati korlatozasok eltavolitasa a Registry-bol (.NET)..." -ForegroundColor Yellow
        try {
            # Töröljük az Internet kulcsot és annak teljes tartalmát
            $rpcKey.DeleteSubKeyTree("Internet", $false)
            Write-Host "  [OK] Registry kulcs sikeresen torolve." -ForegroundColor Green
        } catch {
            Write-Host "  [HIBA] Nem sikerult torolni az Internet kulcsot! Jogosultsag hiba." -ForegroundColor Red
        }
    } else {
        Write-Host "  [OK] Nincsenek tisztitando RPC halozati korlatozasok a Registry-ben." -ForegroundColor Green
    }
    $rpcKey.Close()
}

# 3. DNS és Hálózati gyorsítótár ürítése
Write-Host "[*] Halozati gyorsitotat uritese..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
netsh int ip reset | Out-Null
Write-Host "  [OK] Halozati protokollok alaphelyzetbe allitva." -ForegroundColor Green

# 4. Winsock alaphelyzetbe állítása
Write-Host "[*] Winsock katalogus visszaallitasa..." -ForegroundColor Yellow
netsh winsock reset | Out-Null
Write-Host "  [OK] Winsock kesz." -ForegroundColor Green

Write-Host ""
Write-Host "A javitasok ervenyesitesehez javasolt a gep UJRAINDITASA!" -ForegroundColor Magenta
Write-Host "Kesz." -ForegroundColor Green

# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
