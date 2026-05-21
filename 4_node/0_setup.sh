#!/usr/bin/env bash
# 0_setup.sh - Check prerequisites for the node module
#
# Usage:
#   ./0_setup.sh
#
# What it does:
#   - Verifies apt is available
#   - Verifies internet connectivity
#   - Verifies script is not running as root
#
# Do NOT run with sudo.

set -e

echo '=== Node Setup ==='

# Check not running as root
if [[ "$EUID" -eq 0 ]]; then
    echo 'ERROR: Do not run this script as root or with sudo.'
    exit 1
fi

# Check apt is available
echo ''
echo '[1/2] Checking apt...'

if ! command -v apt &> /dev/null; then
    echo 'ERROR: apt not found. This module requires a Debian/Ubuntu system.'
    exit 1
fi

echo '      apt is available.'

# Check internet connectivity
echo ''
echo '[2/2] Checking internet connectivity...'

if ! curl -s --max-time 5 https://registry.npmjs.org > /dev/null; then
    echo 'ERROR: Cannot reach npmjs.org. Check your internet connection.'
    exit 1
fi

echo '      Internet connectivity confirmed.'

echo ''
echo '=== Setup complete. ==='
