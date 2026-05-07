# OpenSauce installer — public Windows PowerShell install path.
#
# Usage (in PowerShell, possibly as administrator for system scope):
#   irm https://raw.githubusercontent.com/Diatonic-AI/opensauce/main/install/install.ps1 | iex
#   & ([scriptblock]::Create((irm .../install.ps1))) -Version 0.1.0 -Scope user
#
# Downloads the .msi from the latest release and runs msiexec.

[CmdletBinding()]
param(
  [string]$Version = '0.1.0',
  [ValidateSet('user', 'system')]
  [string]$Scope = 'user',
  [string]$Profile = 'client',
  [string]$Repo = 'Diatonic-AI/opensauce',
  [switch]$SkipInit
)

$ErrorActionPreference = 'Stop'

$msiUrl = "https://github.com/$Repo/releases/download/v$Version/sauce-framework-$Version-x64.msi"
$tmp = New-TemporaryFile
$msiPath = "$($tmp.FullName).msi"
Remove-Item $tmp.FullName -Force

Write-Host "→ downloading $msiUrl" -ForegroundColor Cyan
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing

$msiArgs = @('/i', "`"$msiPath`"", '/quiet', '/norestart')
if ($Scope -eq 'user') {
  $msiArgs += @('MSIINSTALLPERUSER=1', 'ALLUSERS=""')
} elseif ($Scope -eq 'system') {
  $msiArgs += @('ALLUSERS=1')
  if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    Write-Error "scope=system requires administrator. Re-run from an elevated PowerShell prompt."
    exit 1
  }
}

Write-Host "→ msiexec $($msiArgs -join ' ')" -ForegroundColor Cyan
$proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
if ($proc.ExitCode -ne 0) {
  Write-Error "msiexec failed with exit code $($proc.ExitCode)"
  exit $proc.ExitCode
}

Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

# ── PATH guidance ──
$installBin = "C:\Program Files\SauceTech\Sauce\bin"
$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($userPath -notlike "*$installBin*") {
  Write-Host ""
  Write-Host "→ NOTE: $installBin is not on your PATH." -ForegroundColor Yellow
  Write-Host "  Add it via: setx PATH `"%PATH%;$installBin`""
}

# ── touchless user provisioning ──
if (-not $SkipInit) {
  $sauce = Join-Path $installBin 'sauce.exe'
  if (Test-Path $sauce) {
    Write-Host "→ $sauce init --scope $Scope --profile $Profile"
    & $sauce init --scope $Scope --profile $Profile --quiet
  }
}

Write-Host ""
Write-Host "✅ sauce-framework $Version installed (scope=$Scope, profile=$Profile)" -ForegroundColor Green
