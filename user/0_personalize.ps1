# 0_personalize.ps1 - Ask for this machine's personal config, then apply it
#
# Usage:
#   .\0_personalize.ps1
#
# Run this BEFORE bootstrap.ps1 on a fresh machine. Safe to run again - it offers your current
# values as defaults, so pressing Enter through it changes nothing.
#
# What it does:
#   - Asks for identity, paths, AI extension and backup-remote capability
#   - Writes them to the shared config.env at the repo root
#   - Configures git identity
#   - Writes this machine's attributes into TDBI's config\machine.local.json
#
# It ASKS rather than making you hand-edit config.env, unlike the bash 0_personalize.sh. That is
# deliberate: this runs on a machine with no WSL and possibly no editor set up yet, where "open
# config.env and fill it in" is a worse first instruction than four questions.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path        # user/
$DotfilesRoot = Split-Path -Parent $RepoDir                       # repo root
$ConfigFile = Join-Path $DotfilesRoot 'config.env'

Write-Host '================================================'
Write-Host '  dotfiles personalization (Windows, no admin)'
Write-Host '  Run this before bootstrap.ps1'
Write-Host '================================================'
Write-Host ''

# ── Load any existing config so re-running is safe ────────────────────────────
$Config = [ordered]@{}
if (Test-Path $ConfigFile) {
    foreach ($line in Get-Content $ConfigFile) {
        $trimmed = $line.Trim()
        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) { continue }
        $parts = $trimmed -split '=', 2
        if ($parts.Count -eq 2) {
            $Config[$parts[0].Trim()] = $parts[1].Trim().Trim('"').Trim("'")
        }
    }
    Write-Host "Loaded existing config.env - press Enter to keep any current value."
} else {
    Write-Host 'No config.env yet - this will create one.'
}
Write-Host ''

function Ask-Value {
    param([string]$Key, [string]$Prompt, [string]$Fallback = '')

    $current = $Config[$Key]
    if ([string]::IsNullOrWhiteSpace($current)) { $current = $Fallback }

    if ([string]::IsNullOrWhiteSpace($current)) {
        $answer = Read-Host $Prompt
    } else {
        $answer = Read-Host "$Prompt [$current]"
        if ([string]::IsNullOrWhiteSpace($answer)) { $answer = $current }
    }
    return $answer.Trim()
}

# ── Identity ──────────────────────────────────────────────────────────────────
Write-Host '-- Identity --'
$Config['DOTFILES_USER_NAME'] = Ask-Value 'DOTFILES_USER_NAME' 'Your full name'
$Config['DOTFILES_USER_EMAIL'] = Ask-Value 'DOTFILES_USER_EMAIL' 'Your email'
$Config['DOTFILES_GITHUB_USERNAME'] = Ask-Value 'DOTFILES_GITHUB_USERNAME' 'Your GitHub username'
$Config['DOTFILES_WINDOWS_USERNAME'] = Ask-Value 'DOTFILES_WINDOWS_USERNAME' 'Your Windows username' $env:USERNAME

# ── Paths ─────────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '-- Paths --'
$defaultGithub = Join-Path $env:USERPROFILE 'Documents\GitHub'
$Config['DOTFILES_GITHUB_PATH_WIN'] = Ask-Value 'DOTFILES_GITHUB_PATH_WIN' 'GitHub directory' $defaultGithub

# ── AI extension ──────────────────────────────────────────────────────────────
# A machine with no local admin may not be permitted every assistant, and 'none' is a complete
# answer rather than a missing value. The list is closed on purpose: a free-text extension id
# with a typo installs nothing and reports nothing.
Write-Host ''
Write-Host '-- AI extension --'
Write-Host '  1) GitHub Copilot        (GitHub.copilot)'
Write-Host '  2) Claude Code           (anthropic.claude-code)'
Write-Host '  3) Continue              (Continue.continue)'
Write-Host '  4) None'

$extensionByChoice = @{
    '1' = 'GitHub.copilot'
    '2' = 'anthropic.claude-code'
    '3' = 'Continue.continue'
    '4' = 'none'
}

$currentExtension = $Config['DOTFILES_AI_EXTENSION']
$defaultChoice = '4'
foreach ($entry in $extensionByChoice.GetEnumerator()) {
    if ($entry.Value -eq $currentExtension) { $defaultChoice = $entry.Key }
}

do {
    $choice = Read-Host "Choose 1-4 [$defaultChoice]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = $defaultChoice }
    $choice = $choice.Trim()
    if (-not $extensionByChoice.ContainsKey($choice)) {
        Write-Host '      Enter 1, 2, 3 or 4.'
    }
} while (-not $extensionByChoice.ContainsKey($choice))

$Config['DOTFILES_AI_EXTENSION'] = $extensionByChoice[$choice]
Write-Host "      Chose: $($Config['DOTFILES_AI_EXTENSION'])"

# ── Backup remote ─────────────────────────────────────────────────────────────
# This decides whether TDBI's evidence gate BLOCKS or warns. False is the safe answer: it makes
# the gate warn, which is correct for a machine with nowhere to copy L0 content to. Answering
# true when no remote exists creates a gate that can never be cleared.
Write-Host ''
Write-Host '-- git-annex backup remote --'
Write-Host '  Does this machine have a git-annex remote it can actually copy L0 content to?'
Write-Host '  Answer no unless you have deliberately wired one. No is correct for a laptop.'

$currentBackup = $Config['DOTFILES_BACKUP_REMOTE']
$defaultBackup = if ($currentBackup -eq 'true') { 'y' } else { 'n' }
$backupAnswer = Read-Host "Backup remote available? (y/n) [$defaultBackup]"
if ([string]::IsNullOrWhiteSpace($backupAnswer)) { $backupAnswer = $defaultBackup }
$Config['DOTFILES_BACKUP_REMOTE'] = if ($backupAnswer.Trim().ToLower().StartsWith('y')) { 'true' } else { 'false' }

# ── First project ─────────────────────────────────────────────────────────────
# Optional, and 'none' is the right answer more often than not. This scaffolds a VS Code workspace
# folder under the COMMITTED 2_vscode/projects/ tree, which means two things: a machine whose work
# is cloned repos rather than scratch projects has no use for it, and it must never be named after
# a client -- a company name in a committed folder is precisely what the gitignored company
# registry exists to keep out of this tree.
Write-Host ''
Write-Host '-- First project (optional) --'
Write-Host '  A VS Code workspace scaffold. Enter none if you do not want one.'
Write-Host '  Never name it after a client: this folder is committed.'
do {
    $Config['DOTFILES_FIRST_PROJECT'] = Ask-Value 'DOTFILES_FIRST_PROJECT' 'First project (p###-name, or none)' 'none'
    $answer = $Config['DOTFILES_FIRST_PROJECT']
    $valid = ($answer -eq 'none') -or ([string]::IsNullOrWhiteSpace($answer)) -or ($answer -match '^p[0-9]{3}-.+')
    if (-not $valid) { Write-Host '      Must look like p008-my-project, or none.' }
} while (-not $valid)
if ([string]::IsNullOrWhiteSpace($Config['DOTFILES_FIRST_PROJECT'])) {
    $Config['DOTFILES_FIRST_PROJECT'] = 'none'
}

# ── Write config.env ──────────────────────────────────────────────────────────
# Written in bash `KEY="value"` syntax because this file is SHARED with the WSL tree, which
# sources it. A PowerShell-native format here would fork the one file both platforms read.
Write-Host ''
Write-Host 'Writing config.env...'

$lines = @('# config.env - personal configuration. Gitignored, never committed.',
           "# Written by user\0_personalize.ps1", '')
foreach ($key in $Config.Keys) {
    $lines += "$key=`"$($Config[$key])`""
}
$lines | Out-File -FilePath $ConfigFile -Encoding utf8
Write-Host "  Wrote $ConfigFile"

# ── Git identity ──────────────────────────────────────────────────────────────
Write-Host ''
Write-Host 'Configuring git identity...'
if (Get-Command git -ErrorAction SilentlyContinue) {
    & git config --global user.name $Config['DOTFILES_USER_NAME']
    & git config --global user.email $Config['DOTFILES_USER_EMAIL']
    & git config --global init.defaultBranch main
    Write-Host "  Name:  $($Config['DOTFILES_USER_NAME'])"
    Write-Host "  Email: $($Config['DOTFILES_USER_EMAIL'])"
} else {
    Write-Host '  WARNING: git is not on PATH - skipping. Install Git and run this again.'
}

# ── Machine attributes for TDBI ───────────────────────────────────────────────
# Written only if a TDBI checkout is there. dotfiles is normally deployed BEFORE the repos are
# cloned, so a missing TDBI is the ordinary case on a fresh machine, not a failure: print the
# file and where it goes, and carry on.
Write-Host ''
Write-Host 'Recording machine attributes for TDBI...'

$machineName = $env:COMPUTERNAME.ToUpper()
$tdbiRoot = Join-Path (Split-Path -Parent $DotfilesRoot) 'TDBI'
$pythonPath = Join-Path $env:LOCALAPPDATA 'miniforge3\python.exe'

$machine = [ordered]@{
    platform      = 'windows'
    backup_remote = ($Config['DOTFILES_BACKUP_REMOTE'] -eq 'true')
    ai_extension  = $Config['DOTFILES_AI_EXTENSION']
    python        = $pythonPath
}
$machineJson = $machine | ConvertTo-Json

$tdbiConfig = Join-Path $tdbiRoot 'config'
if (Test-Path $tdbiConfig) {
    $target = Join-Path $tdbiConfig 'machine.local.json'
    $machineJson | Out-File -FilePath $target -Encoding utf8
    Write-Host "  Wrote $target"
    Write-Host "  Machine: $machineName"
} else {
    Write-Host "  No TDBI checkout at $tdbiRoot - nothing written."
    Write-Host '  After you clone TDBI, save this as TDBI\config\machine.local.json:'
    Write-Host ''
    $machineJson -split "`n" | ForEach-Object { Write-Host "    $_" }
}

# ── Summary ───────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '================================================'
Write-Host '  Personalization complete.'
Write-Host ''
Write-Host "  Machine:   $machineName"
Write-Host "  Name:      $($Config['DOTFILES_USER_NAME'])"
Write-Host "  GitHub:    $($Config['DOTFILES_GITHUB_USERNAME'])"
Write-Host "  AI:        $($Config['DOTFILES_AI_EXTENSION'])"
Write-Host "  Backup:    $($Config['DOTFILES_BACKUP_REMOTE'])"
Write-Host ''
Write-Host '  Next step: .\bootstrap.ps1'
Write-Host '================================================'
