# 3_deploy.ps1 - Install Az PowerShell module for the current user (no elevation required)
#
# Usage:
#   .\3_deploy.ps1
#
# What it does:
#   - Installs the Az PowerShell module from PSGallery into the current user's module path
#   - Skips if Az is already installed and up to date

$ErrorActionPreference = 'Stop'

Write-Host '=== Az PowerShell Deploy ==='

$identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERROR: Do not run this as Administrator. Everything installs into your own user profile.'
    exit 1
}

Write-Host ''
Write-Host '[1/1] Installing Az PowerShell module (CurrentUser scope)...'

if (Get-Module -ListAvailable -Name Az.Accounts -ErrorAction SilentlyContinue) {
    $installed = (Get-Module -ListAvailable -Name Az.Accounts | Sort-Object Version -Descending | Select-Object -First 1).Version
    Write-Host "      Already installed (Az.Accounts $installed). Running update check..."
    Update-Module Az -Force -ErrorAction SilentlyContinue
} else {
    Install-Module Az -Scope CurrentUser -Repository PSGallery -Force -AllowClobber
}

Write-Host ''
Write-Host 'Deploy OK. Run 4_test.ps1 to verify.'
