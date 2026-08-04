# 4_test.ps1 - Validate the conda install. Non-destructive.
#
# Usage:
#   .\4_test.ps1
#
# What it checks:
#   - conda and python exist at the user-scope install path
#   - every package in the shared base-packages.txt actually IMPORTS
#
# It imports rather than reading `conda list`, for the reason already in the root CONTRIBUTING
# decision log: an installed-but-broken package passes a list check and fails at the first search.
# The import is the only test that means anything.

$ErrorActionPreference = 'Continue'    # a test reports every failure, it does not stop at the first

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $RepoDir)
$PackagesFile = Join-Path $DotfilesRoot '1_conda\base-packages.txt'
$MiniforgeDir = Join-Path $env:LOCALAPPDATA 'miniforge3'
$CondaExe = Join-Path $MiniforgeDir 'Scripts\conda.exe'
$PythonExe = Join-Path $MiniforgeDir 'python.exe'

# The import name is not always the package name. Only the exceptions are listed; anything absent
# is assumed to import under its own name.
$ImportNames = @{
    'sqlite-vec' = 'sqlite_vec'
}

$failures = @()

Write-Host '=== Conda Test ==='
Write-Host ''

# ── 1. Binaries exist ─────────────────────────────────────────────────────────
Write-Host '[1/2] Checking conda and python...'
if (Test-Path $CondaExe) {
    Write-Host "      conda found: $(& $CondaExe --version)"
} else {
    Write-Host "      FAIL: conda not found at $CondaExe"
    $failures += 'conda missing'
}
if (Test-Path $PythonExe) {
    Write-Host "      python found: $(& $PythonExe --version)"
} else {
    Write-Host "      FAIL: python not found at $PythonExe"
    $failures += 'python missing'
}

# ── 2. Every base package imports ─────────────────────────────────────────────
Write-Host ''
Write-Host '[2/2] Importing base packages...'

if (-not (Test-Path $PythonExe)) {
    Write-Host '      SKIP: no python to import with.'
} elseif (-not (Test-Path $PackagesFile)) {
    Write-Host "      FAIL: shared package list not found at $PackagesFile"
    $failures += 'package list missing'
} else {
    $packages = Get-Content $PackagesFile |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

    foreach ($package in $packages) {
        # Strip any version pin - "fastembed>=0.8.0" imports as "fastembed".
        $name = ($package -split '[><=!]')[0].Trim()
        $module = if ($ImportNames.ContainsKey($name)) { $ImportNames[$name] } else { $name }

        & $PythonExe -c "import $module" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "      OK   import $module"
        } else {
            Write-Host "      FAIL import $module"
            $failures += "import $module"
        }
    }
}

# ── Report ────────────────────────────────────────────────────────────────────
Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host "=== Conda test FAILED: $($failures.Count) problem(s) ==="
    foreach ($f in $failures) { Write-Host "    - $f" }
    exit 1
}
Write-Host '=== Conda test passed. ==='
exit 0
