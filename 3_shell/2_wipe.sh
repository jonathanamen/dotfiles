#!/usr/bin/env bash
# 2_wipe.sh - Remove deployed shell config from ~/.bashrc
#
# Usage:
#   ./2_wipe.sh
#
# What it does:
#   - Removes the shell config block managed by this repo from ~/.bashrc
#   - Does NOT remove conda init or other blocks managed by other tools
#   - Creates a backup of ~/.bashrc before making any changes
#   - Keeps only the most recent backup (older ones are deleted)
#
# Why keep only 1 local backup:
#   Git holds the full history of all committed states. The local backup
#   is only a safety net for the current run. Older backups are redundant.
#
# WARNING: Run 1_save.sh first to snapshot your current state.

set -e  # exit immediately if any command fails

MARKER_START='# >>> dotfiles shell config >>>'    # start marker for managed block
MARKER_TDBI_START='# >>> dotfiles TDBI path >>>'   # start marker for the TDBI PATH block

echo '=== Shell Wipe ==='
echo ''
echo 'WARNING: This will remove the dotfiles shell config block from ~/.bashrc.'
echo 'Run 1_save.sh first if you have unsaved changes.'
echo ''

# Confirm before wiping
read -r -p 'Are you sure you want to wipe? (yes/no): ' CONFIRM    # prompt for confirmation

if [[ "$CONFIRM" != 'yes' ]]; then    # require exact 'yes' to proceed
    echo 'Wipe cancelled.'
    exit 0
fi

# Check if either managed block exists
if ! grep -q "$MARKER_START" "$HOME/.bashrc" && ! grep -q "$MARKER_TDBI_START" "$HOME/.bashrc"; then
    echo 'No dotfiles shell config block found in ~/.bashrc - already clean.'
    exit 0
fi

# Back up ~/.bashrc before modifying
BACKUP="$HOME/.bashrc.bak.$(date +%Y%m%d%H%M%S)"    # timestamped backup filename
cp "$HOME/.bashrc" "$BACKUP"                           # copy current .bashrc to backup
echo "Backed up ~/.bashrc to: $BACKUP"

# Keep only the most recent backup - delete all older ones
# ls -t sorts by newest first, tail -n +2 skips the first (newest) and outputs the rest
ls -t "$HOME"/.bashrc.bak.* 2>/dev/null | tail -n +2 | xargs rm -f 2>/dev/null || true
echo 'Old backups removed - keeping most recent only.'

# Remove the managed blocks
sed -i "/# >>> dotfiles shell config >>>/,/# <<< dotfiles shell config <<</d" "$HOME/.bashrc"    # remove main block
sed -i "/# >>> dotfiles TDBI path >>>/,/# <<< dotfiles TDBI path <<</d" "$HOME/.bashrc"          # remove TDBI PATH block
echo 'Removed dotfiles shell config blocks from ~/.bashrc.'

echo ''
echo '=== Wipe complete. Run 3_deploy.sh to reinstall. ==='
echo 'Run "source ~/.bashrc" or open a new terminal to apply changes.'
