# 0_setup.ps1 - Prerequisites for the vscode module (checks only, changes nothing)
#
# Usage:
#   .\0_setup.ps1
#
# What it checks:
#   - The `code` CLI is on PATH
#   - VS Code is the USER installation, not the system-wide one
#
# This module never installs VS Code. On a machine with no admin rights the User Installer
# (VSCodeUserSetup-x64-*.exe) is the only one that will run, and it is a hand step - see
# win\README.md. What this module owns is the CONFIG inside an install that already exists.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$UserInstall = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code'
$SystemInstall = Join-Path $env:ProgramFiles 'Microsoft VS Code'

Write-Host '=== VS Code Setup (checks only) ==='
Write-Host ''

# ── 1. The code CLI ───────────────────────────────────────────────────────────
Write-Host '[1/2] Checking for the code CLI...'
$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
    Write-Host "      Found: $($code.Source)"
} else {
    Write-Host '      ERROR: `code` is not on PATH.'
    Write-Host '      Install VS Code with the USER installer:'
    Write-Host '        VSCodeUserSetup-x64-*.exe from https://code.visualstudio.com/download'
    Write-Host '      Then open a new terminal so PATH is refreshed.'
    exit 1
}

# ── 2. User install, not system ───────────────────────────────────────────────
# A system install is not broken, it just is not reproducible here: updating or repairing it
# needs rights this machine does not have, so a deploy that assumes it will eventually be stuck.
Write-Host ''
Write-Host '[2/2] Checking which VS Code install this is...'
if (Test-Path $UserInstall) {
    Write-Host "      User install found at $UserInstall - OK."
} elseif (Test-Path $SystemInstall) {
    Write-Host "      WARNING: only a SYSTEM install found at $SystemInstall"
    Write-Host '      It will work, but you cannot update or repair it without admin rights.'
} else {
    Write-Host '      WARNING: could not locate the install directory.'
    Write-Host '      The code CLI resolves, so this is probably a portable or relocated install.'
}

Write-Host ''
Write-Host '=== Setup checks complete. Nothing was changed. ==='
