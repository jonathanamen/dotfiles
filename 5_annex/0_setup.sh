#!/usr/bin/env bash
# 0_setup.sh - One-time prerequisites for the annex module
#
# Run this once on a fresh machine before running 3_deploy.sh.
# Safe to run multiple times - checks before installing.
#
# What it does:
#   - Verifies we are NOT running as root
#   - Installs git-annex via apt if it is not already present
#   - Verifies git is available (git-annex is useless without it)
#
# Why git-annex?
#   The TDBI intake stack stores raw artifacts in an L0 audit tier that is immutable,
#   hashed at ingest, and never deleted. Committing those bytes to git directly would
#   keep every version of every binary forever, and GitHub caps a single file at 100MB.
#   git-annex keeps the content outside the git object store: git holds a symlink, the
#   hash, and the provenance; the bytes live in a backend of our choosing, including a
#   plain local directory. That satisfies the zero-procurement rule - the stack has to
#   stand up inside a client company with no cloud account and no vendor contract.
#
# Note: this needs sudo for the apt install. That is the only privileged step.

set -e  # exit immediately if any command fails

echo '=== Annex Module Setup ==='

# 1. Check not running as root
echo ''
echo '[1/3] Checking user context...'

if [[ "$EUID" -eq 0 ]]; then    # EUID is the effective user ID - 0 means root
    echo '      ERROR: Do not run this script as root or with sudo.'
    echo '      Run as your normal user: ./0_setup.sh'
    exit 1
fi

echo "      Running as user: $USER - OK."

# 2. Check git is available
echo ''
echo '[2/3] Checking git is available...'

if ! command -v git &> /dev/null; then    # git-annex is a git extension, git must exist first
    echo '      ERROR: git not found. Install git before running this module.'
    exit 1
fi

echo "      git is available: $(git --version)"

# 3. Install git-annex
echo ''
echo '[3/3] Checking git-annex...'

if command -v git-annex &> /dev/null; then    # already installed, nothing to do
    echo "      git-annex already installed: $(git-annex version | head -1)"
else
    echo '      git-annex not found. Installing (requires sudo)...'
    sudo apt update && sudo apt install -y git-annex    # install git-annex via apt
    echo "      git-annex installed: $(git-annex version | head -1)"
fi

echo ''
echo '=== Setup complete. You are ready to run 3_deploy.sh ==='
