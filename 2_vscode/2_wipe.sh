#!/usr/bin/env bash
# 2_wipe.sh — Clean uninstall of VS Code extensions and settings
#
# Usage:
#   ./2_wipe.sh
#
# What it does:
#   - Uninstalls all VS Code extensions
#   - Removes VS Code user settings from WSL
#
# WARNING: This is destructive. Run 1_save.sh first to snapshot your state.
# Your VS Code installation on Windows is not affected — only WSL-side config.

set -e  # exit immediately if any command fails

echo '=== VS Code Wipe ==='
echo ''
echo 'WARNING: This will uninstall all extensions and clear WSL-side settings.'
echo 'Run 1_save.sh first if you have unsaved changes.'
echo ''

# ── Confirm before wiping ─────────────────────────────────────────────────────
read -r -p 'Are you sure you want to wipe? (yes/no): ' CONFIRM   # prompt for confirmation

if [[ "$CONFIRM" != 'yes' ]]; then      # require exact 'yes' to proceed
    echo 'Wipe cancelled.'
    exit 0
fi

# ── 1. Uninstall all extensions ───────────────────────────────────────────────
echo ''
echo '[1/2] Uninstalling all VS Code extensions...'

EXTENSIONS=$(code --list-extensions)    # get list of all installed extensions

if [[ -z "$EXTENSIONS" ]]; then         # check if any extensions are installed
    echo '      No extensions found — already clean.'
else
    while IFS= read -r ext; do
        echo "      Uninstalling $ext"
        code --uninstall-extension "$ext" --force 2>/dev/null   # uninstall each extension
    done <<< "$EXTENSIONS"
fi

echo '      All extensions uninstalled.'

# ── 2. Clear WSL-side VS Code settings ───────────────────────────────────────
echo ''
echo '[2/2] Clearing VS Code settings...'

VSCODE_SETTINGS_DIR="$HOME/.vscode-server/data/Machine"   # WSL VS Code settings path

if [[ -d "$VSCODE_SETTINGS_DIR" ]]; then    # only remove if directory exists
    rm -f "$VSCODE_SETTINGS_DIR/settings.json"      # remove settings
    rm -f "$VSCODE_SETTINGS_DIR/keybindings.json"   # remove keybindings
    echo '      Settings cleared.'
else
    echo '      No settings found — already clean.'
fi

echo ''
echo '=== Wipe complete. Run 3_deploy.sh to reinstall. ==='
