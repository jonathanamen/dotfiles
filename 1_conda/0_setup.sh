#!/usr/bin/env bash
# 0_setup.sh — One-time prerequisites for the conda module
#
# Run this once on a fresh machine before running 3_deploy.sh.
# Safe to run multiple times — checks before installing.
#
# What it does:
#   - Verifies wget is available for downloading the installer
#   - Verifies bash version is 5 or higher
#   - Verifies we are NOT running as root (sudo breaks conda on WSL)
#
# Note: Do NOT run this script with sudo. Conda must be installed as your
# normal user or it will not be accessible without sudo -i.

set -e  # exit immediately if any command fails

echo '=== Conda Module Setup ==='

# ── 1. Check not running as root ──────────────────────────────────────────────
echo ''
echo '[1/3] Checking user context...'

if [[ "$EUID" -eq 0 ]]; then     # EUID is the effective user ID — 0 means root
    echo '      ERROR: Do not run this script as root or with sudo.'
    echo '      Conda installed as root will not be accessible as your normal user.'
    echo '      Run as your normal user: ./0_setup.sh'
    exit 1
fi

echo "      Running as user: $USER — OK."

# ── 2. Check wget is available ────────────────────────────────────────────────
echo ''
echo '[2/3] Checking wget is available...'

if ! command -v wget &> /dev/null; then    # check if wget exists in PATH
    echo '      wget not found. Installing...'
    sudo apt update && sudo apt install -y wget    # install wget via apt
fi

echo '      wget is available.'

# ── 3. Check bash version ─────────────────────────────────────────────────────
echo ''
echo '[3/3] Checking bash version...'

BASH_VER=$(bash --version | head -1)                           # get full bash version string
BASH_MAJOR=$(echo "$BASH_VER" | grep -oP '\d+' | head -1)     # extract major version number

if [[ "$BASH_MAJOR" -ge 5 ]]; then    # verify bash 5 or higher
    echo "      Bash version OK: $BASH_VER"
else
    echo "      WARNING: Bash version is $BASH_MAJOR — version 5 or higher recommended."
    echo '      Run: sudo apt upgrade bash'
fi

echo ''
echo '=== Setup complete. You are ready to run 3_deploy.sh ==='
