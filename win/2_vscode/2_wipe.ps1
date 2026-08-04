# 2_wipe.ps1 - Clean uninstall of VS Code extensions and user settings
#
# Usage:
#   .\2_wipe.ps1           # asks for confirmation
#   .\2_wipe.ps1 -Force    # no prompt, for bootstrap.ps1
#
# What it does:
#   - Uninstalls every currently installed extension
#   - Removes settings.json and keybindings.json from %APPDATA%\Code\User
#
# WARNING: destructive. Run 1_save.ps1 first if you have unsaved changes.
# Your VS Code INSTALL is not touched, only its configuration.

param([switch]$Force)

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$UserDir = Join-Path $env:APPDATA 'Code\User'

Write-Host '=== VS Code Wipe ==='
Write-Host ''
Write-Host 'WARNING: This will uninstall all extensions and clear user settings.'
Write-Host 'Run 1_save.ps1 first if you have unsaved changes.'
Write-Host ''

# bootstrap.ps1 passes -Force because it wipes before every deploy by design. An interactive run
# still has to say yes: this throws away extensions the deploy list may not contain.
if (-not $Force) {
    $confirm = Read-Host 'Are you sure you want to wipe? (yes/no)'
    if ($confirm -ne 'yes') {
        Write-Host 'Wipe cancelled.'
        exit 0
    }
}

# ── 1. Uninstall every extension ──────────────────────────────────────────────
Write-Host ''
Write-Host '[1/2] Uninstalling extensions...'

$installed = & code --list-extensions
if (-not $installed) {
    Write-Host '      None installed.'
} else {
    foreach ($ext in $installed) {
        if ([string]::IsNullOrWhiteSpace($ext)) { continue }
        Write-Host "      Uninstalling $ext"
        # A failed uninstall must not abort the loop and leave the rest installed - the wipe is
        # meant to reach a known state, and one stuck extension is not a reason to stop.
        & code --uninstall-extension $ext --force 2>$null
    }
    Write-Host '      Extensions removed.'
}

# ── 2. Remove settings ────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/2] Removing user settings...'

foreach ($file in @('settings.json', 'keybindings.json')) {
    $target = Join-Path $UserDir $file
    if (Test-Path $target) {
        Remove-Item $target -Force
        Write-Host "      Removed $file."
    } else {
        Write-Host "      $file not present - nothing to remove."
    }
}

Write-Host ''
Write-Host '=== VS Code wipe complete. ==='
