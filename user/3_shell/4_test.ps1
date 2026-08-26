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
Write-Host '[1/4] Checking the PowerShell profile...'

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
Write-Host '[2/4] Checking that a new shell gets conda on PATH...'

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
Write-Host '[3/4] Checking the TDBI citizen shims...'

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

# ── 4. The Git Bash profile ───────────────────────────────────────────────────
# Same principle as check 2: reading the file proves nothing. A .bashrc written with CRLF is
# present, complete, and correct on inspection, and bash still refuses every line in it with
# `$'\r': command not found`. Only launching a login shell shows that.
Write-Host ''
Write-Host '[4/4] Checking the Git Bash profile...'

$bashHome = $env:USERPROFILE
$bashrc = Join-Path $bashHome '.bashrc'
$bashProfile = Join-Path $bashHome '.bash_profile'

$gitBash = @(
    (Join-Path $env:ProgramFiles 'Git\bin\bash.exe'),
    (Join-Path ${env:ProgramFiles(x86)} 'Git\bin\bash.exe'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Git\bin\bash.exe')
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1

if (-not (Test-Path $bashrc)) {
    Write-Host '      FAIL: no .bashrc - run 3_deploy.ps1'
    $failures += 'bashrc missing'
} elseif ((Get-Content $bashrc -Raw) -notmatch [regex]::Escape($MarkerStart)) {
    Write-Host '      FAIL: dotfiles block not in .bashrc - run 3_deploy.ps1'
    $failures += 'bash block missing'
} elseif ((Get-Content $bashProfile -Raw -ErrorAction SilentlyContinue) -notmatch 'bashrc') {
    Write-Host '      FAIL: .bash_profile does not source .bashrc, so nothing above loads'
    $failures += 'bash_profile not sourcing'
} else {
    # CRLF is the failure this catches, and it is invisible to every other check here.
    if ([System.IO.File]::ReadAllBytes($bashrc) -contains 13) {
        Write-Host '      FAIL .bashrc contains CR bytes - bash will reject every line it manages'
        $failures += 'bashrc has CRLF'
    } else {
        Write-Host '      OK   .bashrc is LF-only and .bash_profile sources it'
    }

    if (-not $gitBash) {
        Write-Host '      SKIP: Git Bash not found, so the loaded state cannot be checked.'
        Write-Host '            Install Git for Windows and rerun.'
    } else {
        # -lc, not -c: a login shell is what Git Bash opens and what reads .bash_profile.
        $whichPython = & $gitBash -lc 'command -v python 2>/dev/null' 2>$null
        if ($whichPython -and $whichPython -match 'miniforge3') {
            Write-Host "      OK   python resolves to $whichPython in a login shell"
        } elseif ($whichPython) {
            Write-Host "      FAIL python resolves to $whichPython, not the dotfiles Miniforge"
            $failures += 'wrong python in Git Bash'
        } else {
            Write-Host '      FAIL python is not on PATH in a Git Bash login shell'
            $failures += 'python not on PATH in Git Bash'
        }
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
