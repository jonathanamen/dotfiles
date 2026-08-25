# Repository navigation shortcuts
# Managed by dotfiles/3_shell - do not edit manually
# ── Repository navigation ─────────────────────────────────────────────────────
_DOTFILES_CONFIG="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../config.env"
if [ -f "$_DOTFILES_CONFIG" ]; then source "$_DOTFILES_CONFIG"; fi
unset _DOTFILES_CONFIG
GITHUB="${DOTFILES_GITHUB_PATH:-/mnt/c/Users/Anglachel/Documents/GitHub}"
alias tdbi="cd $GITHUB/TDBI"
alias dotfiles="cd $GITHUB/dotfiles"
alias ltm="cd $GITHUB/ltm"

# Only repos that actually exist on every WSL machine are aliased here (REC-O-187). Aliases for
# arcane-predictive, Project-FitnessTracker, databricks and repo-template were removed: they
# pointed at checkouts no longer kept, so they resolved to a cd into nothing.
#
# NO COMPANY REPO GETS AN ALIAS, EVER. Company workspace names are confidential and are located
# through a gitignored local registry rather than named in committed code (TDBI CLAUDE.md, repo
# boundary rules). An alias here is committed code, so adding one would publish the client name
# to every machine this repo deploys to, and to anyone the repo is later forked for.

