# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---


# RPCHelper_Fix.ps1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "--- RPC Szolgáltatások és Hibák Javítása ---" -ForegroundColor Cyan

# 1. Kritikus RPC szolgáltatások listája és indítási típusuk
$rpcServices = @{
    "RpcSs"    = "Automatic";   # Remote Procedure Call (RPC)
    "RpcEptMapper" = "Automatic"; # RPC Endpoint Mapper
    "DcomLaunch"   = "Automatic"  # DCOM Server Process Launcher
}

Write-Host "[*] Szolgáltatások ellenőrzése és javítása..." -ForegroundColor Yellow
foreach ($svc in $rpcServices.Keys) {
    try {
        $status = Get-Service -Name $svc -ErrorAction Stop
        Set-Service -Name $svc -StartupType $rpcServices[$svc]
        
        if ($status.Status -ne 'Running') {
            Write-Host "  [!] $svc indítása..." -ForegroundColor Yellow
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        } else {
            Write-Host "  [OK] $svc fut és automatikusra van állítva." -ForegroundColor Green
        }
    } catch {
        Write-Host "  [HIBA] Nem sikerült elérni a(z) $svc szolgáltatást!" -ForegroundColor Red
    }
}

# 2. Registry javítás: RPC Endpoint Mapper portok és korlátozások törlése
# Néha bizonyos szoftverek korlátozzák az RPC port-tartományt, ami hibát okoz
$registryPath = "HKLM:\SOFTWARE\Microsoft\Rpc\Internet"
if (Test-Path $registryPath) {
    Write-Host "[*] RPC hálózati korlátozások eltávolítása a Registry-ből..." -ForegroundColor Yellow
    Remove-Item -Path $registryPath -Recurse -Force
    Write-Host "  [OK] Registry kulcs alaphelyzetbe állítva." -ForegroundColor Green
}

# 3. DNS és Hálózati gyorsítótár ürítése (az RPC hálózati része miatt)
Write-Host "[*] Hálózati gyorsítótár ürítése..." -ForegroundColor Yellow
ipconfig /flushdns | Out-Null
netsh int ip reset | Out-Null
Write-Host "  [OK] Hálózati protokollok alaphelyzetbe állítva." -ForegroundColor Green

# 4. Winsock alaphelyzetbe állítása
Write-Host "[*] Winsock katalógus visszaállítása..." -ForegroundColor Yellow
netsh winsock reset | Out-Null
Write-Host "  [OK] Winsock kész." -ForegroundColor Green

Write-Host ""
Write-Host "A javítások érvénybelépéséhez javasolt a gép ÚJRAINDÍTÁSA!" -ForegroundColor Magenta
Write-Host "Kész." -ForegroundColor Green


# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
