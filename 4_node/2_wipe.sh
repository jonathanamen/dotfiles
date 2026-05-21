#!/usr/bin/env bash
# 2_wipe.sh - Remove Node.js, npm, and Claude Code
#
# Usage:
#   ./2_wipe.sh
#
# What it does:
#   - Removes Claude Code global npm package
#   - Removes Node.js and npm via apt
#   - Cleans up npm cache
#
# Run 3_deploy.sh after this to reinstall from scratch.

set -e

echo '=== Node Wipe ==='

# Confirm before wiping unless piped 'yes'
if [ -t 0 ]; then    # only prompt if running interactively
    read -p 'This will remove Node.js, npm, and Claude Code. Continue? [y/N] ' CONFIRM
    if [[ "$CONFIRM" != 'y' && "$CONFIRM" != 'Y' ]]; then
        echo 'Aborted.'
        exit 0
    fi
fi

# 1. Remove Claude Code
echo ''
echo '[1/3] Removing Claude Code...'

if command -v claude &> /dev/null; then
    sudo npm uninstall -g @anthropic-ai/claude-code
    echo '      Claude Code removed.'
else
    echo '      Claude Code not installed — skipping.'
fi

# 2. Remove Node.js and npm
echo ''
echo '[2/3] Removing Node.js and npm...'

if command -v node &> /dev/null || command -v npm &> /dev/null; then
    sudo apt remove -y nodejs npm
    sudo apt autoremove -y
    echo '      Node.js and npm removed.'
else
    echo '      Node.js and npm not installed — skipping.'
fi

# 3. Clean npm cache
echo ''
echo '[3/3] Cleaning npm cache...'

if [[ -d "$HOME/.npm" ]]; then
    rm -rf "$HOME/.npm"
    echo '      npm cache cleared.'
else
    echo '      npm cache not found — skipping.'
fi

echo ''
echo '=== Wipe complete. ==='
echo 'Run 3_deploy.sh to reinstall.'
