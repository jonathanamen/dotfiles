#!/usr/bin/env bash
# 1_save.sh - Snapshot the current git-annex configuration to the repo
#
# Usage:
#   ./1_save.sh
#
# What it does:
#   - Records the installed git-annex version to config/version.txt
#   - Records the global git-annex settings this module manages to config/gitconfig.annex
#
# Non-destructive to the machine - only writes into this repo.
#
# Note: annex REMOTES are deliberately not saved here. A remote's directory path is
# machine-local and confidential by nature - the recology laptop points at the client's
# OneDrive, ENIAC points at a local folder - and git-annex already stores remote
# metadata in the repo's own git-annex branch. Committing a path here would leak a
# client's storage layout into a public dotfiles repo.

set -e  # exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to this module
CONFIG_DIR="$REPO_DIR/config"                                # where snapshots land

echo '=== Annex Save ==='

if ! command -v git-annex &> /dev/null; then    # nothing to snapshot if not installed
    echo '      ERROR: git-annex not installed. Run 0_setup.sh first.'
    exit 1
fi

mkdir -p "$CONFIG_DIR"    # create config dir on first save

# 1. Record installed version
echo ''
echo '[1/2] Saving git-annex version...'

git-annex version | head -1 > "$CONFIG_DIR/version.txt"    # first line carries the version
echo "      Saved: $(cat "$CONFIG_DIR/version.txt")"

# 2. Record the global git config keys this module manages
echo ''
echo '[2/2] Saving global annex git config...'

: > "$CONFIG_DIR/gitconfig.annex"    # truncate, then append each managed key if set

for KEY in annex.autocommit annex.synccontent; do    # keys 3_deploy.sh sets (never largefiles)
    VALUE=$(git config --global --get "$KEY" || true)    # empty if unset
    if [[ -n "$VALUE" ]]; then
        echo "$KEY=$VALUE" >> "$CONFIG_DIR/gitconfig.annex"
    fi
done

echo "      Saved $(wc -l < "$CONFIG_DIR/gitconfig.annex") global annex setting(s)."

echo ''
echo '=== Save complete. Commit the changes to persist them. ==='
