# 3_deploy.ps1 - Layer personal-only additions on top of an already-deployed dotfiles slug
#
# Usage:
#   .\3_deploy.ps1
#
# Run this AFTER dotfiles-team (or any other team slug) has already deployed. It never runs on
# its own, and it is not part of user\bootstrap.ps1 -- see README.md for why.
#
# What it does:
#   - MERGES settings-overlay.json into %APPDATA%\Code\User\settings.json (patches only those
#     keys; every other key, including whatever the team deploy wrote, is left exactly as-is)
#   - Runs ..\5_pac_cli\3_deploy.ps1 as-is
#   - Runs ..\3_shell\3_deploy.ps1 as-is (already safe to layer -- see that script's own comments)

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path            # user\personal_overlay
$UserTreeRoot = Split-Path -Parent $RepoDir                           # user\
$UserDir = Join-Path $env:APPDATA 'Code\User'
$SettingsFile = Join-Path $UserDir 'settings.json'
$OverlayFile = Join-Path $RepoDir 'settings-overlay.json'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host '=== Personal Overlay Deploy ==='

# ── 1. Merge settings ─────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[1/3] Merging personal settings...'

if (-not (Test-Path $UserDir)) {
    New-Item -ItemType Directory -Path $UserDir -Force | Out-Null
}

# The live file, or an empty object if nothing has deployed here yet. ConvertFrom-Json on Windows
# PowerShell 5.1 returns a PSCustomObject, not a hashtable, so properties are set/removed through
# .PSObject rather than dictionary syntax.
if (Test-Path $SettingsFile) {
    Copy-Item $SettingsFile "$SettingsFile.bak.$(Get-Date -Format 'yyyyMMddHHmmss')" -Force
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
    if (-not $settings) { $settings = New-Object PSCustomObject }
} else {
    $settings = New-Object PSCustomObject
}

$overlay = Get-Content $OverlayFile -Raw | ConvertFrom-Json
foreach ($prop in $overlay.PSObject.Properties) {
    if ($settings.PSObject.Properties[$prop.Name]) {
        $settings.PSObject.Properties[$prop.Name].Value = $prop.Value
    } else {
        $settings | Add-Member -NotePropertyName $prop.Name -NotePropertyValue $prop.Value
    }
    Write-Host "      Set $($prop.Name) = $($prop.Value | ConvertTo-Json -Compress)"
}

# No BOM: Set-Content/-Encoding utf8 on Windows PowerShell 5.1 writes one, and a BOM at the top of
# settings.json is silently accepted by VS Code but has bitten JSON-consuming tooling elsewhere in
# this same repo family -- write it the same safe way everywhere.
$json = $settings | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($SettingsFile, $json, $Utf8NoBom)
Write-Host "      Wrote $SettingsFile."

# ── 2. Power Platform CLI ──────────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/3] Installing Power Platform CLI...'
& (Join-Path $UserTreeRoot '5_pac_cli\3_deploy.ps1')

# ── 3. TDBI shell additions ────────────────────────────────────────────────────
Write-Host ''
Write-Host '[3/3] Deploying TDBI shell additions...'
& (Join-Path $UserTreeRoot '3_shell\3_deploy.ps1')

Write-Host ''
Write-Host '=== Personal overlay deploy complete. ==='
