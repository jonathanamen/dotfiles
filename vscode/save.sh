#!/usr/bin/env bash
# save.sh — Snapshot current VS Code state into this repo
#
# Usage:
#   ./save.sh
#
# Run from the vscode/ directory of this repo whenever you want
# to commit your current VS Code settings and extension list to git.

set -e  # Exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$REPO_DIR/global"

VSCODE_SETTINGS_DIR="$HOME/.vscode-server/data/Machine"
# Native Linux alternative:
# VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"

echo "=== VS CODE Dev Env Save ==="

echo ""
echo "[1/2] Saving settings and keybindings..."
mkdir -p "$GLOBAL_DIR"
cp "$VSCODE_SETTINGS_DIR/settings.json"    "$GLOBAL_DIR/settings.json"
cp "$VSCODE_SETTINGS_DIR/keybindings.json" "$GLOBAL_DIR/keybindings.json"
echo "      Saved settings.json and keybindings.json."

echo ""
echo "[2/2] Saving installed extensions..."
code --list-extensions | sort > "$GLOBAL_DIR/extensions.txt"
echo "      Saved extensions.txt."
echo ""
echo "--- Current extension list ---"
cat "$GLOBAL_DIR/extensions.txt"
echo "------------------------------"

echo ""
echo "=== Save complete. Commit your changes: ==="
echo ""
echo "    git add -A"
echo "    git commit -m \"chore: snapshot vscode env \$(date +%Y-%m-%d)\""
echo "    git push"
