#!/usr/bin/env bash
# deploy.sh — Restore VS Code environment from this repo
#
# Usage:
#   ./deploy.sh                          # global settings and extensions only
#   ./deploy.sh p008-arcane-predictive   # global + project-specific config
#
# Run from the vscode/ directory of this repo.

set -e  # Exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$REPO_DIR/global"
PROJECT="$1"

VSCODE_SETTINGS_DIR="$HOME/.vscode-server/data/Machine"
# Native Linux alternative:
# VSCODE_SETTINGS_DIR="$HOME/.config/Code/User"

echo "=== VS CODE Dev Env Deploy ==="

echo ""
echo "[1/3] Copying global VS Code settings..."
mkdir -p "$VSCODE_SETTINGS_DIR"
cp "$GLOBAL_DIR/settings.json"    "$VSCODE_SETTINGS_DIR/settings.json"
cp "$GLOBAL_DIR/keybindings.json" "$VSCODE_SETTINGS_DIR/keybindings.json"
echo "      settings.json and keybindings.json copied."

echo ""
echo "[2/3] Installing global extensions..."
while IFS= read -r ext || [[ -n "$ext" ]]; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    echo "      Installing $ext"
    code --install-extension "$ext" --force 2>/dev/null
done < "$GLOBAL_DIR/extensions.txt"
echo "      Global extensions done."

echo ""
if [[ -z "$PROJECT" ]]; then
    echo "[3/3] No project specified — skipping project config."
    echo "      Available projects:"
    for d in "$REPO_DIR/projects"/*/; do
        echo "        - $(basename "$d")"
    done
    echo ""
    echo "      Run with a project name to apply project config:"
    echo "      ./deploy.sh p008-arcane-predictive"
else
    echo "[3/3] Applying project config: $PROJECT"
    PROJECT_DIR="$REPO_DIR/projects/$PROJECT"
    if [[ ! -d "$PROJECT_DIR" ]]; then
        echo "      ERROR: Project folder not found: $PROJECT_DIR"
        exit 1
    fi
    PROJECT_EXT_FILE="$PROJECT_DIR/extensions.txt"
    if [[ -f "$PROJECT_EXT_FILE" ]]; then
        while IFS= read -r ext || [[ -n "$ext" ]]; do
            [[ -z "$ext" || "$ext" == \#* ]] && continue
            echo "      Installing $ext"
            code --install-extension "$ext" --force 2>/dev/null
        done < "$PROJECT_EXT_FILE"
    fi
    echo "      Project extensions done."
    echo "      Workspace settings are in: $PROJECT_DIR/settings.json"
fi

echo ""
echo "=== Deploy complete. Restart VS Code to apply all settings. ==="
