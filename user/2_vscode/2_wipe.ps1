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

# NOT 'Stop' (O-1248). `code.cmd` is a node wrapper and node writes deprecation warnings to stderr;
# in PowerShell 5.1 a native command's stderr becomes a NativeCommandError, which under 'Stop' is
# terminating. That aborted the deploy on a real machine over a warning about `url.parse()`. A wipe
# is meant to reach a known state, so one noisy or stuck extension must not stop the rest.
$ErrorActionPreference = 'Continue'

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
        # meant to reach a known state, and one stuck extension is not a reason to stop. stderr is
        # NOT redirected: doing so is what wrapped a harmless node warning into a terminating error.
        & code --uninstall-extension $ext --force
        if ($LASTEXITCODE -ne 0) {
            Write-Host "      WARNING: could not uninstall $ext (exit $LASTEXITCODE)"
        }
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
