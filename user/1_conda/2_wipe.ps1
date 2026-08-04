# 2_wipe.ps1 - Remove the user-scope Miniforge install
#
# Usage:
#   .\2_wipe.ps1
#
# What it does:
#   - Deletes %LOCALAPPDATA%\miniforge3
#
# Destructive by design: bootstrap.ps1 wipes before it deploys so the deployed state is always
# exactly what the repo says, never an accumulation. Nothing outside the install directory is
# touched - PATH lives in the PowerShell profile and is 3_shell's to remove.
#
# -Force is accepted and ignored here: this wipe never prompts. Every 2_wipe.ps1 takes the same
# switch so bootstrap.ps1 can call all of them identically, rather than keeping a list of which
# ones happen to ask a question.

param([switch]$Force)

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$MiniforgeDir = Join-Path $env:LOCALAPPDATA 'miniforge3'

Write-Host '=== Conda Wipe ==='
Write-Host ''
Write-Host '[1/1] Removing Miniforge...'

if (Test-Path $MiniforgeDir) {
    # A running python.exe holds a lock on files inside the install, and a half-deleted conda is
    # worse than either state - it passes a Test-Path check and fails every import. Say so plainly
    # rather than leaving a corpse behind.
    try {
        Remove-Item -Path $MiniforgeDir -Recurse -Force
        Write-Host "      Removed $MiniforgeDir."
    } catch {
        Write-Host "      ERROR: could not fully remove $MiniforgeDir"
        Write-Host '      Close any open python, conda or VS Code windows and run this again.'
        exit 1
    }
} else {
    Write-Host '      Not installed - nothing to remove.'
}

Write-Host ''
Write-Host '=== Conda wipe complete. ==='
