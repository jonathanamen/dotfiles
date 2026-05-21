#!/usr/bin/env bash
# deploy.sh — Restore VS Code environment from this repo
#
# Usage:
#   ./deploy.sh                            # global settings and extensions only
#   ./deploy.sh p008-arcane-predictive     # global + project-specific config
#
# Run from the vscode/ directory of this repo.
set -e  # Exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GLOBAL_DIR="$REPO_DIR/global"
PROJECT="$1"

# Load config.env to get Windows username
DOTFILES_ROOT="$(cd "$REPO_DIR/.." && pwd)"
if [[ -f "$DOTFILES_ROOT/config.env" ]]; then
    source "$DOTFILES_ROOT/config.env"
fi

# VS Code settings paths
WSL_SETTINGS_DIR="$HOME/.vscode-server/data/Machine"
WINDOWS_SETTINGS_DIR="/mnt/c/Users/${DOTFILES_WINDOWS_USERNAME}/AppData/Roaming/Code/User"

echo '=== VS Code Deploy ==='

# ── 1. Global settings ────────────────────────────────────────────────────────
echo ''
echo '[1/3] Copying global VS Code settings...'

# Write to WSL-side settings
mkdir -p "$WSL_SETTINGS_DIR"
cp "$GLOBAL_DIR/settings.json"    "$WSL_SETTINGS_DIR/settings.json"
cp "$GLOBAL_DIR/keybindings.json" "$WSL_SETTINGS_DIR/keybindings.json"
echo '      WSL settings deployed.'

# Write to Windows-side settings
if [[ -d "$WINDOWS_SETTINGS_DIR" ]]; then
    cp "$GLOBAL_DIR/settings.json"    "$WINDOWS_SETTINGS_DIR/settings.json"
    cp "$GLOBAL_DIR/keybindings.json" "$WINDOWS_SETTINGS_DIR/keybindings.json"
    echo '      Windows settings deployed.'
else
    echo "      WARNING: Windows settings path not found: $WINDOWS_SETTINGS_DIR"
    echo '      Skipping Windows-side settings deploy.'
fi

echo '      settings.json and keybindings.json copied.'

# ── 2. Global extensions ──────────────────────────────────────────────────────
echo ''
echo '[2/3] Installing global extensions...'

while IFS= read -r ext || [[ -n "$ext" ]]; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    echo "      Installing $ext"
    code --install-extension "$ext" --force 2>/dev/null
done < "$GLOBAL_DIR/extensions.txt"
echo '      Global extensions done.'

# ── 3. Project-specific config (optional) ─────────────────────────────────────
echo ''
if [[ -z "$PROJECT" ]]; then
    echo '[3/3] No project specified — skipping project config.'
    echo '      Available projects:'
    for d in "$REPO_DIR/projects"/*/; do
        echo "        - $(basename "$d")"
    done
    echo ''
    echo '      Run with a project name to apply project config:'
    echo '      ./vscode/deploy.sh your-project-name'
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
    echo '      Project extensions done.'
    echo "      Workspace settings are in: $PROJECT_DIR/settings.json"
fi

# ── 4. Claude Code global settings ───────────────────────────────────────────
echo ''
echo '[4/4] Deploying Claude Code global settings...'

CLAUDE_SETTINGS_SRC="$REPO_DIR/claude/settings.json"
CLAUDE_SETTINGS_DEST="$HOME/.claude/settings.json"

if [[ -f "$CLAUDE_SETTINGS_SRC" ]]; then
    mkdir -p "$HOME/.claude"
    cp "$CLAUDE_SETTINGS_SRC" "$CLAUDE_SETTINGS_DEST"
    echo '      Deployed claude/settings.json to ~/.claude/settings.json.'
else
    echo '      claude/settings.json not found in repo -- skipping.'
fi

echo ''
echo '=== Deploy complete. Restart VS Code to apply all settings. ==='
