# 2_wipe.ps1 - Remove ONLY what personal_overlay added
#
# Usage:
#   .\2_wipe.ps1
#
# What it does:
#   - Removes settings-overlay.json's keys from settings.json, leaving every other key
#     (including whatever the team deploy wrote) untouched
#   - Uninstalls Power Platform CLI (delegates to ..\5_pac_cli\2_wipe.ps1)
#   - Removes ONLY the TDBI-path blocks from the PowerShell profile and Git Bash files
#
# Deliberately does NOT call ..\3_shell\2_wipe.ps1: that script removes the MAIN shell block too,
# and this overlay never owns that block -- a team deploy (or personal dotfiles' own 3_shell) may
# be the one that wrote it. The TDBI-path blocks are safe to always remove here because
# dotfiles-team never writes them; they exist only in this personal ecosystem.

param([switch]$Force)

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserTreeRoot = Split-Path -Parent $RepoDir
$UserDir = Join-Path $env:APPDATA 'Code\User'
$SettingsFile = Join-Path $UserDir 'settings.json'
$OverlayFile = Join-Path $RepoDir 'settings-overlay.json'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

$MarkerTdbiStart = '# >>> dotfiles TDBI path >>>'
$MarkerTdbiEnd = '# <<< dotfiles TDBI path <<<'

function Remove-MarkedBlock([string]$Path, [string]$Start, [string]$End, [switch]$Posix) {
    if (-not (Test-Path $Path)) { return $false }
    $lines = @(Get-Content $Path)
    if (-not ($lines -contains $Start)) { return $false }
    Copy-Item $Path "$Path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')" -Force
    $kept = New-Object System.Collections.Generic.List[string]
    $inBlock = $false
    foreach ($line in $lines) {
        if ($line -eq $Start) { $inBlock = $true; continue }
        if ($line -eq $End) { $inBlock = $false; continue }
        if (-not $inBlock) { $kept.Add($line) }
    }
    if ($Posix) {
        $Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($Path, (($kept -join "`n").TrimEnd() + "`n"), $Utf8NoBom)
    } else {
        Set-Content -Path $Path -Value $kept -Encoding utf8
    }
    return $true
}

Write-Host '=== Personal Overlay Wipe ==='

# ── 1. Settings ────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[1/3] Removing personal settings keys...'
if (Test-Path $SettingsFile) {
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
    $overlay = Get-Content $OverlayFile -Raw | ConvertFrom-Json
    $removed = $false
    foreach ($prop in $overlay.PSObject.Properties) {
        if ($settings.PSObject.Properties[$prop.Name]) {
            $settings.PSObject.Properties.Remove($prop.Name)
            Write-Host "      Removed $($prop.Name)"
            $removed = $true
        }
    }
    if ($removed) {
        Copy-Item $SettingsFile "$SettingsFile.bak.$(Get-Date -Format 'yyyyMMddHHmmss')" -Force
        $json = $settings | ConvertTo-Json -Depth 20
        [System.IO.File]::WriteAllText($SettingsFile, $json, $Utf8NoBom)
    } else {
        Write-Host '      None of the overlay keys were present - nothing to remove.'
    }
} else {
    Write-Host '      No settings.json - nothing to remove.'
}

# ── 2. Power Platform CLI ──────────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/3] Uninstalling Power Platform CLI...'
& (Join-Path $UserTreeRoot '5_pac_cli\2_wipe.ps1') -Force

# ── 3. TDBI-path shell blocks only ────────────────────────────────────────────
Write-Host ''
Write-Host '[3/3] Removing TDBI-path shell blocks...'

if (Remove-MarkedBlock -Path $PROFILE -Start $MarkerTdbiStart -End $MarkerTdbiEnd) {
    Write-Host '      Removed from the PowerShell profile.'
} else {
    Write-Host '      Not present in the PowerShell profile - nothing to remove.'
}

$bashrc = Join-Path $env:USERPROFILE '.bashrc'
if (Remove-MarkedBlock -Path $bashrc -Start $MarkerTdbiStart -End $MarkerTdbiEnd -Posix) {
    Write-Host '      Removed from .bashrc.'
} else {
    Write-Host '      Not present in .bashrc - nothing to remove.'
}

Write-Host ''
Write-Host '=== Personal overlay wipe complete. ==='
