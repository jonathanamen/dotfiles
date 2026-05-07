# Contributing

Standards, conventions, and decisions for this repo. Follow these when adding or modifying anything. When in doubt, default to best practice and most common convention for the language or tool in use.

---

## General principles

- **Best practice first** — always use the most widely accepted approach for the language or tool. Personal preference comes second. If you are unsure what best practice is, research it before deciding.
- **Document decisions** — if you make a non-obvious choice, add it to the Decision log at the bottom of this file with a reason.
- **Readable over clever** — code should be easy to understand for someone reading it for the first time. Prioritize clarity.
- **Modular and self-contained** — each module (vscode/, conda/, shell/) should be able to run independently without depending on other modules.

---

## Bash standards

### Shebang
Always use the portable shebang line at the top of every bash script:

    #!/usr/bin/env bash

This is preferred over #!/bin/bash because it finds bash from the environment rather than assuming a fixed path.

### Exit on error
Always include `set -e` near the top of every script:

    set -e

This causes the script to exit immediately if any command fails, preventing silent errors.

### Echo statements
Always use single quotes for echo statements that contain special characters, variables that should print literally, or suggested commands:

    # Correct
    echo '    git commit -m "chore: example $(date +%Y-%m-%d)"'

    # Avoid — backslash escaping is harder to read and maintain
    echo "    git commit -m \"chore: example \$(date +%Y-%m-%d)\""

Use double quotes for echo statements that should expand variables:

    echo "Installing $ext"

### Comments
Comment every non-obvious line. A future engineer should be able to understand what a script does without running it.

### Naming
- Script files: lowercase with hyphens — `deploy.sh`, `save.sh`
- Variables: uppercase with underscores — `REPO_DIR`, `PROJECT_DIR`

---

## Git standards

### Commit messages
Use Conventional Commits format:

    type: short description

Common types:

| Type | When to use |
|---|---|
| feat | A new feature or capability |
| fix | A bug fix |
| docs | Documentation changes only |
| chore | Maintenance, config changes, housekeeping |
| refactor | Code restructure with no behavior change |

Examples:

    feat: add conda module with deploy and save scripts
    fix: correct pylance extension ID in p008 extensions.txt
    docs: add wipe and reinstall section to README
    chore: snapshot vscode env 2026-05-07
    refactor: extract extension install logic into shared function

### Branch strategy
For a personal repo, committing directly to main is fine. If collaborating, use feature branches:

    git checkout -b feat/conda-module
    # do work
    git push origin feat/conda-module
    # open pull request

---

## File and folder naming

- Lowercase with hyphens for all files and folders: `deploy.sh`, `p008-arcane-predictive/`
- Project folders use padded numeric prefix: `p008-`, `p009-` — supports up to 999 projects
- README.md and CONTRIBUTING.md are uppercase by convention — GitHub surfaces them automatically

---

## Decision log

| Decision | Reason |
|---|---|
| Single quotes for echo statements with literal content | Avoids backslash escaping, easier to read and maintain |
| Separate extensions.txt and extensions.md | extensions.txt stays machine-readable for deploy.sh; extensions.md is human-readable reference with descriptions and links |
| One repo for all dotfiles, not per-tool repos | Single clone gets everything; tools are modular within the repo |
| WSL over Git Bash | WSL is a real Linux environment; scripts are portable to Linux servers and CI pipelines |
| Padded project numbering (p008 not p8) | Consistent sort order up to 999 projects |
