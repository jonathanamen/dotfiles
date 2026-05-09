#!/usr/bin/env bash
# 0_setup.sh - One-time prerequisites for the conda module
#
# Run this once on a fresh machine before running 3_deploy.sh.
# Safe to run multiple times - checks before installing.
#
# What it does:
#   - Verifies we are NOT running as root (sudo breaks conda on WSL)
#   - Verifies wget is available for downloading the Miniforge installer
#   - Verifies bash version is 5 or higher
#   - If conda is already installed, verifies it is Miniforge not Miniconda
#
# Note: Do NOT run this script with sudo. Conda must be installed as your
# normal user or it will not be accessible without sudo -i.
#
# Why Miniforge over Miniconda?
#   - Ships pre-configured with conda-forge as the only channel
#   - No Anaconda TOS or commercial licensing restrictions
#   - Miniconda hard-codes Anaconda defaults in ways that are difficult to remove
#   - Recommended by the conda-forge community

set -e  # exit immediately if any command fails

MINIFORGE_DIR="$HOME/miniforge3"    # standard Miniforge install location

echo '=== Conda Module Setup ==='

# 1. Check not running as root
echo ''
echo '[1/4] Checking user context...'

if [[ "$EUID" -eq 0 ]]; then     # EUID is the effective user ID - 0 means root
    echo '      ERROR: Do not run this script as root or with sudo.'
    echo '      Conda installed as root will not be accessible as your normal user.'
    echo '      Run as your normal user: ./0_setup.sh'
    exit 1
fi

echo "      Running as user: $USER - OK."

# 2. Check wget is available
echo ''
echo '[2/4] Checking wget is available...'

if ! command -v wget &> /dev/null; then    # check if wget exists in PATH
    echo '      wget not found. Installing...'
    sudo apt update && sudo apt install -y wget    # install wget via apt
fi

echo '      wget is available.'

# 3. Check bash version
echo ''
echo '[3/4] Checking bash version...'

BASH_VER=$(bash --version | head -1)                           # get full bash version string
BASH_MAJOR=$(echo "$BASH_VER" | grep -oP '\d+' | head -1)     # extract major version number

if [[ "$BASH_MAJOR" -ge 5 ]]; then    # verify bash 5 or higher
    echo "      Bash version OK: $BASH_VER"
else
    echo "      WARNING: Bash version is $BASH_MAJOR - version 5 or higher recommended."
    echo '      Run: sudo apt upgrade bash'
fi

# 4. Check for existing conda install - warn if Miniconda detected
echo ''
echo '[4/4] Checking existing conda installation...'

if [[ -d "$HOME/miniconda3" ]]; then    # check for Miniconda install directory
    echo '      WARNING: Miniconda detected at ~/miniconda3.'
    echo '      This repo uses Miniforge. Run 2_wipe.sh to remove Miniconda first.'
    echo '      Then run 3_deploy.sh to install Miniforge.'
    exit 1
elif [[ -d "$MINIFORGE_DIR" ]]; then    # check for existing Miniforge install
    echo "      Miniforge already installed at $MINIFORGE_DIR - OK."
else
    echo '      No existing conda installation found - ready for fresh install.'
fi

echo ''
echo '=== Setup complete. You are ready to run 3_deploy.sh ==='
