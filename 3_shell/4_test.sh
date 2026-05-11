#!/usr/bin/env bash
# 4_test.sh - Validate shell module state and report pass/fail
#
# Usage:
#   ./4_test.sh
#
# What it does:
#   - Verifies bash is the default shell
#   - Verifies the dotfiles shell config block is present in ~/.bashrc
#   - Verifies key aliases are defined in ~/.bashrc
#   - Verifies key environment variables are set
#   - Reports pass/fail for each check with a final summary
#
# Non-destructive - this script never changes anything.
#
# Note: Aliases are checked in ~/.bashrc not in the active shell because
# aliases do not export to subshells in bash - checking the file is more
# reliable and tests what is actually deployed.

# Note: set -e is intentionally omitted - test scripts must run all checks
# and report results rather than exiting on the first failure.

PASS=0
FAIL=0

echo '=== Shell Module Test ==='

pass() {
    echo "      PASS: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "      FAIL: $1"
    FAIL=$((FAIL + 1))
}

# 1. Check bash is the default shell
echo ''
echo '[1/4] Checking default shell...'

if [[ "$SHELL" == */bash ]]; then    # verify SHELL ends in bash
    pass 'Default shell is bash'
else
    fail "Default shell is $SHELL - expected bash"
fi

# 2. Check dotfiles block is in ~/.bashrc
echo ''
echo '[2/4] Checking shell config is deployed...'

if grep -q '>>> dotfiles shell config >>>' "$HOME/.bashrc"; then    # check for marker
    pass 'dotfiles shell config block found in ~/.bashrc'
else
    fail 'dotfiles shell config block not found - run 3_deploy.sh'
fi

# 3. Check key aliases are defined in ~/.bashrc
# Note: aliases do not export to subshells so we check the file directly
echo ''
echo '[3/4] Checking aliases are defined in ~/.bashrc...'

for alias_name in ll gs ga gc gp gd gl; do    # check each expected alias
    if grep -q "alias $alias_name=" "$HOME/.bashrc"; then    # check definition in file
        pass "alias $alias_name is defined"
    else
        fail "alias $alias_name is not defined - run 3_deploy.sh"
    fi
done

# 4. Check key environment variables are set
echo ''
echo '[4/4] Checking environment variables...'

if [[ -n "$EDITOR" ]]; then    # check EDITOR is set and non-empty
    pass "EDITOR is set: $EDITOR"
else
    fail 'EDITOR is not set - run: source ~/.bashrc'
fi

if [[ -n "$HISTSIZE" ]]; then    # check HISTSIZE is set and non-empty
    pass "HISTSIZE is set: $HISTSIZE"
else
    fail 'HISTSIZE is not set - run: source ~/.bashrc'
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
