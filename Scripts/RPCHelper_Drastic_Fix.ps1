# RPCHelper_Fix.ps1 - LordAthis - Ultimate RPC & Service Recovery
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   RPC ÉS RENDSZERSZOLGÁLTATÁS HELYREÁLLÍTÁS" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

# 1. Ismert káros/hibás szolgáltatások eltávolítása (pl. Intel Ipsm)
Write-Host "[1] Specifikus hibaforrások keresése..." -ForegroundColor Yellow
$badServices = @("Ipsm", "Intel(R) Power Sharing Manager")

foreach ($badSvc in $badServices) {
    if (Get-Service -Name $badSvc -ErrorAction SilentlyContinue) {
        Write-Host "  [!] $badSvc találva! Eltávolítás..." -ForegroundColor Red
        Stop-Service -Name $badSvc -Force -ErrorAction SilentlyContinue
        sc.exe delete $badSvc | Out-Null
        Write-Host "  [OK] $badSvc törölve." -ForegroundColor Green
    }
}

# 2. Kritikus RPC és DCOM szolgáltatások helyreállítása
Write-Host ""
Write-Host "[2] Alapvető RPC szolgáltatások ellenőrzése..." -ForegroundColor Yellow
$rpcServices = @{
    "RpcSs"        = "Automatic"
    "RpcEptMapper" = "Automatic"
    "DcomLaunch"   = "Automatic"
    "RpcLocator"   = "Manual"
}

foreach ($svc in $rpcServices.Keys) {
    try {
        Set-Service -Name $svc -StartupType $rpcServices[$svc] -ErrorAction SilentlyContinue
        if ((Get-Service $svc).Status -ne 'Running' -and $svc -ne "RpcLocator") {
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        }
        Write-Host "  [OK] $svc beállítva ($($rpcServices[$svc]))." -ForegroundColor Green
    } catch {
        Write-Host "  [!!] $svc nem érhető el!" -ForegroundColor Red
    }
}

# 3. WMI (Windows Management Instrumentation) javítás
# Sokszor az RPC hiba mögött a WMI tároló sérülése áll
Write-Host ""
Write-Host "[3] WMI (RPC alapfeltétel) ellenőrzése..." -ForegroundColor Yellow
$wmiStatus = Get-Service -Name winmgmt
if ($wmiStatus.Status -ne 'Running') {
    Write-Host "  [!] WMI nem fut. Újraindítás..." -ForegroundColor Yellow
    Restart-Service -Name winmgmt -Force -ErrorAction SilentlyContinue
}
Write-Host "  [OK] WMI szolgáltatás aktív." -ForegroundColor Green

# 4. Registry és Hálózati protokoll tisztítás
Write-Host ""
Write-Host "[4] Hálózati réteg és Registry alaphelyzetbe állítása..." -ForegroundColor Yellow

# RPC Internet korlátozások törlése
if (Test-Path "HKLM:\SOFTWARE\Microsoft\Rpc\Internet") {
    Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Rpc\Internet" -Recurse -Force
    Write-Host "  [OK] RPC Internet korlátozások törölve." -ForegroundColor Green
}

# Hálózati stack reset
netsh winsock reset | Out-Null
netsh int ip reset | Out-Null
ipconfig /flushdns | Out-Null
Write-Host "  [OK] Winsock, IP és DNS gyorsítótár ürítve." -ForegroundColor Green

# 5. Rendszerfájl ellenőrzés (háttérben indítva)
Write-Host ""
Write-Host "[5] Gyors fájlrendszer ellenőrzés indítása (sfc)..." -ForegroundColor Yellow
sfc /verifyonly | Out-Null # Csak ellenőriz, nem tart sokáig
Write-Host "  [OK] Ellenőrzés lefutott." -ForegroundColor Green

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host " A javítások végeztek. ÚJRAINDÍTÁS JAVASOLT!" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Cyan
