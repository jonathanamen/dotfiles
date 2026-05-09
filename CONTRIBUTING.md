# Contributing

Standards, conventions, and decisions for this repo. Follow these when adding or modifying anything. When in doubt, default to best practice and most common convention for the language or tool in use.

---

## Table of contents

1. [General principles](#1-general-principles)
2. [Module structure](#2-module-structure)
3. [Bootstrap order](#3-bootstrap-order)
4. [File and folder naming](#4-file-and-folder-naming)
5. [Bash standards](#5-bash-standards)
6. [Git standards](#6-git-standards)
7. [Decision log](#7-decision-log)

---

## 1. General principles

- **Best practice first** — always use the most widely accepted approach for the language or tool. Personal preference comes second. If you are unsure what best practice is, research it before deciding.
- **Document decisions** — if you make a non-obvious choice, add it to the Decision log at the bottom of this file with a reason.
- **Readable over clever** — code should be easy to understand for someone reading it for the first time. Prioritize clarity.
- **Modular and self-contained** — each module must be able to run independently without depending on other modules.
- **Standardization is the path to perfection** — every module must follow the same formula. No exceptions.
- **Always take the high road when the cost is low** — if a better solution exists and the effort to implement it is small, use it. Do not leave known improvements on the table.

---

## 2. Module structure

Every environment module must follow this exact structure. No deviations.

    N_modulename/
    ├── 0_setup.sh       <- prerequisites only (apt installs, one-time setup)
    ├── 1_save.sh        <- snapshot current state to repo
    ├── 2_wipe.sh        <- clean uninstall
    ├── 3_deploy.sh      <- full install from repo
    └── 4_test.sh        <- validate current state, report pass/fail

### Script responsibilities

| Script | Purpose | Destructive? |
|---|---|---|
| 0_setup.sh | One-time prerequisites only | No |
| 1_save.sh | Snapshot current state to repo | No |
| 2_wipe.sh | Clean uninstall | Yes |
| 3_deploy.sh | Full install from repo | Yes |
| 4_test.sh | Validate state, report pass/fail | Never |

### Rules

- Each script must be independently runnable
- `0_setup.sh` is for one-time prerequisites only — never for regular deploy logic
- `4_test.sh` must be non-destructive — validates state only, never changes anything
- A `0` prefix is reserved for setup only — never use it for regular process steps

### Adding a new module

1. Determine the correct position in the bootstrap order
2. Create the folder with the correct numeric prefix
3. Create all five scripts — even if some are stubs initially
4. Add the module to `bootstrap.sh` in the correct order
5. Document the module in `README.md` under Repo structure
6. Add any non-obvious decisions to the Decision log in this file

---

## 3. Bootstrap order

Modules must deploy in this order because each depends on the ones before it:

| Order | Module | Reason |
|---|---|---|
| 1 | 1_conda/ | Python runtime — all other tools depend on it |
| 2 | 2_vscode/ | Editor — extensions need Python to function |
| 3 | 3_shell/ | Shell config — may reference tools installed above |

### Running a single module

Each module can be wiped and redeployed independently without running bootstrap:

    cd 1_conda && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
    cd 2_vscode && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
    cd 3_shell && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh

---

## 4. File and folder naming

### Numbered prefixes

Any file or folder that is part of a process must be numbered with underscores so files display and run in logical order:

    1_save.sh
    2_wipe.sh
    3_deploy.sh
    4_test.sh

The `0_` prefix is reserved for setup and prerequisites only.

### Naming conventions by type

| Type | Convention | Example |
|---|---|---|
| Module folders | numeric prefix + underscore + name | 1_conda/, 2_vscode/ |
| Process scripts | numeric prefix + underscore + name | 1_save.sh, 3_deploy.sh |
| Project folders | padded project number + name | p008-arcane-predictive/ |
| Non-process files | lowercase with hyphens | global/, environments/ |
| Standard repo files | uppercase by convention | README.md, CONTRIBUTING.md |
| Script variables | uppercase with underscores | REPO_DIR, PROJECT_DIR |

### Project numbering

Project folders use zero-padded 3-digit numbers supporting up to 999 projects:

    p008-arcane-predictive/    <- correct
    p8-arcane-predictive/      <- incorrect

---

## 5. Bash standards

### Shebang

Always use the portable shebang line at the top of every bash script:

    #!/usr/bin/env bash

Preferred over `#!/bin/bash` because it finds bash from the environment rather than assuming a fixed path.

### Exit on error

Always include `set -e` near the top of every script:

    set -e

Causes the script to exit immediately if any command fails, preventing silent errors.

### Echo statements

Use single quotes for static text, suggested commands, or anything with special characters:

    echo '=== Deploy complete ==='
    echo '    git commit -m "chore: example $(date +%Y-%m-%d)"'

Use double quotes only when variable expansion is needed:

    echo "Installing $ext"
    echo "Applying project config: $PROJECT"

Never use backslash escaping inside echo strings — switch to single quotes instead.

### Inline comments

Every non-obvious line must have an inline comment:

    chmod +x vscode/deploy.sh    # make script executable before running
    set -e                       # exit immediately if any command fails

---

## 6. Git standards

### Commit messages

Use Conventional Commits format:

    type: short description

| Type | When to use |
|---|---|
| feat | A new feature or capability |
| fix | A bug fix |
| docs | Documentation changes only |
| chore | Maintenance, config changes, housekeeping |
| refactor | Code restructure with no behavior change |

### Commit often

Commit every logical unit of work independently. Small frequent commits are preferred over large infrequent ones. Do not bundle unrelated changes.

### Branch strategy

For a personal repo, committing directly to main is fine. If collaborating, use feature branches:

    git checkout -b feat/conda-module
    git push origin feat/conda-module
    # open pull request

---

## 7. Decision log

Decisions are grouped by category. Add new decisions to the relevant category.

### Architecture

| Decision | Reason |
|---|---|
| One repo for all dotfiles | Single clone gets everything; tools are modular within the repo |
| Each module has all 5 scripts | Standardization ensures every module is fully manageable independently |
| conda before vscode in bootstrap order | Python must exist before VS Code extensions can function |
| Modules must be independently runnable | Allows surgical wipe/redeploy of a single module without full bootstrap |

### Naming and structure

| Decision | Reason |
|---|---|
| Numbered file and folder prefixes | Files display and run in logical order; process is self-documenting |
| 0_ prefix reserved for setup only | Clear separation between prerequisites and regular process steps |
| Padded project numbering (p008 not p8) | Consistent sort order up to 999 projects |

### Bash

| Decision | Reason |
|---|---|
| Single quotes for static echo statements | Avoids backslash escaping; easier to read and maintain |
| WSL over Git Bash | WSL is a real Linux environment; scripts are portable to Linux servers and CI pipelines |

### VS Code extensions

| Decision | Reason |
|---|---|
| Separate extensions.txt and extensions.snapshot | extensions.txt is the curated intentional list; extensions.snapshot records live reality |
| Separate extensions.txt and extensions.md | extensions.txt stays machine-readable for deploy; extensions.md is human-readable reference with docs links |
