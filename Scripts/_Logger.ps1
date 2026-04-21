# _Logger.ps1 - Minden script dot-source-olja: . "$PSScriptRoot\_Logger.ps1"
# Logokat a /LOG mappába írja, ami .gitignore-ban szerepel.

# LOG mappa: a Scripts szülője + \LOG
$script:LogFolder = Join-Path (Split-Path $PSScriptRoot -Parent) "LOG"
if (-not (Test-Path $script:LogFolder)) {
    New-Item -ItemType Directory -Path $script:LogFolder -Force | Out-Null
}

# Log fájl neve: YYYY-MM-DD_HH-mm_ScriptNev.log
$script:CallerName = if ($MyInvocation.ScriptName) {
    [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.ScriptName)
} else { "unknown" }

$script:LogFile = Join-Path $script:LogFolder (
    "$(Get-Date -Format 'yyyy-MM-dd_HH-mm')_$($script:CallerName).log"
)

# Fejléc a log fájlba
@"
========================================
WinRegTools Log
Script  : $($script:CallerName)
Datum   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
OS      : $([System.Environment]::OSVersion.VersionString)
User    : $env:USERNAME / $env:COMPUTERNAME
========================================
"@ | Out-File -FilePath $script:LogFile -Encoding UTF8 -Force

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",       # INFO | OK | WARN | ERROR | SKIP
        [ConsoleColor]$Color = [ConsoleColor]::Gray
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "[$timestamp][$Level] $Message"

    # Konzolra
    Write-Host $line -ForegroundColor $Color

    # Fájlba
    $line | Out-File -FilePath $script:LogFile -Encoding UTF8 -Append
}

function Write-LogOK    { param([string]$m) Write-Log "  [OK]   $m" "OK"    Green }
function Write-LogWarn  { param([string]$m) Write-Log "  [!!]   $m" "WARN"  Yellow }
function Write-LogError { param([string]$m) Write-Log "  [HIBA] $m" "ERROR" Red }
function Write-LogSkip  { param([string]$m) Write-Log "  [--]   $m" "SKIP"  DarkGray }
function Write-LogInfo  { param([string]$m) Write-Log "  [*]    $m" "INFO"  Cyan }

function Write-LogSection {
    param([string]$Title)
    $line = "`n--- $Title ---"
    Write-Host $line -ForegroundColor Magenta
    $line | Out-File -FilePath $script:LogFile -Encoding UTF8 -Append
}

function Close-Log {
    $footer = "`n[$(Get-Date -Format 'HH:mm:ss')] Script vege. Log: $script:LogFile"
    Write-Host $footer -ForegroundColor DarkGray
    $footer | Out-File -FilePath $script:LogFile -Encoding UTF8 -Append
}
