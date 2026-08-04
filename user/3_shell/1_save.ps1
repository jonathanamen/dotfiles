# 1_save.ps1 - Snapshot the live PowerShell profile to this repo
#
# Usage:
#   .\1_save.ps1
#
# What it does:
#   - Copies the live PowerShell profile to config\Microsoft.PowerShell_profile.ps1
#
# This is a SNAPSHOT for reference and history, not the deploy source. 3_deploy.ps1 writes its
# block from the script itself, exactly as the bash module does, so that the deployed config is
# always what the repo's code says rather than whatever was last saved off a machine.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path $RepoDir 'config'

Write-Host '=== Shell Save ==='
Write-Host ''
Write-Host '[1/1] Saving the PowerShell profile...'

if (-not (Test-Path $PROFILE)) {
    Write-Host "      ERROR: no profile found at $PROFILE"
    Write-Host '      Run 3_deploy.ps1 first.'
    exit 1
}

if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

Copy-Item $PROFILE (Join-Path $ConfigDir 'Microsoft.PowerShell_profile.ps1') -Force
Write-Host '      Saved config\Microsoft.PowerShell_profile.ps1.'

Write-Host ''
Write-Host '=== Save complete. Review and commit your changes: ==='
Write-Host ''
Write-Host '    git status'
Write-Host '    git add -A'
Write-Host "    git commit -m 'chore: snapshot powershell profile'"
Write-Host '    git push'
