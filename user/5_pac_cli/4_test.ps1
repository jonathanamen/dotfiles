# 4_test.ps1 - Verify Power Platform CLI (pac) is installed and reachable
#
# Usage:
#   .\4_test.ps1

$ErrorActionPreference = 'Stop'

Write-Host '=== Power Platform CLI Test ==='

Write-Host ''
Write-Host '[1/1] Checking pac on PATH...'
if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    Write-Host 'FAIL: pac not found on PATH. Open a new terminal after install and retry.'
    exit 1
}
$ver = pac --version 2>$null
Write-Host "      pac $ver"

Write-Host ''
Write-Host 'Test OK.'
