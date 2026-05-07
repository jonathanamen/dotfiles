#!/usr/bin/env bash
# save.sh — Snapshot current VS Code state into this repo
#
# Usage:
#   ./save.sh
#
# Run from the root of this repo whenever you want to commit
# your current VS Code settings and extension list to git.

set -e  # Exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$REPO_DIR/global"

# Match the path used in deploy.sh
VSCODE_SETTINGS_DIR="$HOME/.vscode-server/data/Machine"
# If using native Linux VS Code instead, use:
# VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"

echo "=== VS Code Save ==="

# ── 1. Settings and keybindings ───────────────────────────────────────────────
echo ""
echo "[1/2] Saving settings and keybindings..."

mkdir -p "$GLOBAL_DIR"
cp "$VSCODE_SETTINGS_DIR/settings.json"    "$GLOBAL_DIR/settings.json"
cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$GLOBAL_DIR/keybindings.json"

echo "      Saved settings.json and keybindings.json."

# ── 2. Extension list ─────────────────────────────────────────────────────────
echo ""
echo "[2/2] Saving installed extensions..."

# List all installed extensions, sort alphabetically, write to file
code --list-extensions | sort > "$GLOBAL_DIR/extensions.txt"

echo "      Saved extensions.txt."
echo ""
echo "--- Current extension list ---"
cat "$GLOBAL_DIR/extensions.txt"
echo "------------------------------"

# ── Suggest next steps ────────────────────────────────────────────────────────
echo ""
echo "=== Save complete. Review and commit your changes: ==="
echo ""
echo '    git diff'
echo '    git add -A'
echo '    git commit -m "chore: snapshot vscode env $(date +%Y-%m-%d)"'
echo '    git push'
