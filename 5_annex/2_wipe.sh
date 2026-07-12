#!/usr/bin/env bash
# 2_wipe.sh - Remove git-annex and the global annex git config
#
# Usage:
#   ./2_wipe.sh
#
# What it does:
#   - Removes the global git-annex settings this module manages
#   - Removes git-annex via apt
#
# Run 3_deploy.sh after this to reinstall from scratch.
#
# SAFETY: this never touches a repository's annexed content, its .git/annex directory,
# or any backup remote. Uninstalling the tool does not destroy the data - the L0 audit
# tier is evidence, and nothing in this repo is allowed to delete it. Reinstalling
# git-annex and running `git annex get` restores full access.

set -e  # exit immediately if any command fails

echo '=== Annex Wipe ==='

# Confirm before wiping unless piped 'yes'
if [ -t 0 ]; then    # only prompt if running interactively
    read -p 'This will remove git-annex (annexed content is NOT touched). Continue? [y/N] ' CONFIRM
    if [[ "$CONFIRM" != 'y' && "$CONFIRM" != 'Y' ]]; then
        echo 'Aborted.'
        exit 0
    fi
fi

# 1. Remove the global annex git config keys
echo ''
echo '[1/2] Removing global annex git config...'

for KEY in annex.largefiles annex.autocommit annex.synccontent; do    # incl. largefiles: clear it if an older deploy set it
    if git config --global --get "$KEY" &> /dev/null; then
        git config --global --unset "$KEY"    # remove only the keys this module owns
        echo "      Unset: $KEY"
    fi
done

echo '      Global annex config cleared.'

# 2. Remove git-annex
echo ''
echo '[2/2] Removing git-annex...'

if command -v git-annex &> /dev/null; then
    sudo apt remove -y git-annex    # remove the package, leave content alone
    sudo apt autoremove -y
    echo '      git-annex removed.'
else
    echo '      git-annex not installed - skipping.'
fi

echo ''
echo '=== Wipe complete. ==='
echo 'Annexed content was NOT removed. Run 0_setup.sh then 3_deploy.sh to reinstall.'
