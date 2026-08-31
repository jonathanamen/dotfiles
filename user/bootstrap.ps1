# bootstrap.ps1 - Full machine setup for a no-admin, no-WSL Windows machine
#
# Usage:
#   .\bootstrap.ps1
#
# Prerequisites (see user\README.md - none of them need administrator rights):
#   - config.env exists at the repo root (copy config.env.example and fill it in)
#   - VS Code installed with the USER installer
#   - Git installed per-user, SSH keys in %USERPROFILE%\.ssh
#
# What it does:
#   1. Wipes all modules in reverse dependency order (shell, vscode, conda)
#   2. Deploys all modules in dependency order (conda, vscode, shell)
#   3. Runs all module tests to verify the deployment
#
# Wiping before deploying guarantees a clean state every time, exactly as the root bootstrap.sh
# does. There is no 4_node and no 5_annex here - see user\README.md for why.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path        # absolute path to user/
$DotfilesRoot = Split-Path -Parent $RepoDir                        # repo root, one level up
$ConfigFile = Join-Path $DotfilesRoot 'config.env'                 # shared personal config

Write-Host '================================================'
Write-Host '  dotfiles bootstrap (Windows, no admin)'
Write-Host '  Full machine setup'
Write-Host '================================================'
Write-Host ''

# ── Refuse to run elevated ────────────────────────────────────────────────────
# The root bootstrap.sh refuses to run under sudo for the same reason: a tool installed as
# another user is not on THIS user's PATH, and the whole point of this tree is that nothing
# here needs elevation. If it only works elevated, it is wrong.
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERROR: Do not run this as Administrator.'
    Write-Host '       Everything here installs into your own user profile.'
    exit 1
}

# ── Check config.env exists ───────────────────────────────────────────────────
if (-not (Test-Path $ConfigFile)) {
    Write-Host 'ERROR: config.env not found at the repo root.'
    Write-Host ''
    Write-Host 'Create it from the example file:'
    Write-Host '  copy config.env.example config.env'
    exit 1
}

# The modules, in dependency order. Wipe walks this list backwards.
$Modules = @('1_conda', '2_vscode', '3_shell', '4_azure_cli', '5_pac_cli')

# ── Wipe all modules in reverse dependency order ──────────────────────────────
Write-Host '--- Wiping all modules ---'
Write-Host ''
foreach ($module in ($Modules | Sort-Object -Descending)) {
    $wipe = Join-Path $RepoDir "$module\2_wipe.ps1"
    # 5_pac_cli has no 2_wipe.ps1 -- pac has no clean per-user uninstall this tree provides.
    if (-not (Test-Path $wipe)) {
        Write-Host "Skipping $module wipe (no 2_wipe.ps1)..."
        Write-Host ''
        continue
    }
    Write-Host "Wiping $module..."
    # -Force because a bootstrap must run unattended. Every 2_wipe.ps1 takes the switch, so this
    # call is identical for all of them; the vscode wipe is the one that would otherwise stop and
    # ask, which would hang a bootstrap that nobody is watching.
    & $wipe -Force
    Write-Host ''
}

# ── Deploy all modules in dependency order ────────────────────────────────────
Write-Host '--- Deploying all modules ---'
Write-Host ''
foreach ($module in $Modules) {
    $deploy = Join-Path $RepoDir "$module\3_deploy.ps1"
    Write-Host "Deploying $module..."
    & $deploy
    Write-Host ''
}

# ── Test all modules ──────────────────────────────────────────────────────────
# Tests report rather than throw, so one failing module does not hide the others. The exit code
# below is what a caller checks.
Write-Host '--- Testing all modules ---'
Write-Host ''
$failed = @()
foreach ($module in $Modules) {
    $test = Join-Path $RepoDir "$module\4_test.ps1"
    Write-Host "Testing $module..."
    & $test
    if ($LASTEXITCODE -ne 0) { $failed += $module }
    Write-Host ''
}

Write-Host '================================================'
if ($failed.Count -gt 0) {
    Write-Host "  Bootstrap finished with failures in: $($failed -join ', ')"
    Write-Host '================================================'
    exit 1
}
Write-Host '  Bootstrap complete. All modules deployed and tested.'
Write-Host ''
Write-Host '  Open a NEW PowerShell window so the profile loads.'
Write-Host ''
# TDBI is normally already cloned by this point -- 0_personalize.ps1 wants it present so it can
# write config\machine.local.json on the first pass instead of printing it to paste. The old wording
# here told you to clone it AFTERWARDS, which contradicted that and would have left the machine
# file unwritten. Found by citizen 000 reading the output of a successful run (O-1248).
Write-Host '  Next:'
Write-Host '    - Clone any corpus repos you still need beside TDBI.'
Write-Host '    - If TDBI was cloned AFTER you ran 0_personalize.ps1, run it again so it can'
Write-Host '      write TDBI\config\machine.local.json.'
Write-Host '    - Re-run user\3_shell\3_deploy.ps1 whenever you change config.env.'
Write-Host '================================================'
