Write-Host "--- Talca Hirek es Erdeklodes letiltasa ---" -ForegroundColor Cyan
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds"
if (-not (Test-Path $path)) { New-Item $path -Force }
Set-ItemProperty -Path $path -Name "ShellFeedsTaskbarViewMode" -Value 2 -Force
Write-Host "Kesz. (Kijelentkezes utan ervenyes)" -ForegroundColor Green
