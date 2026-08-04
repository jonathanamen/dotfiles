# 3_deploy.ps1 - Deploy the dotfiles shell config into the PowerShell profile
#
# Usage:
#   .\3_deploy.ps1
#
# What it does:
#   - Appends the dotfiles block to your PowerShell profile
#   - Wraps it in markers so 2_wipe.ps1 can remove it cleanly
#   - Backs the profile up first
#   - Skips if the block is already present (idempotent)
#
# This is the counterpart of the WSL module's ~/.bashrc block. It is what puts the user-scope
# Miniforge on PATH, so nothing else has to know where python lives.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path            # user\3_shell
$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $RepoDir)      # repo root
$MarkerStart = '# >>> dotfiles shell config >>>'
$MarkerEnd = '# <<< dotfiles shell config <<<'

# ── Load config.env for the GitHub path ───────────────────────────────────────
# Parsed, not sourced: config.env is bash syntax and is SHARED with the WSL tree, so it is read
# rather than duplicated. Its GitHub path is a WSL path, so the Windows one is derived instead.
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

# Prefer an explicit Windows path if config.env carries one; otherwise assume the standard
# layout under the user profile. Never translate the WSL path - a machine with no WSL has no
# /mnt/c, and a path that resolves nowhere is worse than a sensible default.
$githubPath = $Config['DOTFILES_GITHUB_PATH_WIN']
if ([string]::IsNullOrWhiteSpace($githubPath)) {
    # Ask Windows where Documents is (O-1248). OneDrive redirects it on most machines, and
    # assuming %USERPROFILE%\Documents points the `gh` alias at a folder that may not be the one
    # holding the repos -- or worse, at one that gets created empty by something else.
    $documents = [Environment]::GetFolderPath('MyDocuments')
    if ([string]::IsNullOrWhiteSpace($documents)) {
        $documents = Join-Path $env:USERPROFILE 'Documents'
    }
    $githubPath = Join-Path $documents 'GitHub'
}

Write-Host '=== Shell Deploy ==='

# ── Ensure the profile exists ─────────────────────────────────────────────────
$profileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (-not (Test-Path $PROFILE)) {
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "Created a new profile at $PROFILE"
}

# ── Back it up ────────────────────────────────────────────────────────────────
$backup = "$PROFILE.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
Copy-Item $PROFILE $backup -Force
Write-Host "Backed up profile to: $backup"

# ── Skip if already deployed ──────────────────────────────────────────────────
if ((Get-Content $PROFILE -Raw) -match [regex]::Escape($MarkerStart)) {
    Write-Host 'dotfiles shell config already deployed - skipping.'
    Write-Host 'Run 2_wipe.ps1 first to redeploy from scratch.'
    Write-Host ''
    Write-Host '=== Shell deploy complete (no change). ==='
    exit 0
}

Write-Host ''
Write-Host '[1/1] Appending the dotfiles block to the profile...'

$miniforge = Join-Path $env:LOCALAPPDATA 'miniforge3'

$block = @"
$MarkerStart
# Managed by dotfiles/user/3_shell/3_deploy.ps1 - do not edit manually
# Run user\3_shell\2_wipe.ps1 to remove, 3_deploy.ps1 to redeploy

# -- Conda on PATH --------------------------------------------------------------
# The user-scope Miniforge. Installed with /AddToPath=0 deliberately, so PATH is owned here and
# removing this block genuinely removes it.
`$env:PATH = '$miniforge;$miniforge\Scripts;$miniforge\Library\bin;' + `$env:PATH

# -- Navigation -----------------------------------------------------------------
function .. { Set-Location .. }              # go up one directory
function ... { Set-Location ..\.. }          # go up two directories
function gh { Set-Location '$githubPath' }   # jump to the GitHub root

# -- File listing ---------------------------------------------------------------
function ll { Get-ChildItem -Force @args }   # detailed listing including hidden entries

# -- Embedding thread cap -------------------------------------------------------
# ONNX defaults to one thread per core, which took WSL down mid-index on a 32-core machine.
# NOTE, as on the bash side: this export is NOT the binding cap. The grid runs citizens through
# non-interactive shells that never load this profile, so the real limit is the default in
# TDBI's lib/retrieval.py. This only covers interactive terminals.
`$env:TDBI_EMBED_THREADS = '4'
`$env:OMP_NUM_THREADS = '4'
$MarkerEnd
"@

Add-Content -Path $PROFILE -Value $block -Encoding utf8

Write-Host '      Block appended.'
Write-Host ''
Write-Host '=== Shell deploy complete. ==='
Write-Host '    Open a new PowerShell window, or run: . $PROFILE'
