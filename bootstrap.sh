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
#   1. Wipes all modules in reverse dependency order (node, shell, vscode, conda)
#   2. Deploys all modules in dependency order (conda, vscode, shell, node)
#   3. Runs all module tests to verify the deployment
#
# Wiping before deploying guarantees a clean state every time.
# Updates to any module config are always applied on the next bootstrap run.
#
# Each module is self-contained and can also be run independently:
#   cd 1_conda && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
#   cd 2_vscode && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
#   cd 3_shell && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
#   cd 4_node && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
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

# ── Wipe all modules in reverse dependency order ──────────────────────────────
# Reverse order: node first (no dependents), then shell, then vscode, then conda last
# This prevents dependency conflicts during uninstall
echo '================================================'
echo '  Phase 1: Wiping all modules'
echo '================================================'
echo ''

echo '[ Wipe 1/5 ] Wiping annex module...'
echo 'yes' | bash "$REPO_DIR/5_annex/2_wipe.sh"    # pipe 'yes' to skip confirmation prompt
echo '[ Wipe 1/5 ] Annex module wiped.'
echo ''

echo '[ Wipe 2/5 ] Wiping node module...'
echo 'yes' | bash "$REPO_DIR/4_node/2_wipe.sh"     # pipe 'yes' to skip confirmation prompt
echo '[ Wipe 2/5 ] Node module wiped.'
echo ''

echo '[ Wipe 3/5 ] Wiping shell module...'
echo 'yes' | bash "$REPO_DIR/3_shell/2_wipe.sh"    # pipe 'yes' to skip confirmation prompt
echo '[ Wipe 3/5 ] Shell module wiped.'
echo ''

echo '[ Wipe 4/5 ] Wiping vscode module...'
echo 'yes' | bash "$REPO_DIR/2_vscode/2_wipe.sh"   # pipe 'yes' to skip confirmation prompt
echo '[ Wipe 4/5 ] VS Code module wiped.'
echo ''

echo '[ Wipe 5/5 ] Wiping conda module...'
echo 'yes' | bash "$REPO_DIR/1_conda/2_wipe.sh"    # pipe 'yes' to skip confirmation prompt
echo '[ Wipe 5/5 ] Conda module wiped.'
echo ''

# ── Deploy all modules in dependency order ────────────────────────────────────
echo '================================================'
echo '  Phase 2: Deploying all modules'
echo '================================================'
echo ''

echo '[ Deploy 1/5 ] Running conda module setup and deploy...'
echo ''

bash "$REPO_DIR/1_conda/0_setup.sh"    # run conda prerequisites
bash "$REPO_DIR/1_conda/3_deploy.sh"   # install Miniforge and configure conda-forge

echo ''
echo '[ Deploy 1/5 ] Conda module complete.'
echo ''

echo '[ Deploy 2/5 ] Running vscode module setup and deploy...'
echo ''

bash "$REPO_DIR/2_vscode/0_setup.sh"                              # run vscode prerequisites
bash "$REPO_DIR/2_vscode/3_deploy.sh" "$DOTFILES_FIRST_PROJECT"  # install extensions and settings

echo ''
echo '[ Deploy 2/5 ] VS Code module complete.'
echo ''

echo '[ Deploy 3/5 ] Running shell module setup and deploy...'
echo ''

bash "$REPO_DIR/3_shell/0_setup.sh"    # run shell prerequisites
bash "$REPO_DIR/3_shell/3_deploy.sh"   # deploy shell config to ~/.bashrc

echo ''
echo '[ Deploy 3/5 ] Shell module complete.'
echo ''

echo '[ Deploy 4/5 ] Running node module setup and deploy...'
echo ''

bash "$REPO_DIR/4_node/0_setup.sh"    # run node prerequisites
bash "$REPO_DIR/4_node/3_deploy.sh"   # install Node.js, npm, and Claude Code

echo ''
echo '[ Deploy 4/5 ] Node module complete.'
echo ''

echo '[ Deploy 5/5 ] Running annex module setup and deploy...'
echo ''

bash "$REPO_DIR/5_annex/0_setup.sh"    # install git-annex
bash "$REPO_DIR/5_annex/3_deploy.sh"   # set global annex config

echo ''
echo '[ Deploy 5/5 ] Annex module complete.'
echo ''

# ── Run all module tests ──────────────────────────────────────────────────────
echo '================================================'
echo '  Phase 3: Verifying all modules'
echo '================================================'
echo ''

# Disable set -e for test section so one failure does not stop remaining tests
set +e

TESTS_PASSED=true    # track overall test result

bash "$REPO_DIR/1_conda/4_test.sh"
[[ $? -ne 0 ]] && TESTS_PASSED=false    # record failure if conda test fails
echo ''

bash "$REPO_DIR/2_vscode/4_test.sh"
[[ $? -ne 0 ]] && TESTS_PASSED=false    # record failure if vscode test fails
echo ''

bash "$REPO_DIR/3_shell/4_test.sh"
[[ $? -ne 0 ]] && TESTS_PASSED=false    # record failure if shell test fails
echo ''

bash "$REPO_DIR/4_node/4_test.sh"
[[ $? -ne 0 ]] && TESTS_PASSED=false    # record failure if node test fails
echo ''

bash "$REPO_DIR/5_annex/4_test.sh"
[[ $? -ne 0 ]] && TESTS_PASSED=false    # record failure if annex test fails
echo ''

# ── Final summary ─────────────────────────────────────────────────────────────
echo '================================================'
if [[ "$TESTS_PASSED" == true ]]; then
    echo '  Bootstrap complete. ALL TESTS PASSED.'
    echo ''
    echo '  Open a new terminal or restart VS Code'
    echo '  then run: source ~/.bashrc'
else
    echo '  Bootstrap complete. SOME TESTS FAILED.'
    echo ''
    echo '  Review the failures above and run the'
    echo '  relevant module scripts to fix them.'
fi
echo '================================================'
