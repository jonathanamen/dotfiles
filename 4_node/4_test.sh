#!/usr/bin/env bash
# 4_test.sh - Validate node module state and report pass/fail
#
# Usage:
#   ./4_test.sh
#
# What it does:
#   - Verifies Node.js is installed and meets minimum version requirement
#   - Verifies npm is installed
#   - Verifies Claude Code is installed and accessible
#   - Reports pass/fail for each check with a final summary
#
# Non-destructive - this script never changes anything.

# Note: set -e intentionally omitted - test scripts must run all checks
# and report results rather than exiting on the first failure.

PASS=0
FAIL=0
NODE_MIN_MAJOR=18    # minimum required Node.js major version

echo '=== Node Module Test ==='

pass() {
    echo "      PASS: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "      FAIL: $1"
    FAIL=$((FAIL + 1))
}

# 1. Check Node.js is installed and meets minimum version
echo ''
echo '[1/3] Checking Node.js...'

if command -v node &> /dev/null; then
    NODE_VER=$(node --version)
    NODE_MAJOR=$(node --version | sed 's/v//' | cut -d. -f1)
    if [[ "$NODE_MAJOR" -ge "$NODE_MIN_MAJOR" ]]; then
        pass "Node.js is installed: $NODE_VER (>= v${NODE_MIN_MAJOR} required)"
    else
        fail "Node.js version too old: $NODE_VER (v${NODE_MIN_MAJOR}+ required) — run 2_wipe.sh then 3_deploy.sh"
    fi
else
    fail 'Node.js not found — run 3_deploy.sh'
fi

# 2. Check npm is installed
echo ''
echo '[2/3] Checking npm...'

if command -v npm &> /dev/null; then
    NPM_VER=$(npm --version)
    pass "npm is installed: v$NPM_VER"
else
    fail 'npm not found — run 3_deploy.sh'
fi

# 3. Check Claude Code is installed
echo ''
echo '[3/3] Checking Claude Code...'

if command -v claude &> /dev/null; then
    CLAUDE_VER=$(claude --version 2>/dev/null || echo 'installed')
    pass "Claude Code is installed: $CLAUDE_VER"
else
    fail 'Claude Code not found — run 3_deploy.sh'
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
