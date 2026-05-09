#!/usr/bin/env bash
# 2_wipe.sh - Clean uninstall of conda and all environments
#
# Usage:
#   ./2_wipe.sh
#
# What it does:
#   - Removes all named conda environments
#   - Uninstalls Miniconda from $HOME/miniconda3
#   - Removes conda init lines from ~/.bashrc
#
# WARNING: This is destructive. Run 1_save.sh first to export your environments.
# Do NOT run with sudo.

set -e  # exit immediately if any command fails

MINICONDA_DIR="$HOME/miniconda3"    # standard Miniconda install location

echo '=== Conda Wipe ==='
echo ''
echo 'WARNING: This will remove all conda environments and Miniconda.'
echo 'Run 1_save.sh first if you have unsaved environments.'
echo ''

# Confirm before wiping
read -r -p 'Are you sure you want to wipe? (yes/no): ' CONFIRM    # prompt for confirmation

if [[ "$CONFIRM" != 'yes' ]]; then    # require exact 'yes' to proceed
    echo 'Wipe cancelled.'
    exit 0
fi

# Check conda is available
if ! command -v conda &> /dev/null; then    # check if conda exists in PATH
    echo ''
    echo 'conda not found in PATH - checking for Miniconda directory...'
    if [[ ! -d "$MINICONDA_DIR" ]]; then    # check if install directory exists
        echo 'Miniconda directory not found - already clean.'
        exit 0
    fi
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
fi

echo '      Environments removed.'

# 2. Run conda clean to remove cached packages
echo ''
echo '[2/3] Cleaning conda package cache...'

if command -v conda &> /dev/null; then
    conda clean --all --yes 2>/dev/null    # remove all cached packages and tarballs
fi

echo '      Cache cleared.'

# 3. Remove Miniconda directory and clean .bashrc
echo ''
echo '[3/3] Removing Miniconda installation...'

if [[ -d "$MINICONDA_DIR" ]]; then
    rm -rf "$MINICONDA_DIR"    # remove the entire Miniconda directory
    echo '      Miniconda directory removed.'
fi

# Remove conda init block from .bashrc
if grep -q 'conda initialize' "$HOME/.bashrc"; then    # check if conda init block exists
    # Remove the conda initialize block - everything between the two comment markers
    sed -i '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$HOME/.bashrc"
    echo '      Removed conda init block from ~/.bashrc.'
fi

echo ''
echo '=== Wipe complete. Run 3_deploy.sh to reinstall. ==='
echo 'Note: Run "source ~/.bashrc" or open a new terminal to apply shell changes.'
