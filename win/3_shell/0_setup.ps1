# 0_setup.ps1 - Prerequisites for the shell module (checks only, changes nothing)
#
# Usage:
#   .\0_setup.ps1
#
# What it checks:
#   - Where the PowerShell profile will be written, and whether OneDrive redirects it
#   - Whether the execution policy will let a profile run at all
#
# There is nothing to install. This module writes one text file, which is the whole reason it
# needs no admin rights.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

Write-Host '=== Shell Setup (checks only) ==='
Write-Host ''

# ── 1. Profile location ───────────────────────────────────────────────────────
Write-Host '[1/2] Checking the profile path...'
Write-Host "      Profile: $PROFILE"

$profileDir = Split-Path -Parent $PROFILE
if (Test-Path $profileDir) {
    Write-Host '      Directory exists - OK.'
} else {
    Write-Host '      Directory does not exist yet. 3_deploy.ps1 will create it.'
}

# Documents is commonly redirected into OneDrive, which is where the profile lives. Worth SAYING
# rather than discovering later: the profile then syncs between machines, and a machine-specific
# path written into it will follow you somewhere it does not resolve.
if ($profileDir -like '*OneDrive*') {
    Write-Host ''
    Write-Host '      NOTE: your profile lives inside OneDrive, so it syncs across machines.'
    Write-Host '      The dotfiles block writes machine-specific paths, so redeploy on each'
    Write-Host '      machine rather than relying on the synced copy.'
}

# ── 2. Execution policy ───────────────────────────────────────────────────────
# A Restricted policy does not just block these scripts, it stops the PROFILE loading at all -
# so the deploy would appear to succeed and change nothing about a new terminal.
Write-Host ''
Write-Host '[2/2] Checking the execution policy...'
$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -in @('Restricted', 'Undefined', 'AllSigned')) {
    Write-Host "      CurrentUser policy is '$policy' - your profile may not load."
    Write-Host '      Fix it without admin rights by running:'
    Write-Host '        Set-ExecutionPolicy -Scope CurrentUser RemoteSigned'
} else {
    Write-Host "      Policy is '$policy' - OK."
}

Write-Host ''
Write-Host '=== Setup checks complete. Nothing was changed. ==='
