#!/usr/bin/env bash
# 0_setup.sh — One-time prerequisites for the VS Code module
#
# Run this once on a fresh machine before running 3_deploy.sh.
# Safe to run multiple times — checks before installing.
#
# What it does:
#   - Verifies VS Code is installed and accessible from WSL
#   - Verifies code command is available in PATH
#   - Verifies bash version is 5 or higher

set -e  # exit immediately if any command fails

echo '=== VS Code Module Setup ==='

# ── 1. Check VS Code is accessible ───────────────────────────────────────────
echo ''
echo '[1/2] Checking VS Code is accessible from WSL...'

if ! command -v code &> /dev/null; then          # check if 'code' command exists in PATH
    echo '      ERROR: VS Code is not accessible from WSL.'
    echo '      Make sure VS Code is installed on Windows with "Add to PATH" checked.'
    echo '      Then open VS Code from WSL with: code .'
    echo '      This installs the VS Code server into WSL automatically.'
    exit 1
fi

echo '      VS Code is accessible.'

# ── 2. Check bash version ─────────────────────────────────────────────────────
echo ''
echo '[2/2] Checking bash version...'

BASH_VER=$(bash --version | head -1)                              # get full bash version string
BASH_MAJOR=$(echo "$BASH_VER" | grep -oP '\d+' | head -1)        # extract major version number

if [[ "$BASH_MAJOR" -ge 5 ]]; then       # verify bash 5 or higher
    echo "      Bash version OK: $BASH_VER"
else
    echo "      WARNING: Bash version is $BASH_MAJOR — version 5 or higher recommended."
    echo '      Run: sudo apt upgrade bash'
fi

echo ''
echo '=== Setup complete. You are ready to run 3_deploy.sh ==='
