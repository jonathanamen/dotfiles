#!/usr/bin/env bash
# 4_test.sh - Validate conda module state and report pass/fail
#
# Usage:
#   ./4_test.sh
#
# What it does:
#   - Verifies Miniconda is installed at $HOME/miniconda3
#   - Verifies conda command is accessible
#   - Verifies Python is accessible via conda
#   - Verifies all expected environments exist (from environments/*.yml)
#   - Reports pass/fail for each check with a final summary
#
# Non-destructive - this script never changes anything.

# Note: set -e is intentionally omitted - test scripts must run all checks
# and report results rather than exiting on the first failure.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVIRONMENTS_DIR="$REPO_DIR/environments"
MINICONDA_DIR="$HOME/miniconda3"
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

# 1. Check Miniconda directory exists
echo ''
echo '[1/4] Checking Miniconda installation...'

if [[ -d "$MINICONDA_DIR" ]]; then
    pass "Miniconda directory exists at $MINICONDA_DIR"
else
    fail "Miniconda directory not found at $MINICONDA_DIR - run 3_deploy.sh"
fi

# 2. Check conda command is accessible
echo ''
echo '[2/4] Checking conda command...'

if command -v conda &> /dev/null; then
    CONDA_VER=$(conda --version)
    pass "conda is accessible: $CONDA_VER"
else
    if [[ -f "$MINICONDA_DIR/bin/conda" ]]; then
        pass 'conda binary exists - run source ~/.bashrc to activate in current shell'
    else
        fail 'conda command not found - run 3_deploy.sh'
    fi
fi

# 3. Check Python is accessible via conda
echo ''
echo '[3/4] Checking Python...'

PYTHON_PATH="$MINICONDA_DIR/bin/python"

if [[ -f "$PYTHON_PATH" ]]; then
    PYTHON_VER=$("$PYTHON_PATH" --version)
    pass "Python is accessible: $PYTHON_VER"
else
    fail 'Python not found in Miniconda - run 3_deploy.sh'
fi

# 4. Check all expected environments exist
echo ''
echo '[4/4] Checking environments...'

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
