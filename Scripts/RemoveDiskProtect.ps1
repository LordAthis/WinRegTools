# RemoveDiskProtect.ps1 - LordAthis RTS Framework
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Admin ön-emeltetés (biztonsági tartalék)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# --- Ébren tartás ---
$signature = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $signature -Name "Win32Sleep" -Namespace "Win32" -PassThru
$type::SetThreadExecutionState(0x80000001)

$LogFile = Join-Path $PSScriptRoot "..\LOG\DiskProtection_Session.log"

function Show-DiskMenu {
    Clear-Host
    Write-Host "--- MEGHAJTO VEDELEM KEZELO ---" -ForegroundColor Cyan
    Write-Host " 1  Adott meghajto FELOLDASA (DiskPart)"
    Write-Host " 2  Minden, ebben a munkamenetben feloldott lemez VISSZAZARASA" -ForegroundColor Yellow
    Write-Host " 3  Globalis Registry irasvedelem KI (Minden USB)"
    Write-Host " 4  Globalis Registry irasvedelem BE (Minden USB)"
    Write-Host " X  Vissza a fomenube"
}

do {
    Show-DiskMenu
    $opt = Read-Host "Valassz"

    switch ($opt) {
        "1" {
            $disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.IsSystem -eq $false }
            $disks | Select-Object Number, FriendlyName, @{Name="Vedett";Expression={$_.IsReadOnly}} | Format-Table
            $id = Read-Host "Lemez szama"
            if ($id -ne "") {
                "select disk $id", "attributes disk clear readonly" | diskpart | Out-Null
                $id | Out-File -FilePath $LogFile -Append # Mentjük a naplóba a későbbi visszazáráshoz
                Write-Host "Disk $id feloldva es naplozva." -ForegroundColor Green
                Start-Sleep -Seconds 1
            }
        }
        "2" {
            if (Test-Path $LogFile) {
                $ids = Get-Content $LogFile | Select-Object -Unique
                foreach ($id in $ids) {
                    Write-Host "Disk $id visszazarasa..." -ForegroundColor Yellow
                    "select disk $id", "attributes disk set readonly" | diskpart | Out-Null
                }
                Remove-Item $LogFile -Force
                Write-Host "Minden naplozott lemez visszazarva." -ForegroundColor Green
            } else {
                Write-Host "Nincs feloldott lemez a naploban." -ForegroundColor Gray
            }
            Start-Sleep -Seconds 2
        }
        "3" { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" -Name "WriteProtect" -Value 0 -Type DWord -Force }
        "4" { Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies" -Name "WriteProtect" -Value 1 -Type DWord -Force }
    }
} while ($opt -ne "X" -and $opt -ne "x")


# Alváskezelés visszaállítása alaphelyzetbe
$type::SetThreadExecutionState(0x80000000) 
Write-Host "Kesz. Az energiagazdalkodasi korlatok feloldva." -ForegroundColor Gray
