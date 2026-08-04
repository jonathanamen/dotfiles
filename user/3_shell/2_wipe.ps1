# 2_wipe.ps1 - Remove the dotfiles block from the PowerShell profile
#
# Usage:
#   .\2_wipe.ps1
#
# What it does:
#   - Backs the profile up
#   - Removes everything between the dotfiles markers, inclusive
#   - Keeps only the most recent backup
#
# Anything you added to the profile OUTSIDE the markers survives. That is the whole point of the
# markers: this module owns its block and nothing else in the file.
#
# -Force is accepted and ignored here: this wipe never prompts. Every 2_wipe.ps1 takes the same
# switch so bootstrap.ps1 can call all of them identically.

param([switch]$Force)

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$MarkerStart = '# >>> dotfiles shell config >>>'
$MarkerEnd = '# <<< dotfiles shell config <<<'

Write-Host '=== Shell Wipe ==='
Write-Host ''
Write-Host '[1/2] Removing the dotfiles block...'

if (-not (Test-Path $PROFILE)) {
    Write-Host '      No profile exists - nothing to remove.'
    Write-Host ''
    Write-Host '=== Shell wipe complete. ==='
    exit 0
}

$lines = @(Get-Content $PROFILE)
if (-not ($lines -contains $MarkerStart)) {
    Write-Host '      Block not present - nothing to remove.'
} else {
    $backup = "$PROFILE.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $PROFILE $backup -Force
    Write-Host "      Backed up profile to: $backup"

    # Walk the file once and keep everything outside the marker pair. A regex over the whole file
    # would also work, but this stays correct if the block is ever present more than once.
    $kept = New-Object System.Collections.Generic.List[string]
    $inBlock = $false
    foreach ($line in $lines) {
        if ($line -eq $MarkerStart) { $inBlock = $true; continue }
        if ($line -eq $MarkerEnd) { $inBlock = $false; continue }
        if (-not $inBlock) { $kept.Add($line) }
    }

    Set-Content -Path $PROFILE -Value $kept -Encoding utf8
    Write-Host '      Block removed.'
}

# ── Keep only the newest backup ───────────────────────────────────────────────
# Same rule the bash module documents: git holds the full history, so a local backup is only a
# safety net for the current run and older ones are noise.
Write-Host ''
Write-Host '[2/2] Rotating backups...'

$profileDir = Split-Path -Parent $PROFILE
$profileName = Split-Path -Leaf $PROFILE
$backups = @(Get-ChildItem -Path $profileDir -Filter "$profileName.bak.*" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending)

if ($backups.Count -gt 1) {
    $backups | Select-Object -Skip 1 | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "      Removed old backup: $($_.Name)"
    }
} else {
    Write-Host '      Nothing to rotate.'
}

Write-Host ''
Write-Host '=== Shell wipe complete. ==='
Write-Host '    Open a new PowerShell window for the change to take effect.'
