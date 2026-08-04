# 3_deploy.ps1 - Deploy VS Code settings, keybindings and extensions
#
# Usage:
#   .\3_deploy.ps1                       # global config only
#   .\3_deploy.ps1 p008-arcane-predictive  # global + project config
#
# What it does:
#   - Copies the SHARED global settings and keybindings into %APPDATA%\Code\User
#   - Installs the shared curated extension list
#   - Installs the AI extension this machine chose in config.env, if any
#
# Settings and the extension list are read from ..\..\2_vscode\global\, the same files the WSL
# module deploys. There is no Windows copy of them: a second copy is a second thing to keep true.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path            # user\2_vscode
$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $RepoDir)      # repo root
$GlobalDir = Join-Path $DotfilesRoot '2_vscode\global'                # SHARED with the WSL module
$ProjectsDir = Join-Path $DotfilesRoot '2_vscode\projects'            # SHARED project configs
$UserDir = Join-Path $env:APPDATA 'Code\User'                         # where the Windows UI reads
$Project = $args[0]

# ── Load config.env for the AI extension choice ───────────────────────────────
# config.env is bash `KEY="value"` syntax, shared with the WSL tree. Parsed rather than sourced,
# because PowerShell cannot source a bash file and duplicating the file would defeat the point.
$Config = @{}
$ConfigFile = Join-Path $DotfilesRoot 'config.env'
if (Test-Path $ConfigFile) {
    foreach ($line in Get-Content $ConfigFile) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
        $parts = $trimmed -split '=', 2
        if ($parts.Count -eq 2) {
            $Config[$parts[0].Trim()] = $parts[1].Trim().Trim('"').Trim("'")
        }
    }
}

Write-Host '=== VS Code Deploy ==='

# ── 1. Global settings ────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[1/4] Copying global VS Code settings...'

if (-not (Test-Path $UserDir)) {
    New-Item -ItemType Directory -Path $UserDir -Force | Out-Null
}
Copy-Item (Join-Path $GlobalDir 'settings.json')    (Join-Path $UserDir 'settings.json')    -Force
Copy-Item (Join-Path $GlobalDir 'keybindings.json') (Join-Path $UserDir 'keybindings.json') -Force
Write-Host "      settings.json and keybindings.json copied to $UserDir."

# ── 2. Global extensions ──────────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/4] Installing global extensions...'

Get-Content (Join-Path $GlobalDir 'extensions.txt') |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' -and -not $_.StartsWith('#') } |
    ForEach-Object {
        Write-Host "      Installing $_"
        & code --install-extension $_ --force 2>$null
    }
Write-Host '      Global extensions done.'

# ── 3. The AI extension this machine chose ────────────────────────────────────
# A machine with no admin rights may not be permitted Claude Code at all, so which assistant gets
# installed is a per-machine decision, recorded in config.env by 0_personalize. 'none' is a valid
# and complete answer, not a missing value.
Write-Host ''
Write-Host '[3/4] Installing the AI extension for this machine...'

$aiExtension = $Config['DOTFILES_AI_EXTENSION']
if ([string]::IsNullOrWhiteSpace($aiExtension) -or $aiExtension -eq 'none') {
    Write-Host '      None chosen - skipping.'
} else {
    Write-Host "      Installing $aiExtension"
    & code --install-extension $aiExtension --force 2>$null
}

# ── 4. Project config (optional) ──────────────────────────────────────────────
Write-Host ''
if ([string]::IsNullOrWhiteSpace($Project)) {
    Write-Host '[4/4] No project specified - skipping project config.'
    if (Test-Path $ProjectsDir) {
        Write-Host '      Available projects:'
        Get-ChildItem $ProjectsDir -Directory | ForEach-Object { Write-Host "        - $($_.Name)" }
    }
} else {
    $projectDir = Join-Path $ProjectsDir $Project
    if (-not (Test-Path $projectDir)) {
        Write-Host "[4/4] ERROR: project not found: $projectDir"
        exit 1
    }
    Write-Host "[4/4] Applying project config: $Project"
    $projectExtensions = Join-Path $projectDir 'extensions.txt'
    if (Test-Path $projectExtensions) {
        Get-Content $projectExtensions |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' -and -not $_.StartsWith('#') } |
            ForEach-Object {
                Write-Host "      Installing $_"
                & code --install-extension $_ --force 2>$null
            }
    }
    Write-Host '      Project extensions done.'
    Write-Host "      Project settings.json stays in the repo - open $projectDir as a workspace."
}

Write-Host ''
Write-Host '=== VS Code deploy complete. ==='
