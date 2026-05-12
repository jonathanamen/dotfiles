#!/usr/bin/env bash
# 1_save.sh - Snapshot current shell config to this repo
#
# Usage:
#   ./1_save.sh
#
# What it does:
#   - Copies ~/.bashrc to config/.bashrc in this repo
#
# Run this whenever you update your shell config and want to save the state.

set -e  # exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to this script's directory
CONFIG_DIR="$REPO_DIR/config"                                # path to config folder

echo '=== Shell Save ==='

echo ''
echo '[1/1] Saving ~/.bashrc...'

mkdir -p "$CONFIG_DIR"    # create config folder if it does not exist
cp "$HOME/.bashrc" "$CONFIG_DIR/.bashrc"    # copy live .bashrc to repo

echo '      Saved config/.bashrc.'

echo ''
echo '=== Save complete. Review and commit your changes: ==='
echo ''
echo '    git status'
echo '    git add -A'
echo "    git commit -m 'chore: snapshot shell config'"
echo '    git push'
