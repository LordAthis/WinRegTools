# --- Ébren tartás és Laptop figyelmeztetés ---
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---

# --- ADMIN JOG ÉS LOG KÖRNYEZET ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$LogFile = "$env:TEMP\RestorePoint_Cleanup_Log.txt"
"--- Takarítás indítva: $(Get-Date) ---" | Out-File $LogFile

function Write-Log($msg, $color = "White") {
    $txt = "[$(Get-Date -Format "HH:mm:ss")] $msg"
    Write-Host $txt -ForegroundColor $color
    $txt | Out-File $LogFile -Append
}

Write-Log "--- VISSZAÁLLÍTÁSI PONTOK ELLENŐRZÉSE ---" Cyan
$systemDrive = $env:SystemDrive

# --- 3. AKTUÁLIS ÁLLAPOT LISTÁZÁSA (Javítva) ---
Write-Log "Jelenlegi visszaállítási pontok listázása:" Yellow
$points = Get-ComputerRestorePoint -ErrorAction SilentlyContinue

if ($points) {
    # Előbb kiírjuk a képernyőre rendesen
    $points | Select-Object SequenceNumber, @{L="Dátum";E={$_.ConvertToDateTime($_.CreationTime)}}, Description | Format-Table -AutoSize
    
    # Aztán elmentjük a logba is
    $points | Out-String | Out-File $LogFile -Append
    
    $count = ($points | Measure-Object).Count
    Write-Log "Összesen $count darab visszaállítási pont található." White
} else {
    Write-Log "Nem található egyetlen visszaállítási pont sem!" Red
    [uint32]$reset = 2147483648
    $type::SetThreadExecutionState($reset)
    Pause
    exit
}

# --- 4. MEGERŐSÍTÉS ---
if ($count -le 1) {
    Write-Log "Csak egyetlen pont van ($($points.Description)), nincs mit törölni." Yellow
    [uint32]$reset = 2147483648
    $type::SetThreadExecutionState($reset)
    Pause
    exit
}

Write-Host ""
$confirm = Read-Host "Biztosan törölni akarod az ÖSSZES régi pontot, kivéve a legutolsót? (I/N)"
if ($confirm -ne "I" -and $confirm -ne "i") {
    Write-Log "Művelet a felhasználó által megszakítva." Orange
    [uint32]$reset = 2147483648
    $type::SetThreadExecutionState($reset)
    exit
}

# --- 5. TÖRLÉSI FOLYAMAT ---
Write-Log "Takarítás megkezdése..." Yellow
try {
    $currentVss = vssadmin list shadows /for=$systemDrive | Select-String "Shadow Copy ID:"
    $totalSteps = $currentVss.Count - 1
    $step = 1

    while ($currentVss.Count -gt 1) {
        Write-Log "[$step/$totalSteps] Legrégebbi pont eltávolítása..." Gray
        & vssadmin delete shadows /for=$systemDrive /oldest /quiet | Out-File -FilePath $LogFile -Append
        
        $currentVss = vssadmin list shadows /for=$systemDrive | Select-String "Shadow Copy ID:"
        $step++
    }
    Write-Log "Törlési folyamat befejezve." Green
} catch {
    Write-Log "HIBA a törlés során: $($_.Exception.Message)" Red
}

# --- 6. ZÁRÓ ÁLLAPOT ---
Write-Log "--- FRISSÍTETT ÁLLAPOT ---" Cyan
$remainingPoints = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
if ($remainingPoints) {
    $remainingPoints | Select-Object SequenceNumber, @{L="Dátum";E={$_.ConvertToDateTime($_.CreationTime)}}, Description | Format-Table -AutoSize
}

Write-Log "A részletes napló mentve: $LogFile" Yellow

# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)

Pause
