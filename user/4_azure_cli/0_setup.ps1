# 0_setup.ps1 - Check prerequisites for the azure_cli module
#
# Usage:
#   .\0_setup.ps1
#
# What it does:
#   - Verifies PowerShellGet is available for module install
#   - Verifies internet connectivity to PSGallery

$ErrorActionPreference = 'Stop'

Write-Host '=== Azure (Az PowerShell) Setup ==='

Write-Host ''
Write-Host '[1/2] Checking PowerShellGet...'
if (-not (Get-Module -ListAvailable -Name PowerShellGet)) {
    Write-Host 'ERROR: PowerShellGet not found. It ships with PowerShell 5.1+.'
    exit 1
}
Write-Host '      PowerShellGet is available.'

Write-Host ''
Write-Host '[2/2] Checking PSGallery connectivity...'
try {
    $null = Invoke-WebRequest -Uri 'https://www.powershellgallery.com' -Method Head -TimeoutSec 5 -UseBasicParsing
    Write-Host '      PSGallery reachable.'
} catch {
    Write-Host 'ERROR: Cannot reach powershellgallery.com. Check your internet connection.'
    exit 1
}

Write-Host ''
Write-Host 'Setup OK.'
