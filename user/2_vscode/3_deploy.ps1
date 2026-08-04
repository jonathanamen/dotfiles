# 3_deploy.ps1 - Deploy VS Code settings, keybindings and extensions
#
# Usage:
#   .\3_deploy.ps1                       # global config only
#   .\3_deploy.ps1 p008-arcane-predictive  # global + project config
#
# What it does:
#   - Copies the SHARED global settings and keybindings into %APPDATA%\Code\User
#   - Installs the shared curated extension list
#   - Installs the AI extension this machine chose in config.env, if any
#
# Settings and the extension list are read from ..\..\2_vscode\global\, the same files the WSL
# module deploys. There is no Windows copy of them: a second copy is a second thing to keep true.

$ErrorActionPreference = 'Stop'    # exit immediately if any command fails

# ── Calling `code` without letting a warning kill the deploy (O-1248) ─────────
# `code.cmd` is a node wrapper, and node writes deprecation warnings to STDERR. In PowerShell 5.1
# any stderr line from a NATIVE command is wrapped in a NativeCommandError, which under
# ErrorActionPreference 'Stop' is terminating -- so a DeprecationWarning about `url.parse()` aborted
# the whole bootstrap on the FIRST extension, after installing it successfully with exit code 0.
#
# Found on first contact with a real machine (JAMENLAPTOP), which is the entire reason T7 exists.
#
# The exit CODE is the truth about whether a native command worked; its stderr is not. So: drop the
# preference for the duration of the call, let the warning print where it can be read, and judge the
# result on $LASTEXITCODE.
function Invoke-Code {
    param([Parameter(Mandatory)][string[]]$Arguments, [string]$What)

    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        & code @Arguments
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previous
    }

    if ($code -ne 0) {
        # A failed extension install must not abort the rest of the deploy. It is reported and the
        # loop continues -- one unavailable extension is not a reason to leave the machine half
        # configured, and 4_test.ps1 is what decides whether the result is acceptable.
        Write-Host "      WARNING: $What failed (exit $code)"
        return $false
    }
    return $true
}

$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path            # user\2_vscode
$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $RepoDir)      # repo root
$GlobalDir = Join-Path $DotfilesRoot '2_vscode\global'                # SHARED with the WSL module
$ProjectsDir = Join-Path $DotfilesRoot '2_vscode\projects'            # SHARED project configs
$UserDir = Join-Path $env:APPDATA 'Code\User'                         # where the Windows UI reads
$Project = $args[0]

# ── Load config.env for the AI extension choice ───────────────────────────────
# config.env is bash `KEY="value"` syntax, shared with the WSL tree. Parsed rather than sourced,
# because PowerShell cannot source a bash file and duplicating the file would defeat the point.
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

Write-Host '=== VS Code Deploy ==='

# ── 1. Global settings ────────────────────────────────────────────────────────
Write-Host ''
Write-Host '[1/4] Copying global VS Code settings...'

if (-not (Test-Path $UserDir)) {
    New-Item -ItemType Directory -Path $UserDir -Force | Out-Null
}
Copy-Item (Join-Path $GlobalDir 'settings.json')    (Join-Path $UserDir 'settings.json')    -Force
Copy-Item (Join-Path $GlobalDir 'keybindings.json') (Join-Path $UserDir 'keybindings.json') -Force
Write-Host "      settings.json and keybindings.json copied to $UserDir."

# ── 2. Global extensions ──────────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/4] Installing global extensions...'

$failedExtensions = @()
Get-Content (Join-Path $GlobalDir 'extensions.txt') |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' -and -not $_.StartsWith('#') } |
    ForEach-Object {
        Write-Host "      Installing $_"
        if (-not (Invoke-Code @('--install-extension', $_, '--force') "install $_")) {
            $script:failedExtensions += $_
        }
    }
if ($failedExtensions.Count -gt 0) {
    Write-Host "      Global extensions done, $($failedExtensions.Count) failed: $($failedExtensions -join ', ')"
} else {
    Write-Host '      Global extensions done.'
}

# ── 3. The AI extension this machine chose ────────────────────────────────────
# A machine with no admin rights may not be permitted Claude Code at all, so which assistant gets
# installed is a per-machine decision, recorded in config.env by 0_personalize. 'none' is a valid
# and complete answer, not a missing value.
Write-Host ''
Write-Host '[3/4] Installing the AI extension for this machine...'

$aiExtension = $Config['DOTFILES_AI_EXTENSION']
if ([string]::IsNullOrWhiteSpace($aiExtension) -or $aiExtension -eq 'none') {
    Write-Host '      None chosen - skipping.'
} else {
    # Already listed? Then there is nothing to do, and forcing a reinstall only risks disturbing a
    # working one.
    $installed = @(& code --list-extensions)
    if ($installed | Where-Object { $_ -ieq $aiExtension }) {
        Write-Host "      $aiExtension already installed - skipping."
    } elseif (-not (Invoke-Code @('--install-extension', $aiExtension, '--force') "install $aiExtension")) {
        # A failure here is NOT necessarily a missing extension (O-1248). VS Code now SHIPS
        # Copilot: installing GitHub.copilot pulls GitHub.copilot-chat, and the bundled built-in is
        # newer than the marketplace version that dependency resolves to, so the CLI refuses to
        # downgrade and exits 1. Found on a real machine, where the extension was present the whole
        # time. Built-ins never appear in --list-extensions, so neither the install nor the listing
        # can prove the thing is absent.
        Write-Host ''
        Write-Host "      $aiExtension did not install. On a current VS Code this usually means it"
        Write-Host '      is BUILT IN and therefore already available -- built-in extensions are'
        Write-Host '      invisible to --list-extensions, so this cannot be confirmed from the CLI.'
        Write-Host '      Check the Extensions panel. If it is there, set DOTFILES_AI_EXTENSION=none'
        Write-Host '      so this step stops trying to install what VS Code already gives you.'
    }
}

# ── 4. Project config (optional) ──────────────────────────────────────────────
Write-Host ''
if ([string]::IsNullOrWhiteSpace($Project)) {
    Write-Host '[4/4] No project specified - skipping project config.'
    if (Test-Path $ProjectsDir) {
        Write-Host '      Available projects:'
        Get-ChildItem $ProjectsDir -Directory | ForEach-Object { Write-Host "        - $($_.Name)" }
    }
} else {
    $projectDir = Join-Path $ProjectsDir $Project
    if (-not (Test-Path $projectDir)) {
        Write-Host "[4/4] ERROR: project not found: $projectDir"
        exit 1
    }
    Write-Host "[4/4] Applying project config: $Project"
    $projectExtensions = Join-Path $projectDir 'extensions.txt'
    if (Test-Path $projectExtensions) {
        Get-Content $projectExtensions |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -ne '' -and -not $_.StartsWith('#') } |
            ForEach-Object {
                Write-Host "      Installing $_"
                Invoke-Code @('--install-extension', $_, '--force') "install $_" | Out-Null
            }
    }
    Write-Host '      Project extensions done.'
    Write-Host "      Project settings.json stays in the repo - open $projectDir as a workspace."
}

Write-Host ''
Write-Host '=== VS Code deploy complete. ==='
