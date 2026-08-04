# 0_setup.ps1 - Prerequisites for the conda module (checks only, changes nothing)
#
# Usage:
#   .\0_setup.ps1
#
# What it checks:
#   - Not running elevated
#   - The CurrentUser execution policy allows these scripts to run
#   - An existing conda is Miniforge, not Miniconda
#
# The Linux 0_setup.sh installs wget via apt. There is no equivalent here: the download uses
# Invoke-WebRequest, which ships with PowerShell, so this module needs nothing installed to
# bootstrap itself. That is the one advantage of the no-admin platform.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$MiniforgeDir = Join-Path $env:LOCALAPPDATA 'miniforge3'    # user-scope install, no elevation

Write-Host '=== Conda Setup (checks only) ==='
Write-Host ''

# ── 1. Not elevated ───────────────────────────────────────────────────────────
Write-Host '[1/3] Checking this is not an elevated shell...'
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '      ERROR: Do not run this as Administrator.'
    Write-Host '      Conda installed as another user will not be on your PATH.'
    exit 1
}
Write-Host '      Running as a normal user - OK.'

# ── 2. Execution policy ───────────────────────────────────────────────────────
# Setting this at CurrentUser scope needs no admin rights, which is exactly why it is the scope
# used. A machine locked down by GPO can still refuse; that is a policy conversation, not a bug,
# so this reports the fact rather than pretending it can fix it.
Write-Host ''
Write-Host '[2/3] Checking PowerShell execution policy...'
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -in @('Restricted', 'Undefined', 'AllSigned')) {
    Write-Host "      Current CurrentUser policy is '$policy', which may block these scripts."
    Write-Host '      Fix it without admin rights by running:'
    Write-Host '        Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
    Write-Host '      If that command is refused, this machine is locked down by group policy.'
} else {
    Write-Host "      Policy is '$policy' - OK."
}

# ── 3. Existing conda must be Miniforge ───────────────────────────────────────
# Same rule as the Linux module: this repo standardizes on Miniforge because Miniconda
# hard-codes the Anaconda defaults channel, which carries commercial licensing terms.
Write-Host ''
Write-Host '[3/3] Checking for an existing conda install...'
$miniconda = Join-Path $env:LOCALAPPDATA 'miniconda3'
if (Test-Path $miniconda) {
    Write-Host "      WARNING: Miniconda found at $miniconda"
    Write-Host '      This repo uses Miniforge. Remove Miniconda before deploying.'
} elseif (Test-Path $MiniforgeDir) {
    Write-Host "      Miniforge already installed at $MiniforgeDir - OK."
} else {
    Write-Host '      No conda found. 3_deploy.ps1 will install Miniforge.'
}

Write-Host ''
Write-Host '=== Setup checks complete. Nothing was changed. ==='
