#!/usr/bin/env bash
# 0_personalize.sh - Apply personal configuration from config.env
#
# Usage:
#   1. cp config.env.example config.env
#   2. nano config.env        <- fill in your values
#   3. ./0_personalize.sh     <- validates and applies
#
# Run this BEFORE bootstrap.sh on a fresh machine.
# Safe to run multiple times - will reapply config.env values.
#
# What it does:
#   - Validates all values in config.env
#   - Configures git identity
#   - Creates your first VS Code project folder

set -e  # exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to repo root
CONFIG_FILE="$REPO_DIR/config.env"                           # personal config file path

echo '================================================'
echo '  dotfiles personalization'
echo '  Run this before bootstrap.sh'
echo '================================================'
echo ''

# ── Check config.env exists ───────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then    # check if config.env has been created
    echo 'ERROR: config.env not found.'
    echo ''
    echo 'Create it from the example file:'
    echo '  cp config.env.example config.env'
    echo '  nano config.env'
    exit 1
fi

# Load config
source "$CONFIG_FILE"    # load DOTFILES_* variables

echo 'Loaded config.env. Validating...'
echo ''

# ── Validate all fields ───────────────────────────────────────────────────────
ERRORS=0    # counter for validation errors

# Helper function
error() {
    echo "  ERROR: $1"
    ERRORS=$((ERRORS + 1))
}

# Check all required fields are present and non-empty
[[ -z "$DOTFILES_USER_NAME" ]]         && error 'DOTFILES_USER_NAME is empty'
[[ -z "$DOTFILES_USER_EMAIL" ]]        && error 'DOTFILES_USER_EMAIL is empty'
[[ -z "$DOTFILES_GITHUB_USERNAME" ]]   && error 'DOTFILES_GITHUB_USERNAME is empty'
[[ -z "$DOTFILES_WINDOWS_USERNAME" ]]  && error 'DOTFILES_WINDOWS_USERNAME is empty'
# DOTFILES_FIRST_PROJECT is deliberately NOT required (O-1248). It scaffolds a VS Code workspace
# under the COMMITTED 2_vscode/projects/ tree, and a machine whose work is cloned repos rather than
# scratch projects has no use for one. Empty or 'none' skips it.

# Validate email format - must contain @
if [[ -n "$DOTFILES_USER_EMAIL" ]] && [[ "$DOTFILES_USER_EMAIL" != *@* ]]; then
    error "DOTFILES_USER_EMAIL does not look like an email: $DOTFILES_USER_EMAIL"
fi

# Validate GitHub username - no spaces allowed
if [[ -n "$DOTFILES_GITHUB_USERNAME" ]] && [[ "$DOTFILES_GITHUB_USERNAME" == *' '* ]]; then
    error "DOTFILES_GITHUB_USERNAME must not contain spaces: $DOTFILES_GITHUB_USERNAME"
fi

# Validate Windows username exists on this machine
if [[ -n "$DOTFILES_WINDOWS_USERNAME" ]]; then
    if [[ ! -d "/mnt/c/Users/$DOTFILES_WINDOWS_USERNAME" ]]; then    # check Windows user folder exists
        error "DOTFILES_WINDOWS_USERNAME not found at /mnt/c/Users/$DOTFILES_WINDOWS_USERNAME"
        echo '         Run: ls /mnt/c/Users/ to see available Windows usernames'
    fi
fi

# Validate project name format - must match p###-name pattern, unless skipped
if [[ -n "$DOTFILES_FIRST_PROJECT" && "$DOTFILES_FIRST_PROJECT" != 'none' ]]; then
    if ! echo "$DOTFILES_FIRST_PROJECT" | grep -qE '^p[0-9]{3}-.+'; then    # check p###-name format
        error "DOTFILES_FIRST_PROJECT must match format p###-name (e.g. p008-my-project), or none: $DOTFILES_FIRST_PROJECT"
    fi
fi

# Validate the AI extension choice. Only a KNOWN id or 'none' passes: a typo here installs
# nothing at all and says nothing about it, which is exactly the silent failure this rejects.
if [[ -n "$DOTFILES_AI_EXTENSION" ]]; then
    case "$DOTFILES_AI_EXTENSION" in
        GitHub.copilot|anthropic.claude-code|Continue.continue|none) ;;
        *) error "DOTFILES_AI_EXTENSION must be one of GitHub.copilot, anthropic.claude-code, Continue.continue, none: $DOTFILES_AI_EXTENSION" ;;
    esac
fi

# Validate the backup-remote flag. It decides whether TDBI's evidence gate blocks or warns, so a
# typo silently becoming 'false' would quietly disarm a gate that protects client originals.
if [[ -n "$DOTFILES_BACKUP_REMOTE" ]]; then
    case "$DOTFILES_BACKUP_REMOTE" in
        true|false) ;;
        *) error "DOTFILES_BACKUP_REMOTE must be true or false: $DOTFILES_BACKUP_REMOTE" ;;
    esac
fi

# Stop if any validation errors
if [[ "$ERRORS" -gt 0 ]]; then
    echo ''
    echo "$ERRORS error(s) found in config.env. Fix them and run again."
    exit 1
fi

echo 'All values validated OK.'
echo ''

# ── Configure git identity ────────────────────────────────────────────────────
echo 'Configuring git identity...'

git config --global user.name "$DOTFILES_USER_NAME"      # set git display name
git config --global user.email "$DOTFILES_USER_EMAIL"    # set git email
git config --global init.defaultBranch main              # set default branch name

echo "  Name:  $DOTFILES_USER_NAME"
echo "  Email: $DOTFILES_USER_EMAIL"

# ── Create first project VS Code folder ───────────────────────────────────────
echo ''

PROJECT_DIR="$REPO_DIR/2_vscode/projects/$DOTFILES_FIRST_PROJECT"

if [[ -z "$DOTFILES_FIRST_PROJECT" || "$DOTFILES_FIRST_PROJECT" == 'none' ]]; then
    echo 'No first project requested - skipping VS Code project scaffold.'
elif [[ -d "$PROJECT_DIR" ]]; then    # check if already exists
    echo "  Already exists: $PROJECT_DIR — skipping."
else
    echo "Creating VS Code project folder: $DOTFILES_FIRST_PROJECT"
    mkdir -p "$PROJECT_DIR"    # create project folder

    cat > "$PROJECT_DIR/settings.json" << SETTINGSEOF
{
    "editor.tabSize": 4,
    "editor.rulers": [100],
    "files.exclude": {
        "**/__pycache__": true,
        "**/*.pyc": true,
        "**/.venv": true
    },
    "python.defaultInterpreterPath": "\${workspaceFolder}/.venv/bin/python"
}
SETTINGSEOF

    cat > "$PROJECT_DIR/extensions.txt" << EXTEOF
# $DOTFILES_FIRST_PROJECT - project-specific VS Code extensions
# Add extension IDs here (one per line) to install when deploying this project
# See 2_vscode/global/extensions.md for format and documentation links
ms-python.python
ms-python.vscode-pylance
ms-toolsai.jupyter
njpwerner.autodocstring
EXTEOF

    echo "  Created: $PROJECT_DIR"
fi

# ── Write the machine attributes into TDBI ────────────────────────────────────
# This machine's capabilities, recorded where the grid reads them. TDBI decides block-or-warn at
# its evidence gate from `backup_remote`, and it used to decide that by matching the machine's
# NAME against a hardcoded pair -- which had no answer for a machine it had never met.
#
# Written only if a TDBI checkout is actually there. dotfiles is usually deployed BEFORE the repos
# are cloned, so a missing TDBI is the normal case on a fresh machine, not an error: print the
# file and where it goes, and carry on.
echo ''
echo 'Recording machine attributes for TDBI...'

MACHINE_NAME="$(hostname | tr '[:lower:]' '[:upper:]')"    # the name TDBI derives the same way
TDBI_ROOT="$(cd "$REPO_DIR/.." && pwd)/TDBI"               # sibling checkout, the standard layout

MACHINE_JSON=$(cat << MACHINEEOF
{
  "platform": "wsl",
  "backup_remote": ${DOTFILES_BACKUP_REMOTE:-false},
  "ai_extension": "${DOTFILES_AI_EXTENSION:-none}",
  "python": ""
}
MACHINEEOF
)

if [[ -d "$TDBI_ROOT/config" ]]; then
    echo "$MACHINE_JSON" > "$TDBI_ROOT/config/machine.local.json"
    echo "  Wrote $TDBI_ROOT/config/machine.local.json"
    echo "  Machine: $MACHINE_NAME"
else
    echo "  No TDBI checkout at $TDBI_ROOT - nothing written."
    echo '  After you clone TDBI, save this as TDBI/config/machine.local.json:'
    echo ''
    echo "$MACHINE_JSON" | sed 's/^/    /'
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ''
echo '================================================'
echo '  Personalization complete.'
echo ''
echo "  Name:    $DOTFILES_USER_NAME"
echo "  Email:   $DOTFILES_USER_EMAIL"
echo "  GitHub:  $DOTFILES_GITHUB_USERNAME"
echo "  Windows: $DOTFILES_WINDOWS_USERNAME"
echo "  Project: $DOTFILES_FIRST_PROJECT"
echo ''
echo '  Next step: ./bootstrap.sh'
echo '================================================'
