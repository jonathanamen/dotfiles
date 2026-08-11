# 4_test.ps1 - Verify Az PowerShell module is installed and can connect
#
# Usage:
#   .\4_test.ps1

$ErrorActionPreference = 'Stop'

Write-Host '=== Az PowerShell Test ==='

Write-Host ''
Write-Host '[1/2] Checking Az.Accounts module...'
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Write-Host 'FAIL: Az.Accounts not found. Run 3_deploy.ps1 first.'
    exit 1
}
$ver = (Get-Module -ListAvailable -Name Az.Accounts | Sort-Object Version -Descending | Select-Object -First 1).Version
Write-Host "      Az.Accounts $ver"

Write-Host ''
Write-Host '[2/2] Checking Az.Monitor module (required for metrics)...'
if (-not (Get-Module -ListAvailable -Name Az.Monitor)) {
    Write-Host 'FAIL: Az.Monitor not found. Run 3_deploy.ps1 first.'
    exit 1
}
Write-Host '      Az.Monitor found.'

Write-Host ''
Write-Host 'Test OK. Run Connect-AzAccount to authenticate before using the tools.'
