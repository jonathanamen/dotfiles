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
# The TDBI block carries its own markers and its own presence check, exactly as the WSL twin does
# (3_shell/3_deploy.sh:76). A single blob guarded by one marker means a machine that deployed
# before this section existed sees the marker, skips, and never picks the addition up on a rerun
# -- the REC-O-20 recurrence. Two blocks, two checks.
$MarkerTdbiStart = '# >>> dotfiles TDBI path >>>'
$MarkerTdbiEnd = '# <<< dotfiles TDBI path <<<'

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

# ── 1. The main block ─────────────────────────────────────────────────────────
# Skipping this block no longer ends the script: the TDBI path and the shims below have their own
# checks and must still run on a machine whose profile block was deployed by an older version.
Write-Host ''
Write-Host '[1/3] Appending the dotfiles block to the profile...'

$miniforge = Join-Path $env:LOCALAPPDATA 'miniforge3'
$skipMainBlock = $false

if ((Get-Content $PROFILE -Raw) -match [regex]::Escape($MarkerStart)) {
    Write-Host '      dotfiles shell config already deployed - skipping.'
    Write-Host '      Run 2_wipe.ps1 first to redeploy from scratch.'
    $skipMainBlock = $true
}

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

if (-not $skipMainBlock) {
    Add-Content -Path $PROFILE -Value $block -Encoding utf8
    Write-Host '      Block appended.'
}

# ── 2. TDBI\bin on PATH ───────────────────────────────────────────────────────
# This is the line that makes the runbook true on a Windows-native machine (O-1251). Every command
# there is written as a bare word (`herald fetch-step`, `mfs tdbi`), and without this directory on
# PATH not one of them resolves - which is exactly how the company laptop ended up unable to call
# a citizen at all. The WSL twin has had this since REC-O-20; this side never did.
$tdbiRoot = Join-Path $githubPath 'TDBI'
$tdbiBin = Join-Path $tdbiRoot 'bin'

Write-Host ''
Write-Host '[2/3] Deploying TDBI bin PATH...'
if ((Get-Content $PROFILE -Raw) -match [regex]::Escape($MarkerTdbiStart)) {
    Write-Host '      TDBI bin PATH already deployed - skipping.'
} else {
    $tdbiBlock = @"
$MarkerTdbiStart
# Managed by dotfiles/user/3_shell/3_deploy.ps1 - do not edit manually
# Citizen shims: mfs, herald, orchestrator, linter, registrar, librarian, consolidator.
# They are GENERATED into that directory at deploy, never committed (O-1251).
`$env:PATH = '$tdbiBin;' + `$env:PATH
# The GitHub root, exported so it is available interactively - GRID-RUNBOOK writes repo paths
# against it so a copied block runs on any machine without hardcoding one machine's layout.
`$env:DOTFILES_GITHUB_PATH = '$githubPath'
$MarkerTdbiEnd
"@
    Add-Content -Path $PROFILE -Value $tdbiBlock -Encoding utf8
    Write-Host "      TDBI bin PATH deployed: $tdbiBin"
}

# ── 3. The shims themselves ───────────────────────────────────────────────────
# bin/ is OUTPUT, not committed code. The one machine-specific line in a shim is the interpreter,
# and that is knowable only here - which is why the committed shims hardcoded the dotfiles WSL
# standard and had no .cmd twin, so the bare word `herald` resolved to nothing on this platform.
Write-Host ''
Write-Host '[3/3] Generating TDBI citizen shims...'
$generator = Join-Path $tdbiRoot 'tools\generate_shims.py'
$python = Join-Path $miniforge 'python.exe'
if (-not (Test-Path $generator)) {
    Write-Host "      No TDBI checkout at $tdbiRoot - skipping."
    Write-Host '      Clone TDBI beside dotfiles and rerun; without this the citizen commands do not exist.'
} elseif (-not (Test-Path $python)) {
    Write-Host "      Miniforge not found at $python - run user\1_conda\3_deploy.ps1 first. Skipping."
} else {
    & $python $generator
    if ($LASTEXITCODE -ne 0) {
        Write-Host '      FAIL: the shim generator refused. The citizen commands will not resolve.'
        exit 1
    }
}

Write-Host ''
Write-Host '=== Shell deploy complete. ==='
Write-Host '    Open a new PowerShell window, or run: . $PROFILE'
