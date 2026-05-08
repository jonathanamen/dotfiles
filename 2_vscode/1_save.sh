#!/usr/bin/env bash
# save.sh — Snapshot current VS Code state into this repo
#
# Usage:
#   ./save.sh
#
# Run from the vscode/ directory of this repo whenever you want to commit
# your current VS Code settings and extension list to git.
#
# Files written:
#   global/settings.json        — live VS Code settings
#   global/keybindings.json     — live keybindings
#   global/extensions.snapshot  — everything currently installed (auto-generated, do not edit)
#
# Note: global/extensions.txt is your curated intentional list and is NOT
# overwritten by this script. Edit it manually when you want to add or remove
# an extension from your standard deploy.

set -e  # Exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$REPO_DIR/global"

# Match the path used in deploy.sh
VSCODE_SETTINGS_DIR="$HOME/.vscode-server/data/Machine"
# If using native Linux VS Code instead, use:
# VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"

echo '=== VS Code Save ==='

# ── 1. Settings and keybindings ───────────────────────────────────────────────
echo ''
echo '[1/2] Saving settings and keybindings...'

mkdir -p "$GLOBAL_DIR"
cp "$VSCODE_SETTINGS_DIR/settings.json"    "$GLOBAL_DIR/settings.json"
cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$GLOBAL_DIR/keybindings.json"

echo '      Saved settings.json and keybindings.json.'

# ── 2. Extension snapshot ─────────────────────────────────────────────────────
echo ''
echo '[2/2] Saving extension snapshot...'

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

# ── Suggest next steps ────────────────────────────────────────────────────────
echo ''
echo '=== Save complete. Review and commit your changes: ==='
echo ''
echo '    git diff'
echo '    git add -A'
echo '    git commit -m "chore: snapshot vscode env $(date +%Y-%m-%d)"'
echo '    git push'
