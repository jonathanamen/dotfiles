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
| 4 | 4_node/ | Node, npm, and Claude Code — no dependents |
| 5 | 5_annex/ | git-annex — content backend for the TDBI intake L0 tier; depends on nothing but git |

### Running a single module

Each module can be wiped and redeployed independently without running bootstrap:

    cd 1_conda && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
    cd 2_vscode && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
    cd 3_shell && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
    cd 4_node  && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
    cd 5_annex && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh

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
| A `user/` tree, not a second repo | A fork means every module fix is made twice and the two drift. One repo keeps a single history and a single set of standards. |
| Named `user/`, not `win/` | The tree was called `win/` first, for the platform. The property that actually defines it is **privilege**: it installs entirely into the user profile and needs no administrator. It happens to be Windows-only because the machine that forced it has no WSL, but a future no-admin Linux target would belong here too and would make a platform name a lie. |
| A platform tree, not a flag on the existing scripts | The root modules are bash targeting a Linux userland — `1_conda` fetches the Linux Miniforge behind `sudo apt`, `3_shell` writes `~/.bashrc`, `4_node` runs `sudo apt install`. That is a different operating system, not an option a switch can turn off. A flag would have meant a conditional in every script and two untested paths through each. |
| `user/` holds scripts only, never config data | `config.env`, `base-packages.txt` and `2_vscode/global/` are read from the root tree. A Windows copy of a settings file is a second source of truth that silently drifts from the first. |
| Every `user/2_wipe.ps1` accepts `-Force`, even the ones that never prompt | `bootstrap.ps1` then calls all of them identically instead of keeping a list of which ones happen to ask a question. |
| `user/0_personalize.ps1` prompts; the bash one reads a hand-edited file | The bash script runs on a machine that already has WSL and an editor. The Windows one runs on a bare machine where "open config.env and fill it in" is a worse first instruction than four questions. Both write the same `config.env`. |
| The AI extension list is closed, not free text | A mistyped extension id installs nothing and reports nothing — `code --install-extension` treats an unknown id as a no-op. A closed list turns that silent failure into a validation error. |
| `0_personalize` writes TDBI's `machine.local.json`, but only if TDBI is there | dotfiles is normally deployed before the repos are cloned, so a missing TDBI is the ordinary case on a fresh machine rather than a failure. It prints the file and where it goes instead, so either clone order works. |
| `backup_remote` defaults to false and the prompt steers to no | It decides whether TDBI's evidence gate blocks or warns. Answering yes without a real remote creates a gate nothing can clear. |

### PowerShell

| Decision | Reason |
|---|---|
| Never redirect a native command's stderr (`2>$null`, `2>&1`) in PowerShell 5.1 | 5.1 wraps every stderr line from a native exe in a `NativeCommandError` and sets `$?` to false **even when the exit code is 0**. Under `$ErrorActionPreference = 'Stop'` that is terminating. Found on first contact with a real machine: `code.cmd` is a node wrapper, node printed a `url.parse()` deprecation warning, the extension installed successfully, and the whole bootstrap aborted anyway. |
| Judge a native command by `$LASTEXITCODE`, never by `$?` or by whether it wrote to stderr | Plenty of working tools write warnings to stderr. The exit code is the only thing that states success or failure. |
| Drop `$ErrorActionPreference` to `Continue` around native calls, then restore it | Keeps `Stop` for the PowerShell logic, where an unhandled error genuinely should abort, without letting a third-party tool's chattiness decide whether the deploy finishes. |
| A failed extension install warns and continues | One unavailable extension is not a reason to leave a machine half configured. `4_test.ps1` is what decides whether the result is acceptable. |
| The AI extension is reported by `4_test.ps1`, never failed | VS Code ships Copilot as a **built-in**, and built-in extensions do not appear in `code --list-extensions` at all. Absence from that list is therefore not evidence of absence from the editor — the test failed a machine that had Copilot working the whole time. A check that cannot distinguish "missing" from "invisible" must not fail a deploy. |
| Installing a built-in extension fails, and that is not a bug | `GitHub.copilot` pulls `GitHub.copilot-chat`; the bundled built-in is newer than the version that dependency resolves to, so the CLI refuses to downgrade and exits 1. On a current VS Code the right value is `none` — the editor already provides it. |
| Each module has all 5 scripts | Standardization ensures every module is fully manageable independently |
| conda before vscode in bootstrap order | Python must exist before VS Code extensions can function |
| Modules must be independently runnable | Allows surgical wipe/redeploy of a single module without full bootstrap |
| bootstrap wipes before deploying | Guarantees clean state every run; updates are always applied |

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
| git status over git diff in save script suggestions | git diff only shows changes to tracked files; new files on first run only appear in git status |

### Conda

| Decision | Reason |
|---|---|
| Miniforge over Miniconda | Miniforge ships with conda-forge pre-configured; Miniconda hard-codes Anaconda defaults that are difficult to remove |
| conda-forge as default channel | No vendor TOS or commercial licensing restrictions, larger package selection, faster updates, industry standard |
| Named environments per project over base environment | Clean dependency separation, industry standard, prevents package conflicts across projects |

### Shell

| Decision | Reason |
|---|---|
| Keep only 1 local .bashrc backup | Git holds full history; local backup is only a safety net for the current run. Older backups are redundant. |
| Backup rotation in 0_setup.sh and 2_wipe.sh only | These are the only scripts that modify ~/.bashrc directly; save scripts write to the repo not the live file |

### VS Code extensions

| Decision | Reason |
|---|---|
| Separate extensions.txt and extensions.snapshot | extensions.txt is the curated intentional list; extensions.snapshot records live reality |
| Separate extensions.txt and extensions.md | extensions.txt stays machine-readable for deploy; extensions.md is human-readable reference with docs links |

### Python packages

| Decision | Reason |
|---|---|
| Base-env packages live in 1_conda/base-packages.txt, not in TDBI | The TDBI grid runs on the miniforge **base** python, so its dependencies are machine state, and machine state is dotfiles' job. A requirements.txt inside TDBI would be a second source of truth that a fresh machine never runs. |
| 4_test.sh imports them rather than checking pip list | An installed-but-broken package passes a `pip list` check and fails at the first search. The import is the only test that means anything. |
| TDBI_EMBED_THREADS=4 and OMP_NUM_THREADS=4 exported in .bashrc | ONNX defaults to one thread per core. On ENIAC (32 cores) an embedding pass spawned enough threads to take WSL down mid-index, live. An embedding pass is a background convenience, not a workload, and it must never be able to kill the machine it runs on. |
| ...but the .bashrc export is NOT the real cap | `.bashrc` returns early for non-interactive shells, and the grid runs every citizen through `wsl.exe bash -c` -- which is non-interactive. So the export never reaches librarian. The binding cap is the default in TDBI's `lib/retrieval.py`; the export only covers interactive terminals. Worth knowing before trusting an env var to constrain anything the grid runs. |

### git-annex

| Decision | Reason |
|---|---|
| Dotfiles installs git-annex but wires no remote | A backup remote is a property of a corpus on a machine, not of the machine: ENIAC uses a local folder, the client laptop uses the client's OneDrive. The grid (linter connect-intake) wires it and can re-point it with `git annex enableremote`. Dotfiles installs the tool; the grid decides where the bytes go. |
| annex.largefiles is never set globally | A git config value for annex.largefiles **overrides** a repo's own .gitattributes. Verified live on 2026-07-12: a global `annex.largefiles=nothing` silently un-annexed the TDBI intake L0 tier and sent raw artifacts into the git object store even though .gitattributes said to annex them. Which files annex is a property of the corpus, and only the corpus may declare it. 3_deploy.sh actively unsets it. |
| annex.autocommit=false | Every commit on the grid goes through herald's commit gate, where a human reads the diff first. Annex never commits on our behalf. |
| 2_wipe.sh never touches annexed content | The L0 tier is evidence and nothing may delete it. Uninstalling the tool must not destroy the data — reinstall and `git annex get` restores access. |
