#!/usr/bin/env bash
# save.sh — Snapshot current VS Code and Claude Code state into this repo
#
# Usage:
#   ./save.sh
#
# Run from the vscode/ directory of this repo whenever you want to commit
# your current VS Code settings and extension list to git.
#
# Files written:
#   global/settings.json        — live VS Code settings (Windows side preferred)
#   global/keybindings.json     — live keybindings (Windows side preferred)
#   global/extensions.snapshot  — everything currently installed (auto-generated, do not edit)
#   claude/settings.json        — Claude Code global settings (~/.claude/settings.json)
#
# Note: global/extensions.txt is your curated intentional list and is NOT
# overwritten by this script. Edit it manually when you want to add or remove
# an extension from your standard deploy.

set -e  # Exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$REPO_DIR/global"
CLAUDE_DIR="$REPO_DIR/claude"

# Load config.env to get Windows username
DOTFILES_ROOT="$(cd "$REPO_DIR/.." && pwd)"
if [[ -f "$DOTFILES_ROOT/config.env" ]]; then
    source "$DOTFILES_ROOT/config.env"
fi

# VS Code settings paths — prefer Windows side (where UI writes), fall back to WSL
WINDOWS_SETTINGS_DIR="/mnt/c/Users/${DOTFILES_WINDOWS_USERNAME}/AppData/Roaming/Code/User"
WSL_SETTINGS_DIR="$HOME/.vscode-server/data/Machine"

if [[ -d "$WINDOWS_SETTINGS_DIR" ]]; then
    VSCODE_SETTINGS_DIR="$WINDOWS_SETTINGS_DIR"
    echo "      Using Windows-side settings (authoritative for UI changes)."
else
    VSCODE_SETTINGS_DIR="$WSL_SETTINGS_DIR"
    echo "      Windows path not found, falling back to WSL-side settings."
fi

echo '=== VS Code Save ==='

# ── 1. Settings and keybindings ───────────────────────────────────────────────
echo ''
echo '[1/3] Saving settings and keybindings...'

mkdir -p "$GLOBAL_DIR"
cp "$VSCODE_SETTINGS_DIR/settings.json"    "$GLOBAL_DIR/settings.json"
cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$GLOBAL_DIR/keybindings.json"

echo '      Saved settings.json and keybindings.json.'

# ── 2. Extension snapshot ─────────────────────────────────────────────────────
echo ''
echo '[2/3] Saving extension snapshot...'

# Write live extension list to snapshot file — NOT extensions.txt
# extensions.txt is the curated intentional list and is managed manually
code --list-extensions | sort > "$GLOBAL_DIR/extensions.snapshot"

echo '      Saved extensions.snapshot.'
echo ''
echo '--- Currently installed extensions ---'
cat "$GLOBAL_DIR/extensions.snapshot"
echo '--------------------------------------'
echo ''
echo '      Tip: compare snapshot to curated list to see drift:'
echo '      diff global/extensions.txt global/extensions.snapshot'

# ── 3. Claude Code global settings ───────────────────────────────────────────
echo ''
echo '[3/3] Saving Claude Code global settings...'

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if [[ -f "$CLAUDE_SETTINGS" ]]; then
    mkdir -p "$CLAUDE_DIR"
    cp "$CLAUDE_SETTINGS" "$CLAUDE_DIR/settings.json"
    echo '      Saved ~/.claude/settings.json.'
else
    echo '      ~/.claude/settings.json not found -- skipping.'
fi

# ── Suggest next steps ────────────────────────────────────────────────────────
echo ''
echo '=== Save complete. Review and commit your changes: ==='
echo ''
echo '    git status'
echo '    git add -A'
echo '    git commit -m "chore: snapshot vscode env $(date +%Y-%m-%d)"'
echo '    git push'
