# 0_setup.ps1 - Check prerequisites for the pac_cli module
#
# Usage:
#   .\0_setup.ps1
#
# What it does:
#   - Verifies winget is available
#   - Verifies internet connectivity to Microsoft download servers

$ErrorActionPreference = 'Stop'

Write-Host '=== Power Platform CLI (pac) Setup ==='

Write-Host ''
Write-Host '[1/2] Checking winget...'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'ERROR: winget not found. Install App Installer from the Microsoft Store.'
    exit 1
}
Write-Host '      winget is available.'

Write-Host ''
Write-Host '[2/2] Checking internet connectivity...'
try {
    $null = Invoke-WebRequest -Uri 'https://download.microsoft.com' -Method Head -TimeoutSec 5 -UseBasicParsing
    Write-Host '      Internet reachable.'
} catch {
    Write-Host 'ERROR: Cannot reach download.microsoft.com. Check your internet connection.'
    exit 1
}

Write-Host ''
Write-Host 'Setup OK.'
