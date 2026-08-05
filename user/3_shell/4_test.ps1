# 4_test.ps1 - Validate the shell deployment. Non-destructive.
#
# Usage:
#   .\4_test.ps1
#
# What it checks:
#   - The profile exists and carries the dotfiles block
#   - The block is complete (both markers present, in the right order)
#   - Loading the profile in a fresh shell actually puts conda on PATH
#
# The last check is the one that means anything. A block that is present but broken - a bad path,
# a syntax error - leaves the profile silently half-loaded, and every check that only reads the
# FILE would still pass.

$ErrorActionPreference = 'Continue'    # report every failure, do not stop at the first

$MarkerStart = '# >>> dotfiles shell config >>>'
$MarkerEnd = '# <<< dotfiles shell config <<<'

$failures = @()

Write-Host '=== Shell Test ==='
Write-Host ''

# ── 1. The block is present and complete ──────────────────────────────────────
Write-Host '[1/3] Checking the profile...'

if (-not (Test-Path $PROFILE)) {
    Write-Host "      FAIL: no profile at $PROFILE"
    $failures += 'profile missing'
} else {
    $content = Get-Content $PROFILE -Raw
    $startIndex = $content.IndexOf($MarkerStart)
    $endIndex = $content.IndexOf($MarkerEnd)

    if ($startIndex -lt 0) {
        Write-Host '      FAIL: dotfiles block not found - run 3_deploy.ps1'
        $failures += 'block missing'
    } elseif ($endIndex -lt 0) {
        Write-Host '      FAIL: block has a start marker but no end marker - it is truncated'
        $failures += 'block truncated'
    } elseif ($endIndex -lt $startIndex) {
        Write-Host '      FAIL: block markers are out of order'
        $failures += 'block malformed'
    } else {
        Write-Host '      OK   dotfiles block present and complete'
    }
}

# ── 2. A fresh shell picks up conda ───────────────────────────────────────────
Write-Host ''
Write-Host '[2/3] Checking that a new shell gets conda on PATH...'

$miniforge = Join-Path $env:LOCALAPPDATA 'miniforge3'
if (-not (Test-Path (Join-Path $miniforge 'python.exe'))) {
    Write-Host '      SKIP: Miniforge is not installed, so there is nothing to find on PATH.'
    Write-Host '            Run user\1_conda\3_deploy.ps1 first.'
} else {
    # A child powershell loads the profile the same way a new terminal would, so this measures
    # the deployed state rather than the state of the shell running the test.
    $found = & powershell -NoLogo -Command 'if (Get-Command python -ErrorAction SilentlyContinue) { (Get-Command python).Source }'
    if ($found -and $found -like "$miniforge*") {
        Write-Host "      OK   python resolves to $found"
    } elseif ($found) {
        Write-Host "      FAIL python resolves to $found, not the dotfiles Miniforge"
        $failures += 'wrong python on PATH'
    } else {
        Write-Host '      FAIL python is not on PATH in a new shell'
        $failures += 'python not on PATH'
    }
}

# ── 3. The citizen commands actually resolve ──────────────────────────────────
# This is the check that would have caught the whole problem (O-1251): the laptop had a machine
# file saying `windows`, a python, and a TDBI checkout, and still could not run `herald` - because
# bin/ held bash shims and no .cmd twin, and nothing put it on PATH. Every check that only reads
# the profile passed the entire time.
Write-Host ''
Write-Host '[3/3] Checking the TDBI citizen shims...'

# Read the deployed path out of the profile rather than re-deriving it: the point is to test what
# was DEPLOYED, and a second copy of the derivation would agree with itself while disagreeing with
# the profile that actually runs.
$profileText = if (Test-Path $PROFILE) { Get-Content $PROFILE -Raw } else { '' }
$tdbiRoot = $null
# Anchored on \TDBI\bin, not on \bin: the conda line in the main block ends in \Library\bin; and
# would otherwise match first and hand back a miniforge path.
if ($profileText -match "(?m)^\`$env:PATH = '(.+?\\TDBI)\\bin;'") {
    $tdbiRoot = $Matches[1]
}
$generator = if ($tdbiRoot) { Join-Path $tdbiRoot 'tools\generate_shims.py' } else { $null }
$python = Join-Path $miniforge 'python.exe'

if (-not $tdbiRoot) {
    Write-Host '      FAIL: no TDBI bin PATH block in the profile - run 3_deploy.ps1'
    $failures += 'TDBI PATH block missing'
} elseif (-not (Test-Path $generator)) {
    Write-Host "      SKIP: no TDBI checkout at $tdbiRoot"
} elseif (-not (Test-Path $python)) {
    Write-Host '      SKIP: Miniforge is not installed, so the shims cannot be checked.'
} else {
    & $python $generator --check
    if ($LASTEXITCODE -eq 0) {
        Write-Host '      OK   shims are current for this machine'
    } else {
        Write-Host '      FAIL shims are missing or stale - run 3_deploy.ps1'
        $failures += 'TDBI shims stale'
    }
}

# ── Report ────────────────────────────────────────────────────────────────────
Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host "=== Shell test FAILED: $($failures.Count) problem(s) ==="
    foreach ($f in $failures) { Write-Host "    - $f" }
    exit 1
}
Write-Host '=== Shell test passed. ==='
exit 0
