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
echo '[1/5] Copying global VS Code settings...'

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
echo '[2/5] Installing global extensions...'

while IFS= read -r ext || [[ -n "$ext" ]]; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue
    echo "      Installing $ext"
    code --install-extension "$ext" --force 2>/dev/null
done < "$GLOBAL_DIR/extensions.txt"
echo '      Global extensions done.'

# ── 3. Project-specific config (optional) ─────────────────────────────────────
echo ''
if [[ -z "$PROJECT" ]]; then
    echo '[3/5] No project specified — skipping project config.'
    echo '      Available projects:'
    for d in "$REPO_DIR/projects"/*/; do
        echo "        - $(basename "$d")"
    done
    echo ''
    echo '      Run with a project name to apply project config:'
    echo '      ./vscode/deploy.sh your-project-name'
else
    echo "[3/5] Applying project config: $PROJECT"
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
echo '[4/5] Deploying Claude Code global settings...'

CLAUDE_SETTINGS_SRC="$REPO_DIR/claude/settings.json"
# The WINDOWS profile, not $HOME. Claude Code's GUI runs Windows-side and reads the settings there;
# 1_save.sh has always READ from that path while this deployed to the Linux one, so the deploy has
# been writing to a file nothing loads (O-1255). Same derivation 1_save.sh uses.
WIN_USER="${DOTFILES_WINDOWS_USERNAME:-$(echo "$DOTFILES_ROOT" | cut -d/ -f5)}"
CLAUDE_SETTINGS_DEST="/mnt/c/Users/$WIN_USER/.claude/settings.json"

if [[ -f "$CLAUDE_SETTINGS_SRC" ]]; then
    mkdir -p "$(dirname "$CLAUDE_SETTINGS_DEST")"
    cp "$CLAUDE_SETTINGS_SRC" "$CLAUDE_SETTINGS_DEST"
    echo "      Deployed claude/settings.json to $CLAUDE_SETTINGS_DEST."
else
    echo '      claude/settings.json not found in repo -- skipping.'
fi

# ── 5. The raw-sync Stop hook ────────────────────────────────────────────────
# Written HERE and not committed, because the command names this machine's interpreter and
# checkout. It used to live inside claude/settings.json above, which shipped ENIAC's `wsl.exe`
# line to every machine -- unrunnable on a Windows-native one, and silent when it failed.
# Runs AFTER the copy above, which would otherwise overwrite the registration.
echo ''
echo '[5/5] Registering the raw-sync Stop hook...'
if [[ -z "${DOTFILES_GITHUB_PATH:-}" ]]; then
    echo '      DOTFILES_GITHUB_PATH not set -- cannot find TDBI. Skipping.'
elif [[ ! -f "$DOTFILES_GITHUB_PATH/TDBI/tools/register_hook.py" ]]; then
    echo "      No TDBI checkout at $DOTFILES_GITHUB_PATH/TDBI - skipping."
    echo '      Without this the session transcript is never captured.'
else
    "$HOME/miniforge3/bin/python3" "$DOTFILES_GITHUB_PATH/TDBI/tools/register_hook.py"
fi

echo ''
echo '=== Deploy complete. Restart VS Code to apply all settings. ==='
