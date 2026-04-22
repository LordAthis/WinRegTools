# RemoveDiskProtect.ps1 - LordAthis RTS Framework
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Admin ön-emeltetés
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# --- RTS Framework - Sleep Prevention ---
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags) | Out-Null

$LogFile = Join-Path $PSScriptRoot "..\LOG\DiskProtection_Session.log"

function Show-DiskMenu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   MEGHAJTO VEDELEM KEZELO" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " 1  Adott meghajto FELOLDASA (CLEAN)"
    Write-Host " 2  Munkamenet lemezeinek VISSZAZARASA" -ForegroundColor Yellow
    Write-Host " 3  Globalis USB irasvedelem KI"
    Write-Host " 4  Globalis USB irasvedelem BE"
    Write-Host " X  Vissza a fomenube"
    Write-Host "----------------------------------------"
}

do {
    Show-DiskMenu
    $opt = Read-Host "Valassz opciot"

    switch ($opt) {
        "1" {
            Write-Host "`n[*] Meghajtok lekerdezese..." -ForegroundColor Yellow
            $disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.IsSystem -eq $false }
            
            if (-not $disks) {
                Write-Host "Hiba: Nem talalhato kulso meghajto!" -ForegroundColor Red
                Start-Sleep -Seconds 2
                continue
            }

            $disks | Select-Object Number, FriendlyName, HealthStatus, @{Name="Vedett";Expression={$_.IsReadOnly}} | Format-Table -AutoSize
            
            $id = Read-Host "Melyik lemez szamat oldjam fel? (CLEAN)"
            if ($id -ne "") {
                if ($disks.Number -contains [int]$id) {
                    Write-Host "Disk $id drasztikus feloldasa..." -ForegroundColor Magenta
                    $dpCmd = "select disk $id", "attributes disk clear readonly", "online disk", "clean", "exit"
                    $dpCmd | diskpart | Out-Null

                    $id | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    Write-Host "Kesz. Attributumok torolve, lemez tiszta." -ForegroundColor Green
                } else {
                    Write-Host "Hiba: Ervenytelen lemezszam!" -ForegroundColor Red
                }
                Start-Sleep -Seconds 2
            }
        }

        "2" {
            if (Test-Path $LogFile) {
                $ids = Get-Content $LogFile | Select-Object -Unique
                foreach ($id in $ids) {
                    Write-Host "Disk $id visszazarasa..." -ForegroundColor Yellow
                    "select disk $id", "attributes disk set readonly", "exit" | diskpart | Out-Null
                }
                Remove-Item $LogFile -Force
                Write-Host "Minden lemez visszazarva." -ForegroundColor Green
            } else {
                Write-Host "Nincs feloldott lemez a naploban." -ForegroundColor Gray
            }
            Start-Sleep -Seconds 2
        }

        "3" {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
            if (-not (Test-Path $regPath)) { New-Item $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "WriteProtect" -Value 0 -Type DWord -Force
            Write-Host "Globalis vedelem KIKAPCSOLVA." -ForegroundColor Green
            Start-Sleep -Seconds 2
        }

        "4" {
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies"
            if (-not (Test-Path $regPath)) { New-Item $regPath -Force | Out-Null }
            Set-ItemProperty -Path $regPath -Name "WriteProtect" -Value 1 -Type DWord -Force
            Write-Host "Globalis vedelem BEKAPCSOLVA." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
        }
    }
} while ($opt -ne "X" -and $opt -ne "x")

# --- Alvaskezeles visszaallitasa ---
if ($type) {
    [uint32]$reset = 2147483648
    $type::SetThreadExecutionState($reset) | Out-Null
}
