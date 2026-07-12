#!/usr/bin/env bash
# 3_deploy.sh - Configure git-annex from the repo
#
# Usage:
#   ./3_deploy.sh
#
# What it does:
#   - Verifies git-annex is installed (0_setup.sh installs it)
#   - Sets the global git-annex config this module owns
#
# Idempotent - safe to run repeatedly.
#
# What this deliberately does NOT do:
#   It does not create, wire, or point any backup remote at any path. A remote is a
#   property of a corpus on a machine, not of the machine itself: on ENIAC it is a local
#   folder, on the recology laptop it is the client's OneDrive, on a locked-down client
#   it may be an external disk. That wiring belongs to the grid (linter connect-intake),
#   which knows which workspace it is wiring and can be re-pointed with
#   `git annex enableremote <name> directory=<path>` when a corpus moves machines.
#   Dotfiles installs the tool. The grid decides where the bytes go.

set -e  # exit immediately if any command fails

echo '=== Annex Deploy ==='

# 1. Verify git-annex is installed
echo ''
echo '[1/2] Verifying git-annex...'

if ! command -v git-annex &> /dev/null; then    # 0_setup.sh is responsible for installing it
    echo '      ERROR: git-annex not installed. Run 0_setup.sh first.'
    exit 1
fi

echo "      git-annex is installed: $(git-annex version | head -1)"

# 2. Set the global annex config
echo ''
echo '[2/2] Setting global annex config...'

# annex.largefiles is deliberately NOT set globally. A git config value for it OVERRIDES
# the repo's own .gitattributes - verified live on 2026-07-12, where a global
# `annex.largefiles=nothing` silently un-annexed the intake L0 tier and sent raw client
# artifacts into the git object store despite .gitattributes saying otherwise. Which files
# annex is a property of the corpus, and only the corpus may declare it.
git config --global --unset annex.largefiles 2>/dev/null || true    # clear any prior value
echo '      annex.largefiles: unset globally (a corpus decides via its own .gitattributes)'

# Never let annex commit on our behalf. Every commit on this grid goes through herald's
# commit gate, where a human reads the diff first.
git config --global annex.autocommit 'false'
echo '      annex.autocommit=false (herald owns commit/push)'

echo ''
echo '=== Deploy complete. Run 4_test.sh to verify. ==='
