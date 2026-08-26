# 1_save.ps1 - Snapshot the live PowerShell and Git Bash profiles to this repo
#
# Usage:
#   .\1_save.ps1
#
# What it does:
#   - Copies the live PowerShell profile to config\Microsoft.PowerShell_profile.ps1
#   - Copies the live ~/.bashrc and ~/.bash_profile to config\bashrc and config\bash_profile
#
# This is a SNAPSHOT for reference and history, not the deploy source. 3_deploy.ps1 writes its
# block from the script itself, exactly as the bash module does, so that the deployed config is
# always what the repo's code says rather than whatever was last saved off a machine.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigDir = Join-Path $RepoDir 'config'

Write-Host '=== Shell Save ==='
Write-Host ''

if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}

$saved = 0

Write-Host '[1/2] Saving the PowerShell profile...'
if (Test-Path $PROFILE) {
    Copy-Item $PROFILE (Join-Path $ConfigDir 'Microsoft.PowerShell_profile.ps1') -Force
    Write-Host '      Saved config\Microsoft.PowerShell_profile.ps1.'
    $saved++
} else {
    # Not an error any more. A Git Bash machine legitimately has no PowerShell profile, and
    # exiting here would skip the bash snapshot below and save nothing at all (REC-E-0025).
    Write-Host '      No PowerShell profile on this machine - skipping.'
}

Write-Host ''
Write-Host '[2/2] Saving the Git Bash profile...'
$bashHome = $env:USERPROFILE
foreach ($pair in @(@('.bashrc', 'bashrc'), @('.bash_profile', 'bash_profile'))) {
    $live = Join-Path $bashHome $pair[0]
    if (Test-Path $live) {
        Copy-Item $live (Join-Path $ConfigDir $pair[1]) -Force
        Write-Host "      Saved config\$($pair[1])."
        $saved++
    } else {
        Write-Host "      No $($pair[0]) on this machine - skipping."
    }
}

if ($saved -eq 0) {
    Write-Host ''
    Write-Host '      ERROR: nothing to save. Run 3_deploy.ps1 first.'
    exit 1
}

Write-Host ''
Write-Host '=== Save complete. Review and commit your changes: ==='
Write-Host ''
Write-Host '    git status'
Write-Host '    git add -A'
Write-Host "    git commit -m 'chore: snapshot shell profiles'"
Write-Host '    git push'
