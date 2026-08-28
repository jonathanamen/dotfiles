# 4_test.ps1 - Validate the personal overlay. Non-destructive.
#
# Usage:
#   .\4_test.ps1
#
# What it checks:
#   - Every key in settings-overlay.json is present in the deployed settings.json with the
#     right value (and nothing else in that file was disturbed -- this only checks presence,
#     never asserts the file equals the overlay)
#   - pac is on PATH
#   - The TDBI-path block is present in the PowerShell profile

$ErrorActionPreference = 'Continue'    # report every failure, do not stop at the first

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserDir = Join-Path $env:APPDATA 'Code\User'
$SettingsFile = Join-Path $UserDir 'settings.json'
$OverlayFile = Join-Path $RepoDir 'settings-overlay.json'
$MarkerTdbiStart = '# >>> dotfiles TDBI path >>>'

$failures = @()

Write-Host '=== Personal Overlay Test ==='
Write-Host ''

# ── 1. Settings keys present ──────────────────────────────────────────────────
Write-Host '[1/3] Checking personal settings keys...'
if (-not (Test-Path $SettingsFile)) {
    Write-Host "      FAIL: no settings.json at $SettingsFile"
    $failures += 'settings.json missing'
} else {
    $settings = Get-Content $SettingsFile -Raw | ConvertFrom-Json
    $overlay = Get-Content $OverlayFile -Raw | ConvertFrom-Json
    foreach ($prop in $overlay.PSObject.Properties) {
        $current = $settings.PSObject.Properties[$prop.Name]
        if ($current -and ($current.Value -eq $prop.Value)) {
            Write-Host "      OK   $($prop.Name)"
        } else {
            Write-Host "      FAIL $($prop.Name) missing or does not match"
            $failures += "$($prop.Name) not set"
        }
    }
}

# ── 2. pac on PATH ─────────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/3] Checking pac on PATH...'
if (Get-Command pac -ErrorAction SilentlyContinue) {
    Write-Host "      OK   pac $(pac --version 2>$null)"
} else {
    Write-Host '      FAIL pac not found on PATH.'
    $failures += 'pac missing'
}

# ── 3. TDBI-path block ─────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[3/3] Checking the TDBI-path block in the PowerShell profile...'
if ((Test-Path $PROFILE) -and ((Get-Content $PROFILE -Raw) -match [regex]::Escape($MarkerTdbiStart))) {
    Write-Host '      OK   TDBI-path block present'
} else {
    Write-Host '      FAIL TDBI-path block not found - run 3_deploy.ps1'
    $failures += 'TDBI-path block missing'
}

# ── Report ────────────────────────────────────────────────────────────────────
Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host "=== Personal overlay test FAILED: $($failures.Count) problem(s) ==="
    foreach ($f in $failures) { Write-Host "    - $f" }
    exit 1
}
Write-Host '=== Personal overlay test passed. ==='
exit 0
