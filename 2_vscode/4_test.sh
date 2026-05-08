#!/usr/bin/env bash
# 4_test.sh — Validate VS Code module state and report pass/fail
#
# Usage:
#   ./4_test.sh
#
# What it does:
#   - Checks VS Code is accessible from WSL
#   - Verifies settings.json and keybindings.json exist
#   - Verifies all extensions in extensions.txt are installed
#   - Verifies default shell is bash
#   - Reports pass/fail for each check with a final summary
#
# Non-destructive — this script never changes anything.

# Note: set -e is intentionally omitted — test scripts must run all checks
# and report results rather than exiting on the first failure.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # get absolute path to this script's directory
GLOBAL_DIR="$REPO_DIR/global"                               # path to global config folder
PASS=0                                                       # counter for passed checks
FAIL=0                                                       # counter for failed checks

echo '=== VS Code Module Test ==='

# ── Helper functions ──────────────────────────────────────────────────────────
pass() {
    echo "      PASS: $1"
    PASS=$((PASS + 1))    # increment pass counter — using arithmetic expansion avoids set -e issues
}

fail() {
    echo "      FAIL: $1"
    FAIL=$((FAIL + 1))    # increment fail counter — using arithmetic expansion avoids set -e issues
}

# ── 1. Check VS Code is accessible ───────────────────────────────────────────
echo ''
echo '[1/4] Checking VS Code is accessible...'

if command -v code &> /dev/null; then    # check if code command exists in PATH
    pass 'VS Code is accessible from WSL'
else
    fail 'VS Code is not accessible — run 0_setup.sh'
fi

# ── 2. Check settings files exist ────────────────────────────────────────────
echo ''
echo '[2/4] Checking settings files...'

VSCODE_SETTINGS_DIR="$HOME/.vscode-server/data/Machine"   # WSL-side VS Code settings path

if [[ -f "$VSCODE_SETTINGS_DIR/settings.json" ]]; then     # verify settings file exists
    pass 'settings.json exists'
else
    fail 'settings.json not found — run 3_deploy.sh'
fi

if [[ -f "$VSCODE_SETTINGS_DIR/keybindings.json" ]]; then  # verify keybindings file exists
    pass 'keybindings.json exists'
else
    fail 'keybindings.json not found — run 3_deploy.sh'
fi

# ── 3. Check all curated extensions are installed ────────────────────────────
echo ''
echo '[3/4] Checking extensions...'

INSTALLED=$(code --list-extensions | sort)   # get sorted list of all installed extensions

while IFS= read -r ext || [[ -n "$ext" ]]; do
    [[ -z "$ext" || "$ext" == \#* ]] && continue   # skip blank lines and comment lines

    if echo "$INSTALLED" | grep -qi "^${ext}$"; then   # case-insensitive exact match
        pass "$ext"
    else
        fail "$ext is not installed"
    fi
done < "$GLOBAL_DIR/extensions.txt"

# ── 4. Check default shell is bash ───────────────────────────────────────────
echo ''
echo '[4/4] Checking shell...'

if [[ "$SHELL" == */bash ]]; then    # verify SHELL environment variable ends in bash
    pass 'Default shell is bash'
else
    fail "Default shell is $SHELL — expected bash"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ''
echo '================================'
echo "  PASSED: $PASS"
echo "  FAILED: $FAIL"
echo '================================'

if [[ "$FAIL" -eq 0 ]]; then     # exit 0 (success) if no failures
    echo '  RESULT: ALL TESTS PASSED'
    exit 0
else
    echo '  RESULT: SOME TESTS FAILED'
    exit 1                        # exit 1 (failure) if any checks failed
fi
