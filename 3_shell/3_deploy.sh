#!/usr/bin/env bash
# 3_deploy.sh - Deploy shell config to ~/.bashrc and ~/.bash_aliases
#
# Usage:
#   ./3_deploy.sh
#
# What it does:
#   - Appends the dotfiles shell config block to ~/.bashrc
#   - Wraps config in markers so 2_wipe.sh can cleanly remove it later
#   - Skips deploy if block is already present (idempotent)
#   - Creates a backup of ~/.bashrc before making any changes
#   - Symlinks .bash_aliases from dotfiles config into home directory
set -e  # exit immediately if any command fails
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to this script's directory
DOTFILES_ROOT="$(cd "$REPO_DIR/.." && pwd)"                 # repo root, one level up from 3_shell
MARKER_START='# >>> dotfiles shell config >>>'               # start marker for managed block

# Load config.env for DOTFILES_GITHUB_PATH -- the GitHub root differs per machine
# (ANGLACHEL has no OneDrive segment, ENIAC does), so it cannot be baked into a committed file.
if [[ -f "$DOTFILES_ROOT/config.env" ]]; then
    source "$DOTFILES_ROOT/config.env"
fi

echo '=== Shell Deploy ==='
# Back up ~/.bashrc before modifying
BACKUP="$HOME/.bashrc.bak.$(date +%Y%m%d%H%M%S)"    # timestamped backup filename
cp "$HOME/.bashrc" "$BACKUP"                           # copy current .bashrc to backup
echo "Backed up ~/.bashrc to: $BACKUP"
# Check if already deployed
if grep -q "$MARKER_START" "$HOME/.bashrc"; then    # check if block already exists
    echo 'dotfiles shell config already deployed - skipping.'
    echo 'Run 2_wipe.sh first to redeploy from scratch.'
else
    echo ''
    echo '[1/2] Deploying shell config to ~/.bashrc...'
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
# ── Python ────────────────────────────────────────────────────────────────────
conda activate base             # make miniforge python3 the default python3
# ── TDBI ──────────────────────────────────────────────────────────────────────
# ONNX embedding threads (librarian retrieval). Left unset, ONNX spawns one thread per core --
# on a 32-core machine that took WSL down mid-index. An embedding pass is a background
# convenience, not a workload, and must never be able to kill the machine it runs on.
export TDBI_EMBED_THREADS=4     # cap ONNX threads for librarian retrieval
export OMP_NUM_THREADS=4        # same cap for the OpenMP layer underneath it
SHELLCONFIG
    echo '      Shell config deployed to ~/.bashrc.'
fi

# TDBI/bin on PATH -- checked and appended independently of the block above, under its own
# marker. The main block's skip check guards a single blob: a machine that deployed before this
# section existed would see the marker already present and skip forever, never picking up the
# addition on a later rerun (REC-O-20 recurrence). This is the line that makes the runbook true:
# every command there is written as a bare word (`mfs recology`, `herald fetch-step`), and
# without bin/ on PATH not one of them resolves.
MARKER_TDBI_START='# >>> dotfiles TDBI path >>>'
echo ''
echo '[2/3] Deploying TDBI bin PATH...'
if grep -q "$MARKER_TDBI_START" "$HOME/.bashrc"; then
    echo '      TDBI bin PATH already deployed - skipping.'
elif [[ -z "${DOTFILES_GITHUB_PATH:-}" ]]; then
    echo '      DOTFILES_GITHUB_PATH not set -- copy config.env.example to config.env and fill it in, then rerun. Skipping.'
else
    cat >> "$HOME/.bashrc" << SHELLCONFIG_TDBI
$MARKER_TDBI_START
# Managed by dotfiles/3_shell/3_deploy.sh - do not edit manually (REC-O-20)
export PATH="\$PATH:$DOTFILES_GITHUB_PATH/TDBI/bin"   # citizen shims: mfs, herald, orchestrator, linter, registrar, librarian, consolidator
# The GitHub root, exported so it is available interactively -- GRID-RUNBOOK uses it to write
# repo paths that are copy-paste runnable on any machine (\$DOTFILES_GITHUB_PATH/recology, etc)
# without hardcoding ANGLACHEL's layout into a committed doc.
export DOTFILES_GITHUB_PATH="$DOTFILES_GITHUB_PATH"
# <<< dotfiles TDBI path <<<
SHELLCONFIG_TDBI
    echo '      TDBI bin PATH deployed to ~/.bashrc.'
fi

echo ''
echo '[3/3] Deploying .bash_aliases symlink...'
ALIASES_SOURCE="$REPO_DIR/config/.bash_aliases"
ALIASES_TARGET="$HOME/.bash_aliases"

if [ ! -f "$ALIASES_SOURCE" ]; then
    echo '      .bash_aliases not found in config - skipping.'
elif [ -L "$ALIASES_TARGET" ] && [ "$(readlink "$ALIASES_TARGET")" = "$ALIASES_SOURCE" ]; then
    echo '      .bash_aliases symlink already in place - skipping.'
else
    ln -sf "$ALIASES_SOURCE" "$ALIASES_TARGET"
    echo "      Symlinked .bash_aliases -> $ALIASES_SOURCE"
fi

echo ''
echo '=== Deploy complete. ==='
echo 'Run "source ~/.bashrc" or open a new terminal to apply changes.'
