#!/usr/bin/env bash
# bootstrap.sh - Full machine setup from scratch
#
# Usage:
#   ./bootstrap.sh
#
# Prerequisites:
#   - Run 0_personalize.sh first to create config.env
#   - WSL installed and configured (see README.md step 2)
#   - Git configured with SSH keys (see README.md step 4)
#   - VS Code installed on Windows with WSL extension (see README.md step 6)
#
# What it does:
#   Deploys all modules in the correct dependency order:
#     1. conda  - Python runtime (everything depends on this)
#     2. vscode - Editor and extensions (depends on Python)
#     3. shell  - Shell config and aliases (depends on nothing, goes last)
#
# Each module is self-contained and can also be run independently:
#   cd 1_conda && ./3_deploy.sh
#   cd 2_vscode && ./3_deploy.sh
#   cd 3_shell && ./3_deploy.sh
#
# Do NOT run with sudo.

set -e  # exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to repo root
CONFIG_FILE="$REPO_DIR/config.env"                           # personal config file

echo '================================================'
echo '  dotfiles bootstrap'
echo '  Full machine setup'
echo '================================================'
echo ''

# Check not running as root
if [[ "$EUID" -eq 0 ]]; then    # EUID 0 means root
    echo 'ERROR: Do not run this script as root or with sudo.'
    exit 1
fi

# Check config.env exists
if [[ ! -f "$CONFIG_FILE" ]]; then    # verify personalization has been run
    echo 'ERROR: config.env not found.'
    echo 'Run 0_personalize.sh first to set up your personal configuration.'
    exit 1
fi

# Load personal config
source "$CONFIG_FILE"    # load DOTFILES_* variables

echo "Deploying for: $DOTFILES_USER_NAME <$DOTFILES_USER_EMAIL>"
echo ''

# ── Module 1: conda ───────────────────────────────────────────────────────────
echo '[ 1/3 ] Running conda module setup and deploy...'
echo ''

bash "$REPO_DIR/1_conda/0_setup.sh"    # run conda prerequisites
bash "$REPO_DIR/1_conda/3_deploy.sh"   # install Miniforge and configure conda-forge

echo ''
echo '[ 1/3 ] conda module complete.'
echo ''

# ── Module 2: vscode ──────────────────────────────────────────────────────────
echo '[ 2/3 ] Running vscode module setup and deploy...'
echo ''

bash "$REPO_DIR/2_vscode/0_setup.sh"                                    # run vscode prerequisites
bash "$REPO_DIR/2_vscode/3_deploy.sh" "$DOTFILES_FIRST_PROJECT"         # install extensions and settings

echo ''
echo '[ 2/3 ] vscode module complete.'
echo ''

# ── Module 3: shell ───────────────────────────────────────────────────────────
echo '[ 3/3 ] Running shell module setup and deploy...'
echo ''

bash "$REPO_DIR/3_shell/0_setup.sh"    # run shell prerequisites
bash "$REPO_DIR/3_shell/3_deploy.sh"   # deploy shell config to ~/.bashrc

echo ''
echo '[ 3/3 ] shell module complete.'
echo ''

# ── Final instructions ────────────────────────────────────────────────────────
echo '================================================'
echo '  Bootstrap complete.'
echo ''
echo '  Next steps:'
echo '  1. Open a new terminal or restart VS Code'
echo '  2. Run: source ~/.bashrc'
echo '  3. Verify each module:'
echo "     cd ~/repos/dotfiles/1_conda && ./4_test.sh"
echo "     cd ~/repos/dotfiles/2_vscode && ./4_test.sh"
echo "     cd ~/repos/dotfiles/3_shell && ./4_test.sh"
echo '================================================'
