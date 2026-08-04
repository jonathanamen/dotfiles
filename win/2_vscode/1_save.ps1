# 1_save.ps1 - Snapshot live VS Code state into this repo
#
# Usage:
#   .\1_save.ps1
#
# Files written (all SHARED with the WSL module - one copy, both platforms):
#   ..\..\2_vscode\global\settings.json       - live settings
#   ..\..\2_vscode\global\keybindings.json    - live keybindings
#   ..\..\2_vscode\global\extensions.snapshot - everything currently installed
#
# extensions.txt is NOT overwritten. It is the curated intentional list; the snapshot is live
# reality. Edit extensions.txt by hand when you want to change what a deploy installs.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $RepoDir)
$GlobalDir = Join-Path $DotfilesRoot '2_vscode\global'
$UserDir = Join-Path $env:APPDATA 'Code\User'

Write-Host '=== VS Code Save ==='

# ── 1. Settings and keybindings ───────────────────────────────────────────────
Write-Host ''
Write-Host '[1/2] Saving settings and keybindings...'

if (-not (Test-Path $UserDir)) {
    Write-Host "      ERROR: VS Code user directory not found at $UserDir"
    exit 1
}

foreach ($file in @('settings.json', 'keybindings.json')) {
    $source = Join-Path $UserDir $file
    if (Test-Path $source) {
        Copy-Item $source (Join-Path $GlobalDir $file) -Force
        Write-Host "      Saved global\$file."
    } else {
        Write-Host "      SKIP: $file does not exist yet on this machine."
    }
}

# ── 2. Installed extensions ───────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/2] Snapshotting installed extensions...'

& code --list-extensions | Out-File -FilePath (Join-Path $GlobalDir 'extensions.snapshot') -Encoding utf8
Write-Host '      Saved global\extensions.snapshot.'

Write-Host ''
Write-Host '=== Save complete. Review and commit your changes: ==='
Write-Host ''
Write-Host '    git status'
Write-Host '    git add -A'
Write-Host "    git commit -m 'chore: snapshot vscode config'"
Write-Host '    git push'
