#!/usr/bin/env bash
# 3_deploy.sh - Deploy shell config to ~/.bashrc
#
# Usage:
#   ./3_deploy.sh
#
# What it does:
#   - Appends the dotfiles shell config block to ~/.bashrc
#   - Wraps config in markers so 2_wipe.sh can cleanly remove it later
#   - Skips deploy if block is already present (idempotent)
#   - Creates a backup of ~/.bashrc before making any changes

set -e  # exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to this script's directory
MARKER_START='# >>> dotfiles shell config >>>'               # start marker for managed block

echo '=== Shell Deploy ==='

# Back up ~/.bashrc before modifying
BACKUP="$HOME/.bashrc.bak.$(date +%Y%m%d%H%M%S)"    # timestamped backup filename
cp "$HOME/.bashrc" "$BACKUP"                           # copy current .bashrc to backup
echo "Backed up ~/.bashrc to: $BACKUP"

# Check if already deployed
if grep -q "$MARKER_START" "$HOME/.bashrc"; then    # check if block already exists
    echo 'dotfiles shell config already deployed - skipping.'
    echo 'Run 2_wipe.sh first to redeploy from scratch.'
    exit 0
fi

echo ''
echo '[1/1] Deploying shell config to ~/.bashrc...'

# Append managed block to ~/.bashrc
cat >> "$HOME/.bashrc" << 'SHELLCONFIG'

# >>> dotfiles shell config >>>
# Managed by dotfiles/3_shell/3_deploy.sh - do not edit manually
# Run 3_shell/2_wipe.sh to remove, 3_shell/3_deploy.sh to redeploy

# ── Navigation ────────────────────────────────────────────────────────────────
alias ..='cd ..'          # go up one directory
alias ...='cd ../..'      # go up two directories

# ── File listing ──────────────────────────────────────────────────────────────
alias ll='ls -la'         # detailed listing with permissions, sizes, and dates

# ── Git shortcuts ─────────────────────────────────────────────────────────────
alias gs='git status'           # show working tree status
alias ga='git add -A'           # stage all changes
alias gc='git commit -m'        # commit with message - usage: gc "message"
alias gp='git push'             # push to remote
alias gd='git diff'             # show unstaged changes
alias gl='git log --oneline -10' # show last 10 commits in compact format

# ── Environment ───────────────────────────────────────────────────────────────
export EDITOR=nano              # default text editor
export HISTSIZE=10000           # number of commands to keep in session history
export HISTFILESIZE=20000       # number of commands to keep in history file
export HISTCONTROL=ignoredups   # do not save duplicate commands in history

# <<< dotfiles shell config <<<
SHELLCONFIG

echo '      Shell config deployed to ~/.bashrc.'

echo ''
echo '=== Deploy complete. ==='
echo 'Run "source ~/.bashrc" or open a new terminal to apply changes.'
