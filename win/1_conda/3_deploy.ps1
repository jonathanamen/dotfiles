# 3_deploy.ps1 - Install Miniforge into the user profile and install base packages
#
# Usage:
#   .\3_deploy.ps1
#
# What it does:
#   - Downloads the Miniforge Windows installer
#   - Installs it in "Just Me" mode into %LOCALAPPDATA%\miniforge3 (no elevation)
#   - Installs the shared base package list from ..\..\1_conda\base-packages.txt
#
# The package list is NOT duplicated here. It is the same file the WSL module installs from, so a
# package added for the grid reaches both platforms. Only the installer differs.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path            # win\1_conda
$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $RepoDir)      # repo root
$PackagesFile = Join-Path $DotfilesRoot '1_conda\base-packages.txt'   # SHARED with the WSL module
$MiniforgeDir = Join-Path $env:LOCALAPPDATA 'miniforge3'
$CondaExe = Join-Path $MiniforgeDir 'Scripts\conda.exe'

Write-Host '=== Conda Deploy ==='

# ── Refuse to run elevated ────────────────────────────────────────────────────
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'ERROR: Do not run this as Administrator.'
    exit 1
}

# ── 1. Install Miniforge ──────────────────────────────────────────────────────
Write-Host ''
Write-Host '[1/3] Installing Miniforge...'

if (Test-Path $CondaExe) {
    Write-Host "      Already installed at $MiniforgeDir - skipping download."
} else {
    $installer = Join-Path $env:TEMP 'Miniforge3-Windows-x86_64.exe'
    $url = 'https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Windows-x86_64.exe'

    Write-Host '      Downloading installer...'
    # Progress rendering makes Invoke-WebRequest an order of magnitude slower on large files.
    $previousProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
    } finally {
        $ProgressPreference = $previousProgress
    }

    # /InstallationType=JustMe and /RegisterPython=0 are what keep this out of Program Files and
    # out of the machine-wide registry - the two things that would demand elevation.
    Write-Host "      Installing to $MiniforgeDir (this takes a minute)..."
    $arguments = @(
        '/S',                              # silent
        '/InstallationType=JustMe',        # user profile, never Program Files
        '/RegisterPython=0',               # do not claim the machine-wide python registration
        '/AddToPath=0',                    # PATH is 3_shell's job, via the PowerShell profile
        "/D=$MiniforgeDir"                 # must be LAST and unquoted - NSIS requires it
    )
    Start-Process -FilePath $installer -ArgumentList $arguments -Wait -NoNewWindow

    Remove-Item $installer -Force -ErrorAction SilentlyContinue
    Write-Host '      Miniforge installed.'
}

if (-not (Test-Path $CondaExe)) {
    Write-Host "      ERROR: conda.exe not found at $CondaExe after install."
    exit 1
}

# ── 2. Base packages ──────────────────────────────────────────────────────────
# These are the grid's RETRIEVAL dependencies (fastembed, sqlite-vec) plus the harness's flask.
# The citizens themselves are stdlib-only, so a failure here costs search, never the session.
Write-Host ''
Write-Host '[2/3] Installing base packages...'

if (-not (Test-Path $PackagesFile)) {
    Write-Host "      ERROR: shared package list not found at $PackagesFile"
    exit 1
}

$packages = Get-Content $PackagesFile |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

if ($packages.Count -eq 0) {
    Write-Host '      No packages listed - skipping.'
} else {
    foreach ($package in $packages) {
        Write-Host "      Installing $package"
    }
    # One call, not one per package: conda resolves the whole set together and a per-package loop
    # can pick mutually incompatible versions that each looked fine on their own.
    & $CondaExe install -y -n base -c conda-forge @packages
}

# ── 3. Report ─────────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[3/3] Verifying...'
& $CondaExe --version
& (Join-Path $MiniforgeDir 'python.exe') --version

Write-Host ''
Write-Host '=== Conda deploy complete. ==='
Write-Host "    Python: $(Join-Path $MiniforgeDir 'python.exe')"
Write-Host '    Run 3_shell\3_deploy.ps1 to put it on your PATH.'
