# 0_setup.ps1 - Prerequisites for the personal overlay (checks only, changes nothing)
#
# Usage:
#   .\0_setup.ps1
#
# What it checks:
#   - The `code` CLI is on PATH (there is a VS Code install to layer settings onto)
#   - %APPDATA%\Code\User exists (a team or personal deploy has already run)
#   - settings-overlay.json parses as valid JSON

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserDir = Join-Path $env:APPDATA 'Code\User'
$OverlayFile = Join-Path $RepoDir 'settings-overlay.json'

Write-Host '=== Personal Overlay Setup (checks only) ==='
Write-Host ''

Write-Host '[1/3] Checking for the code CLI...'
$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
    Write-Host "      Found: $($code.Source)"
} else {
    Write-Host '      ERROR: `code` is not on PATH. Install VS Code first.'
    exit 1
}

Write-Host ''
Write-Host '[2/3] Checking a settings.json exists to layer onto...'
if (Test-Path (Join-Path $UserDir 'settings.json')) {
    Write-Host "      Found $UserDir\settings.json - OK. This overlay merges into it, never replaces it."
} else {
    Write-Host "      WARNING: no settings.json at $UserDir yet."
    Write-Host '      Deploy a team or personal dotfiles first -- this overlay has nothing to layer onto.'
}

Write-Host ''
Write-Host '[3/3] Checking settings-overlay.json...'
if (-not (Test-Path $OverlayFile)) {
    Write-Host "      ERROR: not found at $OverlayFile"
    exit 1
}
try {
    Get-Content $OverlayFile -Raw | ConvertFrom-Json | Out-Null
    Write-Host '      Valid JSON - OK.'
} catch {
    Write-Host "      ERROR: settings-overlay.json does not parse: $_"
    exit 1
}

Write-Host ''
Write-Host '=== Setup checks complete. Nothing was changed. ==='
