#!/usr/bin/env bash
# 3_deploy.sh - Install Node.js, npm, and Claude Code
#
# Usage:
#   ./3_deploy.sh
#
# What it does:
#   - Installs Node.js and npm via apt
#   - Installs Claude Code globally via npm
#
# Why Claude Code is here:
#   Claude Code is Anthropic's agentic coding CLI and VS Code extension.
#   It reads CLAUDE.md at repo root on every session start, giving it
#   standing context, allowed paths, and working conventions without
#   re-explaining every session. It is part of the standard IDE.
#
# Do NOT run with sudo for the npm global install — sudo causes permission
# issues with npm global packages. Node and npm themselves require sudo
# via apt, which is expected.

set -e

echo '=== Node Deploy ==='

# Check not running as root
if [[ "$EUID" -eq 0 ]]; then
    echo 'ERROR: Do not run this script as root or with sudo.'
    exit 1
fi

# 1. Install Node.js and npm
echo ''
echo '[1/2] Installing Node.js and npm...'

if command -v node &> /dev/null && command -v npm &> /dev/null; then
    NODE_VER=$(node --version)
    NPM_VER=$(npm --version)
    echo "      Node.js already installed: $NODE_VER"
    echo "      npm already installed: $NPM_VER"
    echo '      Skipping — run 2_wipe.sh first to reinstall.'
else
    sudo apt update -q
    sudo apt install -y nodejs npm
    NODE_VER=$(node --version)
    NPM_VER=$(npm --version)
    echo "      Node.js installed: $NODE_VER"
    echo "      npm installed: $NPM_VER"
fi

# 2. Install Claude Code globally
echo ''
echo '[2/2] Installing Claude Code...'

if command -v claude &> /dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null || echo 'unknown')
    echo "      Claude Code already installed: $CLAUDE_VER"
    echo '      Skipping — run 2_wipe.sh first to reinstall.'
else
    sudo npm install -g @anthropic-ai/claude-code
    CLAUDE_VER=$(claude --version 2>/dev/null || echo 'installed')
    echo "      Claude Code installed: $CLAUDE_VER"
fi

echo ''
echo '=== Deploy complete. ==='
echo 'Run "claude" from inside any repo directory to start a session.'
echo 'Install the Claude Code VS Code extension for the sidebar panel experience.'
