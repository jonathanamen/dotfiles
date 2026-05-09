#!/usr/bin/env bash
# 2_wipe.sh — Clean uninstall of VS Code extensions and settings
#
# Usage:
#   ./2_wipe.sh
#
# What it does:
#   - Uninstalls all VS Code extensions in dependency-safe order
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

# ── Helper: uninstall one extension cleanly ───────────────────────────────────
uninstall_ext() {
    local ext="$1"
    echo "      Uninstalling $ext"
    # Capture output and filter noise — suppress "not installed" and other VS Code header messages
    local output
    output=$(code --uninstall-extension "$ext" --force 2>&1) || true
    # Only print output if it contains a real error — filter known noise lines
    echo "$output" | grep -v 'not installed' \
                   | grep -v '^Make sure' \
                   | grep -v 'Installing extensions' \
                   | grep -v '^$' || true
}

# ── 1. Uninstall dependents first to avoid conflict errors ────────────────────
echo ''
echo '[1/2] Uninstalling all VS Code extensions...'

# These must be uninstalled before their parent extension packs
# to avoid dependency conflict errors
UNINSTALL_FIRST=(
    'ms-python.black-formatter'    # must go before donjayamanne.python-extension-pack
    'ms-python.python'             # must go before donjayamanne.python-extension-pack
)

for ext in "${UNINSTALL_FIRST[@]}"; do
    uninstall_ext "$ext"
done

# Now uninstall all remaining extensions
# Filter to only valid extension IDs — format is always publisher.extension-name
EXTENSIONS=$(code --list-extensions | grep -E '^[a-zA-Z0-9-]+\.[a-zA-Z0-9._-]+')   # keep only valid IDs

if [[ -z "$EXTENSIONS" ]]; then         # check if any extensions remain
    echo '      No extensions found — already clean.'
else
    while IFS= read -r ext; do
        [[ -z "$ext" ]] && continue     # skip blank lines
        uninstall_ext "$ext"
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
