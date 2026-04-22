# --- Ébren tartás és Laptop figyelmeztetés ---
# API betöltése (dinamikus névvel, hogy ne legyen ütközés)
# Futás alatt: Ébren tartás kényszerítése
$sig = '[DllImport("kernel32.dll")] public static extern uint SetThreadExecutionState(uint esFlags);'
$type = Add-Type -MemberDefinition $sig -Name "Sleep$(Get-Random)" -Namespace "Win32" -PassThru
# Decimális érték használata a konverziós hiba elkerülésére (0x80000001 = 2147483649)
[uint32]$flags = 2147483649
$type::SetThreadExecutionState($flags)
# --- Ébren tartás és Laptop figyelmeztetés ---


[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

$path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
$name = "ClearPageFileAtShutdown"

$val = Get-ItemProperty -Path $path -Name $name -ErrorAction SilentlyContinue
$status = if ($val.$name -eq 1) { "AKTÍV (törlés leálláskor)" } else { "INAKTÍV" }

Write-Host "Lapozófájl ürítése leálláskor: $status" -ForegroundColor Cyan
$choice = Read-Host "Módosítod? (I/N)"
if ($choice -eq "I" -or $choice -eq "i") {
    $new = if ($val.$name -eq 1) { 0 } else { 1 }
    Set-ItemProperty -Path $path -Name $name -Value $new -Type DWord
    Write-Host "Kész! Új állapot: $new" -ForegroundColor Green
}
Pause


# Alváskezelés visszaállítása alaphelyzetbe (0x80000000 = 2147483648)
[uint32]$reset = 2147483648
$type::SetThreadExecutionState($reset)
