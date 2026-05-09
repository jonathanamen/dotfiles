#!/usr/bin/env bash
# 2_wipe.sh - Clean uninstall of conda and all environments
#
# Usage:
#   ./2_wipe.sh
#
# What it does:
#   - Removes all named conda environments
#   - Uninstalls Miniforge from $HOME/miniforge3
#   - Also removes Miniconda from $HOME/miniconda3 if present
#   - Removes conda init lines from ~/.bashrc
#
# WARNING: This is destructive. Run 1_save.sh first to export your environments.
# Do NOT run with sudo.

set -e  # exit immediately if any command fails

MINIFORGE_DIR="$HOME/miniforge3"    # standard Miniforge install location
MINICONDA_DIR="$HOME/miniconda3"    # Miniconda location - removed if present

echo '=== Conda Wipe ==='
echo ''
echo 'WARNING: This will remove all conda environments and Miniforge.'
echo 'Run 1_save.sh first if you have unsaved environments.'
echo ''

# Confirm before wiping
read -r -p 'Are you sure you want to wipe? (yes/no): ' CONFIRM    # prompt for confirmation

if [[ "$CONFIRM" != 'yes' ]]; then    # require exact 'yes' to proceed
    echo 'Wipe cancelled.'
    exit 0
fi

# Check if anything to wipe
if ! command -v conda &> /dev/null && [[ ! -d "$MINIFORGE_DIR" ]] && [[ ! -d "$MINICONDA_DIR" ]]; then
    echo 'No conda installation found - already clean.'
    exit 0
fi

# 1. Remove all named environments
echo ''
echo '[1/3] Removing all named conda environments...'

if command -v conda &> /dev/null; then    # only if conda is accessible
    ENVS=$(conda env list | grep -v '^#' | grep -v '^base' | grep -v '^$' | awk '{print $1}')

    if [[ -z "$ENVS" ]]; then
        echo '      No named environments found.'
    else
        while IFS= read -r env; do
            [[ -z "$env" ]] && continue
            echo "      Removing environment: $env"
            conda env remove -n "$env" --yes 2>/dev/null    # remove environment without prompting
        done <<< "$ENVS"
    fi

    conda clean --all --yes 2>/dev/null    # remove all cached packages and tarballs
fi

echo '      Environments removed.'

# 2. Remove installation directories
echo ''
echo '[2/3] Removing conda installation...'

if [[ -d "$MINIFORGE_DIR" ]]; then
    rm -rf "$MINIFORGE_DIR"    # remove the entire Miniforge directory
    echo '      Miniforge directory removed.'
fi

if [[ -d "$MINICONDA_DIR" ]]; then
    rm -rf "$MINICONDA_DIR"    # remove Miniconda if present
    echo '      Miniconda directory removed.'
fi

# 3. Remove conda init block from .bashrc
echo ''
echo '[3/3] Cleaning shell config...'

if grep -q 'conda initialize' "$HOME/.bashrc"; then    # check if conda init block exists
    sed -i '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$HOME/.bashrc"    # remove the block
    echo '      Removed conda init block from ~/.bashrc.'
else
    echo '      No conda init block found in ~/.bashrc.'
fi

echo ''
echo '=== Wipe complete. Run 3_deploy.sh to reinstall. ==='
echo 'Note: Run "source ~/.bashrc" or open a new terminal to apply shell changes.'
