#!/usr/bin/env bash
# 3_deploy.sh - Install Miniforge and rebuild conda environments
#
# Usage:
#   ./3_deploy.sh
#
# What it does:
#   - Downloads the latest Miniforge installer for Linux x86_64
#   - Installs Miniforge silently to $HOME/miniforge3
#   - conda-forge is pre-configured as the only channel (no Anaconda defaults)
#   - Initializes conda for bash
#   - Sets auto_activate_base to false (WSL best practice)
#   - Rebuilds all named environments from environments/*.yml files
#
# Why Miniforge over Miniconda?
#   - Ships pre-configured with conda-forge as the only channel
#   - No Anaconda TOS, no commercial licensing restrictions
#   - Miniconda hard-codes Anaconda defaults in ways that are difficult to remove
#   - Miniforge is the recommended installer by the conda-forge community
#   - Industry standard for data science and engineering teams
#
# Do NOT run with sudo.

set -e  # exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to this script's directory
ENVIRONMENTS_DIR="$REPO_DIR/environments"                    # path to saved environment definitions
MINIFORGE_DIR="$HOME/miniforge3"                             # standard Miniforge install location
INSTALLER="$HOME/miniforge_installer.sh"                     # temporary installer file path

echo '=== Conda Deploy ==='

# Check not running as root
if [[ "$EUID" -eq 0 ]]; then    # EUID 0 means root
    echo 'ERROR: Do not run this script as root or with sudo.'
    echo 'Miniforge installed as root will not be accessible as your normal user.'
    exit 1
fi

# 1. Install Miniforge
echo ''
echo '[1/4] Installing Miniforge...'

if [[ -d "$MINIFORGE_DIR" ]]; then    # check if already installed
    echo "      Miniforge already installed at $MINIFORGE_DIR - skipping download."
else
    echo '      Downloading Miniforge installer...'
    wget -q "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" -O "$INSTALLER"    # download latest Miniforge

    echo '      Installing Miniforge silently...'
    bash "$INSTALLER" -b -p "$MINIFORGE_DIR"    # -b = batch mode (no prompts), -p = install path

    rm -f "$INSTALLER"    # remove installer after use

    echo '      Initializing conda for bash...'
    "$MINIFORGE_DIR/bin/conda" init bash    # adds conda init block to ~/.bashrc

    echo '      Setting auto_activate_base to false...'
    "$MINIFORGE_DIR/bin/conda" config --set auto_activate_base false    # WSL best practice
fi

echo '      Miniforge installed.'

# Activate conda for this script session
eval "$("$MINIFORGE_DIR/bin/conda" shell.bash hook)"    # activate conda in current shell session

# Verify conda-forge is the only channel — Miniforge ships clean but verify anyway
CHANNELS=$(conda config --show channels)
if echo "$CHANNELS" | grep -q 'defaults'; then    # fail loudly if defaults is present
    echo 'ERROR: Anaconda defaults channel detected. Remove it and re-run.'
    echo 'Run: conda config --remove channels defaults'
    exit 1
fi

echo '      Channel config verified: conda-forge only.'

# 2. Update conda to latest version
echo ''
echo '[2/4] Updating conda...'

conda update -n base conda --yes -q    # update conda silently

echo '      Conda updated.'

# 3. Rebuild environments from yml files
echo ''
echo '[3/4] Rebuilding environments...'

if ! compgen -G "$ENVIRONMENTS_DIR/*.yml" > /dev/null 2>&1; then    # check if any yml files exist
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

# 4. Install base-environment packages
#
# The TDBI grid runs on the BASE python (~/miniforge3/bin/python3), not on a named environment,
# so its dependencies are installed here rather than in an env yml. Without this, librarian
# retrieval fails on a fresh machine with an ImportError and nothing on the machine says why.
echo ''
echo '[4/4] Installing base-environment packages...'

BASE_PACKAGES="$REPO_DIR/base-packages.txt"    # pip packages for the base env

if [[ -f "$BASE_PACKAGES" ]]; then
    "$MINIFORGE_DIR/bin/python3" -m pip install --quiet --upgrade -r "$BASE_PACKAGES"
    echo "      Installed from base-packages.txt"
else
    echo '      No base-packages.txt found - skipping.'
fi

echo ''
echo '=== Deploy complete. ==='
echo 'Open a new terminal or restart VS Code to use conda.'

