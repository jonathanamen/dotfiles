# 2_wipe.ps1 - Remove the dotfiles blocks from the PowerShell profile and Git Bash
#
# Usage:
#   .\2_wipe.ps1
#
# What it does:
#   - Backs the profile up
#   - Removes everything between the dotfiles markers, inclusive
#   - Keeps only the most recent backup
#
# Anything you added to the profile OUTSIDE the markers survives. That is the whole point of the
# markers: this module owns its block and nothing else in the file.
#
# -Force is accepted and ignored here: this wipe never prompts. Every 2_wipe.ps1 takes the same
# switch so bootstrap.ps1 can call all of them identically.

param([switch]$Force)

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

$MarkerStart = '# >>> dotfiles shell config >>>'
$MarkerEnd = '# <<< dotfiles shell config <<<'
# The TDBI PATH block is a second managed block with its own markers (O-1251), matching
# 3_shell/2_wipe.sh:56. A wipe that removed only the first would leave a dead PATH entry behind
# and the next deploy would see its marker and skip - so the wipe has to know about both.
$MarkerTdbiStart = '# >>> dotfiles TDBI path >>>'
$MarkerTdbiEnd = '# <<< dotfiles TDBI path <<<'

Write-Host '=== Shell Wipe ==='
Write-Host ''
Write-Host '[1/3] Removing the dotfiles blocks from the PowerShell profile...'

# No early exit here. A machine that only ever ran Git Bash has no PowerShell profile at all, and
# returning at this point would skip the bash removal below and report a successful wipe having
# done nothing -- which is precisely the team-fork machine (REC-E-0025).
$lines = if (Test-Path $PROFILE) { @(Get-Content $PROFILE) } else { @() }

if (-not (Test-Path $PROFILE)) {
    Write-Host '      No PowerShell profile exists - nothing to remove.'
} elseif (-not (($lines -contains $MarkerStart) -or ($lines -contains $MarkerTdbiStart))) {
    Write-Host '      Blocks not present - nothing to remove.'
} else {
    $backup = "$PROFILE.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $PROFILE $backup -Force
    Write-Host "      Backed up profile to: $backup"

    # Walk the file once and keep everything outside the marker pair. A regex over the whole file
    # would also work, but this stays correct if the block is ever present more than once.
    $kept = New-Object System.Collections.Generic.List[string]
    $inBlock = $false
    foreach ($line in $lines) {
        if ($line -eq $MarkerStart -or $line -eq $MarkerTdbiStart) { $inBlock = $true; continue }
        if ($line -eq $MarkerEnd -or $line -eq $MarkerTdbiEnd) { $inBlock = $false; continue }
        if (-not $inBlock) { $kept.Add($line) }
    }

    Set-Content -Path $PROFILE -Value $kept -Encoding utf8
    Write-Host '      Blocks removed.'
}

# ── The Git Bash profile ──────────────────────────────────────────────────────
# 3_deploy.ps1 writes three managed blocks on the bash side: the main block and the TDBI block in
# .bashrc, and the sourcing line in .bash_profile. A wipe that removed only the PowerShell ones
# would leave a live conda PATH and a dead TDBI PATH behind, and the next deploy would see its
# own markers and skip -- the same REC-O-20 recurrence the two-marker split exists to prevent.
$MarkerProfileStart = '# >>> dotfiles bash_profile >>>'
$MarkerProfileEnd = '# <<< dotfiles bash_profile <<<'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Written back with LF and no BOM for the same reason 3_deploy.ps1 writes them that way: bash
# reports `$'\r': command not found` on a CRLF file, and a wipe must not be what introduces that.
function Remove-BashBlocks([string]$Path, [string[]]$Starts, [string[]]$Ends) {
    if (-not (Test-Path $Path)) { return $false }
    $src = @(Get-Content $Path)
    if (-not ($src | Where-Object { $Starts -contains $_ })) { return $false }
    Copy-Item $Path "$Path.bak.$(Get-Date -Format 'yyyyMMddHHmmss')" -Force
    $keep = New-Object System.Collections.Generic.List[string]
    $inBlock = $false
    foreach ($line in $src) {
        if ($Starts -contains $line) { $inBlock = $true; continue }
        if ($Ends -contains $line) { $inBlock = $false; continue }
        if (-not $inBlock) { $keep.Add($line) }
    }
    [System.IO.File]::WriteAllText($Path, (($keep -join "`n").TrimEnd() + "`n"), $Utf8NoBom)
    return $true
}

$bashHome = $env:USERPROFILE
$bashrc = Join-Path $bashHome '.bashrc'
$bashProfile = Join-Path $bashHome '.bash_profile'

Write-Host ''
Write-Host '[2/3] Removing the Git Bash blocks...'

if (Remove-BashBlocks $bashrc @($MarkerStart, $MarkerTdbiStart) @($MarkerEnd, $MarkerTdbiEnd)) {
    Write-Host "      Blocks removed from $bashrc"
} else {
    Write-Host '      No blocks in .bashrc - nothing to remove.'
}

if (Remove-BashBlocks $bashProfile @($MarkerProfileStart) @($MarkerProfileEnd)) {
    Write-Host "      Sourcing line removed from $bashProfile"
} else {
    Write-Host '      No block in .bash_profile - nothing to remove.'
}

# ── Keep only the newest backup ───────────────────────────────────────────────
# Same rule the bash module documents: git holds the full history, so a local backup is only a
# safety net for the current run and older ones are noise.
Write-Host ''
Write-Host '[3/3] Rotating backups...'

# Every managed file rotates, not just the PowerShell profile. Both this script and 3_deploy.ps1
# stamp a .bak on the bash files each run, so leaving them out means they accumulate forever.
$rotated = $false
foreach ($managed in @($PROFILE, $bashrc, $bashProfile)) {
    $dir = Split-Path -Parent $managed
    $name = Split-Path -Leaf $managed
    if (-not (Test-Path $dir)) { continue }
    $backups = @(Get-ChildItem -Path $dir -Filter "$name.bak.*" -Force -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending)
    if ($backups.Count -gt 1) {
        $backups | Select-Object -Skip 1 | ForEach-Object {
            Remove-Item $_.FullName -Force
            Write-Host "      Removed old backup: $($_.Name)"
            $rotated = $true
        }
    }
}
if (-not $rotated) { Write-Host '      Nothing to rotate.' }

Write-Host ''
Write-Host '=== Shell wipe complete. ==='
Write-Host '    Open a new Git Bash or PowerShell window for the change to take effect.'
