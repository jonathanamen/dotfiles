#!/usr/bin/env bash
# 4_test.sh - Validate conda module state and report pass/fail
#
# Usage:
#   ./4_test.sh
#
# What it does:
#   - Verifies Miniforge is installed at $HOME/miniforge3
#   - Verifies conda command is accessible
#   - Verifies Python is accessible via conda
#   - Verifies conda-forge is the only channel (no Anaconda defaults)
#   - Verifies all expected environments exist (from environments/*.yml)
#   - Reports pass/fail for each check with a final summary
#
# Non-destructive - this script never changes anything.

# Note: set -e is intentionally omitted - test scripts must run all checks
# and report results rather than exiting on the first failure.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENTS_DIR="$REPO_DIR/environments"
MINIFORGE_DIR="$HOME/miniforge3"
PASS=0
FAIL=0

echo '=== Conda Module Test ==='

pass() {
    echo "      PASS: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "      FAIL: $1"
    FAIL=$((FAIL + 1))
}

# 1. Check Miniforge directory exists
echo ''
echo '[1/6] Checking Miniforge installation...'

if [[ -d "$MINIFORGE_DIR" ]]; then
    pass "Miniforge directory exists at $MINIFORGE_DIR"
else
    fail "Miniforge directory not found at $MINIFORGE_DIR - run 3_deploy.sh"
fi

# 2. Check conda command is accessible
echo ''
echo '[2/6] Checking conda command...'

if command -v conda &> /dev/null; then
    CONDA_VER=$(conda --version)
    pass "conda is accessible: $CONDA_VER"
else
    if [[ -f "$MINIFORGE_DIR/bin/conda" ]]; then
        pass 'conda binary exists - run source ~/.bashrc to activate in current shell'
    else
        fail 'conda command not found - run 3_deploy.sh'
    fi
fi

# 3. Check Python is accessible via conda
echo ''
echo '[3/6] Checking Python...'

PYTHON_PATH="$MINIFORGE_DIR/bin/python"

if [[ -f "$PYTHON_PATH" ]]; then
    PYTHON_VER=$("$PYTHON_PATH" --version)
    pass "Python is accessible: $PYTHON_VER"
else
    fail 'Python not found in Miniforge - run 3_deploy.sh'
fi

# 4. Verify conda-forge is the only channel
echo ''
echo '[4/6] Checking channel configuration...'

if command -v conda &> /dev/null; then
    CHANNELS=$(conda config --show channels 2>/dev/null)
    if echo "$CHANNELS" | grep -q 'defaults'; then    # fail if Anaconda defaults is present
        fail 'Anaconda defaults channel detected - run 3_deploy.sh to reinstall with Miniforge'
    else
        pass 'conda-forge is the only channel - no Anaconda defaults'
    fi
else
    echo '      Skipping channel check - conda not accessible'
fi

# 5. Check all expected environments exist
echo ''
echo '[5/6] Checking environments...'

YML_COUNT=$(ls "$ENVIRONMENTS_DIR"/*.yml 2>/dev/null | wc -l)

if [[ "$YML_COUNT" -eq 0 ]]; then
    echo '      No environment definitions found - skipping environment checks.'
    PASS=$((PASS + 1))
else
    for yml in "$ENVIRONMENTS_DIR"/*.yml; do
        ENV_NAME=$(basename "$yml" .yml)
        if conda env list 2>/dev/null | grep -q "^$ENV_NAME"; then
            pass "Environment exists: $ENV_NAME"
        else
            fail "Environment missing: $ENV_NAME - run 3_deploy.sh"
        fi
    done
fi

# 6. Check base-environment packages import
#
# The TDBI grid runs on the base python, and librarian retrieval imports these. Without this
# check a fresh machine looks healthy and then fails at the first search with an ImportError.
echo ''
echo '[6/6] Checking base-environment packages...'

BASE_PACKAGES="$REPO_DIR/base-packages.txt"

if [[ ! -f "$BASE_PACKAGES" ]]; then
    echo '      No base-packages.txt - skipping.'
    PASS=$((PASS + 1))
else
    # Read the LIST rather than naming packages here. The hardcoded pair this replaces checked
    # fastembed and sqlite_vec only, so flask sat in the file untested -- and flask was added
    # precisely because the harness had imported it for months with nothing installing it. A test
    # that has to be edited every time the list changes is a test that goes stale silently.
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"                          # strip trailing comments
        line="$(echo "$line" | tr -d '[:space:]')"  # strip all whitespace
        [[ -z "$line" ]] && continue

        package="${line%%[><=!]*}"    # "fastembed>=0.8.0" -> "fastembed"
        module="${package//-/_}"      # the import name: sqlite-vec -> sqlite_vec

        if "$MINIFORGE_DIR/bin/python3" -c "import $module" 2>/dev/null; then
            pass "$module importable"
        else
            fail "$module not importable - run 3_deploy.sh"
        fi
    done < "$BASE_PACKAGES"
fi

echo ''
echo '================================'
echo "  PASSED: $PASS"
echo "  FAILED: $FAIL"
echo '================================'

if [[ "$FAIL" -eq 0 ]]; then
    echo '  RESULT: ALL TESTS PASSED'
    exit 0
else
    echo '  RESULT: SOME TESTS FAILED'
    exit 1
fi
