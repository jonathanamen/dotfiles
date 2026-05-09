#!/usr/bin/env bash
# 1_save.sh - Snapshot current conda environments to this repo
#
# Usage:
#   ./1_save.sh
#
# What it does:
#   - Exports all named conda environments to environments/ as .yml files
#   - Skips the base environment - base is rebuilt by 3_deploy.sh automatically
#   - Each environment gets its own file: environments/<name>.yml
#
# Run this whenever you add packages to an environment and want to save the state.

set -e  # exit immediately if any command fails

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"    # absolute path to this script's directory
ENVIRONMENTS_DIR="$REPO_DIR/environments"                    # path to environments folder

echo '=== Conda Save ==='

# Check conda is available
if ! command -v conda &> /dev/null; then    # verify conda is installed and in PATH
    echo 'ERROR: conda not found. Run 3_deploy.sh first.'
    exit 1
fi

echo ''
echo '[1/1] Exporting conda environments...'

mkdir -p "$ENVIRONMENTS_DIR"    # create environments folder if it does not exist

# Get list of all named environments - skip base, comments, and blank lines
ENVS=$(conda env list | grep -v '^#' | grep -v '^base' | grep -v '^$' | awk '{print $1}')

if [[ -z "$ENVS" ]]; then    # check if any named environments exist
    echo '      No named environments found - nothing to save.'
    echo '      Base environment is always rebuilt from scratch by 3_deploy.sh.'
else
    while IFS= read -r env; do
        [[ -z "$env" ]] && continue    # skip blank lines
        echo "      Exporting: $env"
        conda env export -n "$env" > "$ENVIRONMENTS_DIR/$env.yml"    # export to yml file
        echo "      Saved: environments/$env.yml"
    done <<< "$ENVS"
fi

echo ''
echo '=== Save complete. Review and commit your changes: ==='
echo ''
echo '    git diff'
echo '    git add -A'
echo "    git commit -m 'chore: snapshot conda environments'"
echo '    git push'
