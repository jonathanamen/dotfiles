#!/usr/bin/env bash
# 3_deploy.sh - Install Miniconda and rebuild conda environments
#
# Usage:
#   ./3_deploy.sh
#
# What it does:
#   - Downloads the latest Miniconda installer for Linux x86_64
#   - Installs Miniconda silently to $HOME/miniconda3
#   - Initializes conda for bash
#   - Sets auto_activate_base to false (WSL best practice)
#   - Rebuilds all named environments from environments/*.yml files
#
# Do NOT run with sudo.

set -e  # exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to this script's directory
ENVIRONMENTS_DIR="$REPO_DIR/environments"                    # path to saved environment definitions
MINICONDA_DIR="$HOME/miniconda3"                             # standard Miniconda install location
INSTALLER="$HOME/miniconda_installer.sh"                     # temporary installer file path

echo '=== Conda Deploy ==='

# Check not running as root
if [[ "$EUID" -eq 0 ]]; then    # EUID 0 means root
    echo 'ERROR: Do not run this script as root or with sudo.'
    echo 'Conda installed as root will not be accessible as your normal user.'
    exit 1
fi

# 1. Install Miniconda
echo ''
echo '[1/3] Installing Miniconda...'

if [[ -d "$MINICONDA_DIR" ]]; then    # check if already installed
    echo "      Miniconda already installed at $MINICONDA_DIR - skipping download."
else
    echo '      Downloading Miniconda installer...'
    wget -q "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" -O "$INSTALLER"    # download silently

    echo '      Installing Miniconda silently...'
    bash "$INSTALLER" -b -p "$MINICONDA_DIR"    # -b = batch mode (no prompts), -p = install path

    rm -f "$INSTALLER"    # remove installer after use

    echo '      Initializing conda for bash...'
    "$MINICONDA_DIR/bin/conda" init bash    # adds conda init block to ~/.bashrc

    echo '      Setting auto_activate_base to false...'
    "$MINICONDA_DIR/bin/conda" config --set auto_activate_base false    # WSL best practice - don't activate base on every terminal
fi

echo '      Miniconda installed.'

# Activate conda for this script session
eval "$("$MINICONDA_DIR/bin/conda" shell.bash hook)"    # activate conda in current shell session

# 2. Update conda to latest version
echo ''
echo '[2/3] Updating conda...'

conda update -n base -c defaults conda --yes -q    # update conda itself silently

echo '      Conda updated.'

# 3. Rebuild environments from yml files
echo ''
echo '[3/3] Rebuilding environments...'

if [[ ! -d "$ENVIRONMENTS_DIR" ]] || ! compgen -G "$ENVIRONMENTS_DIR/*.yml" > /dev/null 2>&1; then
    echo '      No environment definitions found in environments/'
    echo '      Add .yml files to environments/ to have them rebuilt on deploy.'
else
    for yml in "$ENVIRONMENTS_DIR"/*.yml; do    # loop over all yml files
        ENV_NAME=$(basename "$yml" .yml)         # extract environment name from filename
        echo "      Creating environment: $ENV_NAME"
        conda env create -f "$yml" --yes -q      # create environment from yml file silently
        echo "      Created: $ENV_NAME"
    done
fi

echo ''
echo '=== Deploy complete. ==='
echo 'Run "source ~/.bashrc" or open a new terminal to use conda.'
echo 'Activate an environment with: conda activate <name>'
