# RemoveDiskProtect.ps1 - LordAthis RTS Framework
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Ébren tartás ---
$signature = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $signature -Name "Win32Sleep" -Namespace "Win32" -PassThru
$type::SetThreadExecutionState(0x80000001)

function Show-DiskMenu {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "   MEGHAJTO IRASVEDELEM FELOLDASA (USB/HDD/SSD)" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " 1  Adott meghajto feloldasa (DiskPart - Attributum torles)"
    Write-Host " 2  Globalis USB irasvedelem kikapcsolasa (Registry)"
    Write-Host " 3  Globalis USB irasvedelem BEKAPCSOLASA (Vedelem)"
    Write-Host " X  Vissza a fomenube"
    Write-Host "----------------------------------------------------"
}

do {
    Show-DiskMenu
    $opt = Read-Host "Valassz opciot"

    switch ($opt) {
        "1" {
            Write-Host "`n[*] Elerheto kulso/masodlagos meghajtok lekerese..." -ForegroundColor Yellow
            $disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.IsSystem -eq $false }
            $disks | Select-Object Number, FriendlyName, HealthStatus, @{Name="Vedett";Expression={$_.IsReadOnly}} | Format-Table -AutoSize
            
            $id = Read-Host "Melyik lemez szamat oldjam fel? (pl. 1)"
            if ($id -ne "") {
                Write-Host "Muvelet vegrehajtasa a(z) $id lemezen..." -ForegroundColor Magenta
                "select disk $id", "attributes disk clear readonly", "exit" | diskpart | Out-Null
                Write-Host "Kesz. Ellenorizd az intezoben!" -ForegroundColor Green
                Start-Sleep -Seconds 2
            }
        }
        "2" {
            Write-Host "`n[*] Globalis Registry korlatozas feloldasa..." -ForegroundColor Yellow
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
            if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "WriteProtect" -Value 0 -Type DWord -Force
            Write-Host "✅ SIKER: A rendszer mostantol engedi az irast az USB-kre." -ForegroundColor Green
            Write-Host "INFO: Huzd ki es dugd vissza a meghajtot!" -ForegroundColor Gray
            Start-Sleep -Seconds 3
        }
        "3" {
            Write-Host "`n[!] Globalis irasvedelem BEKAPCSOLASA (Read-Only mod)..." -ForegroundColor Red
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
            if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name "WriteProtect" -Value 1 -Type DWord -Force
            Write-Host "🔒 A rendszer mostantol blokkolja az USB irast." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }
} while ($opt -ne "X" -and $opt -ne "x")

# Ébren tartás vége
$type::SetThreadExecutionState(0x80000000)
