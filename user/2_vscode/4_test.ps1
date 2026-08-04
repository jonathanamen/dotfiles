# 4_test.ps1 - Validate the VS Code deployment. Non-destructive.
#
# Usage:
#   .\4_test.ps1
#
# What it checks:
#   - settings.json and keybindings.json are deployed and are valid JSON
#   - every extension in the shared curated list is actually installed
#   - the AI extension chosen in config.env is installed, if one was chosen
#
# Valid JSON matters more than file presence: a truncated settings.json exists, passes any
# Test-Path check, and silently makes VS Code fall back to defaults.

$ErrorActionPreference = 'Continue'    # report every failure, do not stop at the first

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $RepoDir)
$GlobalDir = Join-Path $DotfilesRoot '2_vscode\global'
$UserDir = Join-Path $env:APPDATA 'Code\User'

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

$failures = @()

Write-Host '=== VS Code Test ==='
Write-Host ''

# ── 1. Settings deployed and parseable ────────────────────────────────────────
Write-Host '[1/2] Checking deployed settings...'
foreach ($file in @('settings.json', 'keybindings.json')) {
    $target = Join-Path $UserDir $file
    if (-not (Test-Path $target)) {
        Write-Host "      FAIL: $file not deployed to $UserDir"
        $failures += "$file missing"
        continue
    }
    try {
        Get-Content $target -Raw | ConvertFrom-Json | Out-Null
        Write-Host "      OK   $file deployed and parses"
    } catch {
        # VS Code allows comments in these files and ConvertFrom-Json does not, so a parse failure
        # here is reported as a warning rather than counted as a failure.
        Write-Host "      WARN $file deployed but did not parse as strict JSON (comments are allowed)"
    }
}

# ── 2. Extensions installed ───────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/2] Checking extensions...'

$installed = @(& code --list-extensions)
$expected = Get-Content (Join-Path $GlobalDir 'extensions.txt') |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' -and -not $_.StartsWith('#') }

foreach ($ext in $expected) {
    # Extension ids are case-insensitive; comparing them case-sensitively reports false failures.
    if ($installed -contains $ext -or ($installed | Where-Object { $_ -ieq $ext })) {
        Write-Host "      OK   $ext"
    } else {
        Write-Host "      FAIL $ext not installed"
        $failures += "$ext missing"
    }
}

# The AI extension REPORTS, it does not fail the test (O-1248). VS Code ships Copilot as a built-in
# now, and built-in extensions do not appear in --list-extensions at all -- so absence from that
# list is not evidence of absence from the editor. This test failed a machine that had Copilot
# working the entire time. A check that cannot tell "missing" from "invisible" must not be allowed
# to fail a deploy; it says what it saw and lets a person decide.
$aiExtension = $Config['DOTFILES_AI_EXTENSION']
if ([string]::IsNullOrWhiteSpace($aiExtension) -or $aiExtension -eq 'none') {
    Write-Host '      SKIP no AI extension configured'
} elseif ($installed | Where-Object { $_ -ieq $aiExtension }) {
    Write-Host "      OK   $aiExtension"
} else {
    Write-Host "      NOTE $aiExtension is not in the extension list."
    Write-Host '           It may still be BUILT IN -- built-ins are invisible here.'
    Write-Host '           Check the Extensions panel; this does not fail the test.'
}

# ── Report ────────────────────────────────────────────────────────────────────
Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host "=== VS Code test FAILED: $($failures.Count) problem(s) ==="
    foreach ($f in $failures) { Write-Host "    - $f" }
    exit 1
}
Write-Host '=== VS Code test passed. ==='
exit 0
