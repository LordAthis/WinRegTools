[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Write-Host "--- RPC Fix (Intel Ipsm hiba javítása) ---" -ForegroundColor Cyan
# RPC szolgáltatás beállítása automatikusra
Set-Service -Name RpcSs -StartupType Automatic
Write-Host "RPC szolgáltatás beállítva Automatikusra." -ForegroundColor Green

# Ipsm szolgáltatás eltávolítása ha létezik
if (Get-Service -Name Ipsm -ErrorAction SilentlyContinue) {
    Stop-Service -Name Ipsm -Force -ErrorAction SilentlyContinue
    sc.exe delete Ipsm
    Write-Host "Ipsm szolgáltatás eltávolítva." -ForegroundColor Yellow
} else {
    Write-Host "Ipsm szolgáltatás nem található, a rendszer tiszta." -ForegroundColor Gray
}
Pause
