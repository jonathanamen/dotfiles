# Repository navigation shortcuts
# Managed by dotfiles/3_shell - do not edit manually
# ── Repository navigation ─────────────────────────────────────────────────────
_DOTFILES_CONFIG="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../config.env"
if [ -f "$_DOTFILES_CONFIG" ]; then source "$_DOTFILES_CONFIG"; fi
unset _DOTFILES_CONFIG
GITHUB="${DOTFILES_GITHUB_PATH:-/mnt/c/Users/Anglachel/Documents/GitHub}"
alias tdbi="cd $GITHUB/TDBI"
alias arcane="cd $GITHUB/arcane-predictive"
alias fitness="cd $GITHUB/Project-FitnessTracker"
alias databricks="cd $GITHUB/databricks"
alias template="cd $GITHUB/repo-template"
alias dotfiles="cd $GITHUB/dotfiles"
alias ltm="cd $GITHUB/ltm"
export TDBI_MEMORY_TOKEN="paste-key-inside-quotes-wrapper"
