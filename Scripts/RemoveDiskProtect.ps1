# RemoveDiskProtect.ps1 - LordAthis RTS Framework
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Admin ön-emeltetés (biztonsági tartalék)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---

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
            Write-Host "`n[*] Elérhető külső/másodlagos meghajtók lekérése..." -ForegroundColor Yellow
            # Lekérdezzük a lemezeket (Rendszerlemezt kihagyva a biztonság kedvéért)
            $disks = Get-Disk | Where-Object { $_.BusType -eq "USB" -or $_.IsSystem -eq $false }
            
            if (-not $disks) {
                Write-Host "❌ Nem található feloldható (külső) meghajtó!" -ForegroundColor Red
                Start-Sleep -Seconds 2
                continue
            }

            $disks | Select-Object Number, FriendlyName, HealthStatus, @{Name="Védett";Expression={$_.IsReadOnly}} | Format-Table -AutoSize
            
            $id = Read-Host "Melyik lemez számát oldjam fel drasztikusan? (Pl. 2)"
            if ($id -ne "") {
                # Ellenőrizzük, hogy létezik-e a megadott számú lemez
                if ($disks.Number -contains [int]$id) {
                    Write-Host "Disk $id drasztikus feloldása (CLEAN) folyamatban..." -ForegroundColor Magenta
                    
                    $dpCmd = @"
select disk $id
attributes disk clear readonly
online disk
clean
exit
"@
                    $dpCmd | diskpart | Out-Null

                    $id | Out-File -FilePath $LogFile -Append -Encoding UTF8
                    Write-Host "✅ Disk $id attribútumai törölve és a partíciós tábla törölve (Clean)." -ForegroundColor Green
                    Write-Host "⚠️ A lemez most teljesen üres, inicializálni kell a Lemezkezelőben!" -ForegroundColor Yellow
                } else {
                    Write-Host "❌ Érvénytelen lemezszám!" -ForegroundColor Red
                }
                Start-Sleep -Seconds 3
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

# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
