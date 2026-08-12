# 3_deploy.ps1 - Install Power Platform CLI (pac) via winget
#
# Usage:
#   .\3_deploy.ps1
#
# What it does:
#   - Installs Microsoft PowerApps CLI (pac) via winget
#   - Skips if pac is already installed and runs upgrade check

$ErrorActionPreference = 'Stop'

Write-Host '=== Power Platform CLI Deploy ==='

Write-Host ''
Write-Host '[1/1] Installing Power Platform CLI...'

if (Get-Command pac -ErrorAction SilentlyContinue) {
    $ver = (pac --version 2>$null)
    Write-Host "      Already installed ($ver). Running upgrade check..."
    winget upgrade --id Microsoft.PowerAppsCLI --accept-package-agreements --accept-source-agreements
} else {
    winget install --id Microsoft.PowerAppsCLI --accept-package-agreements --accept-source-agreements
}

Write-Host ''
Write-Host 'Deploy OK. Open a new terminal so pac is on PATH, then run 4_test.ps1.'
