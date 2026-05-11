#!/usr/bin/env bash
# 0_setup.sh - One-time prerequisites for the shell module
#
# Run this once on a fresh machine before running 3_deploy.sh.
# Safe to run multiple times - checks before installing.
#
# What it does:
#   - Verifies bash is the default shell
#   - Verifies ~/.bashrc exists
#   - Backs up existing ~/.bashrc before any changes

set -e  # exit immediately if any command fails

echo '=== Shell Module Setup ==='

# 1. Check bash is the default shell
echo ''
echo '[1/3] Checking default shell...'

if [[ "$SHELL" != */bash ]]; then    # verify SHELL environment variable ends in bash
    echo "      WARNING: Default shell is $SHELL - expected bash."
    echo '      Run: chsh -s $(which bash)'
else
    echo '      Default shell is bash - OK.'
fi

# 2. Check ~/.bashrc exists
echo ''
echo '[2/3] Checking ~/.bashrc exists...'

if [[ ! -f "$HOME/.bashrc" ]]; then    # check if .bashrc file exists
    echo '      ~/.bashrc not found. Creating empty file...'
    touch "$HOME/.bashrc"              # create empty .bashrc if missing
fi

echo '      ~/.bashrc exists - OK.'

# 3. Back up existing ~/.bashrc
echo ''
echo '[3/3] Backing up ~/.bashrc...'

BACKUP="$HOME/.bashrc.bak.$(date +%Y%m%d%H%M%S)"    # timestamped backup filename
cp "$HOME/.bashrc" "$BACKUP"                           # copy current .bashrc to backup
echo "      Backed up to: $BACKUP"

echo ''
echo '=== Setup complete. You are ready to run 3_deploy.sh ==='
