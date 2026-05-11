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
#
# WARNING: Run 1_save.sh first to snapshot your current state.

set -e  # exit immediately if any command fails

MARKER_START='# >>> dotfiles shell config >>>'    # start marker for managed block

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

# Check if managed block exists
if ! grep -q "$MARKER_START" "$HOME/.bashrc"; then    # check if block is present
    echo 'No dotfiles shell config block found in ~/.bashrc - already clean.'
    exit 0
fi

# Back up ~/.bashrc before modifying
BACKUP="$HOME/.bashrc.bak.$(date +%Y%m%d%H%M%S)"    # timestamped backup filename
cp "$HOME/.bashrc" "$BACKUP"                           # copy current .bashrc to backup
echo "Backed up ~/.bashrc to: $BACKUP"

# Remove the managed block
sed -i "/# >>> dotfiles shell config >>>/,/# <<< dotfiles shell config <<</d" "$HOME/.bashrc"    # remove block
echo 'Removed dotfiles shell config block from ~/.bashrc.'

echo ''
echo '=== Wipe complete. Run 3_deploy.sh to reinstall. ==='
echo 'Run "source ~/.bashrc" or open a new terminal to apply changes.'
