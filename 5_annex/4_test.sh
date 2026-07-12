#!/usr/bin/env bash
# 4_test.sh - Validate annex module state and report pass/fail
#
# Usage:
#   ./4_test.sh
#
# What it does:
#   - Verifies git-annex is installed and meets the minimum version
#   - Verifies the global annex config this module owns is set correctly
#   - Reports pass/fail for each check with a final summary
#
# Non-destructive - this script never changes anything.

# Note: set -e intentionally omitted - test scripts must run all checks
# and report results rather than exiting on the first failure.

PASS=0
FAIL=0
ANNEX_MIN_MAJOR=8    # minimum git-annex major version (v8 added the v8 repo format)

echo '=== Annex Module Test ==='

pass() {
    echo "      PASS: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "      FAIL: $1"
    FAIL=$((FAIL + 1))
}

# 1. Check git-annex is installed and meets minimum version
echo ''
echo '[1/3] Checking git-annex...'

if command -v git-annex &> /dev/null; then
    ANNEX_VER=$(git-annex version | head -1 | sed 's/git-annex version: //')    # e.g. 10.20251029
    ANNEX_MAJOR=$(echo "$ANNEX_VER" | cut -d. -f1)                              # e.g. 10
    if [[ "$ANNEX_MAJOR" -ge "$ANNEX_MIN_MAJOR" ]]; then
        pass "git-annex is installed: $ANNEX_VER (>= v${ANNEX_MIN_MAJOR} required)"
    else
        fail "git-annex version too old: $ANNEX_VER (v${ANNEX_MIN_MAJOR}+ required) - run 0_setup.sh"
    fi
else
    fail 'git-annex not found - run 0_setup.sh'
fi

# 2. Check annex.largefiles is NOT set globally
echo ''
echo '[2/3] Checking annex.largefiles is unset...'

LARGEFILES=$(git config --global --get annex.largefiles || true)

# A global value overrides the repo's .gitattributes, which silently un-annexes a corpus
# that asked for annexing. Unset is the only correct state - the corpus decides.
if [[ -z "$LARGEFILES" ]]; then
    pass 'annex.largefiles is unset globally (a corpus decides via its own .gitattributes)'
else
    fail "annex.largefiles is set to '$LARGEFILES' globally - it overrides .gitattributes and will un-annex corpora. Run 3_deploy.sh"
fi

# 3. Check autocommit is off
echo ''
echo '[3/3] Checking annex.autocommit...'

AUTOCOMMIT=$(git config --global --get annex.autocommit || true)

if [[ "$AUTOCOMMIT" == 'false' ]]; then
    pass 'annex.autocommit=false (herald owns commit/push)'
else
    fail "annex.autocommit is '${AUTOCOMMIT:-unset}', expected 'false' - run 3_deploy.sh"
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
