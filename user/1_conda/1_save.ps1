# 1_save.ps1 - Snapshot the live base environment to this repo
#
# Usage:
#   .\1_save.ps1
#
# What it does:
#   - Writes the live base-env package list to base-packages.snapshot
#
# It writes a SNAPSHOT, never base-packages.txt. That file is the curated, intentional list the
# deploy installs from; this one records what is actually on the machine. The same split the
# vscode module already makes between extensions.txt and extensions.snapshot, and for the same
# reason: overwriting the curated list with live reality means every transitive dependency conda
# happened to pull becomes something the next machine is told to install on purpose.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SnapshotFile = Join-Path $RepoDir 'base-packages.snapshot'
$MiniforgeDir = Join-Path $env:LOCALAPPDATA 'miniforge3'
$CondaExe = Join-Path $MiniforgeDir 'Scripts\conda.exe'

Write-Host '=== Conda Save ==='
Write-Host ''
Write-Host '[1/1] Snapshotting the base environment...'

if (-not (Test-Path $CondaExe)) {
    Write-Host "      ERROR: conda not found at $CondaExe"
    Write-Host '      Run 3_deploy.ps1 first.'
    exit 1
}

& $CondaExe list -n base --export | Out-File -FilePath $SnapshotFile -Encoding utf8

Write-Host "      Saved $SnapshotFile."

Write-Host ''
Write-Host '=== Save complete. Review and commit your changes: ==='
Write-Host ''
Write-Host '    git status'
Write-Host '    git add -A'
Write-Host "    git commit -m 'chore: snapshot windows base env'"
Write-Host '    git push'
