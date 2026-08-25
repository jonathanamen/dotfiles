# VS Code Extensions Reference

Human-readable companion to `extensions.txt`. Contains the extension name, what it does, and a link
to documentation. The machine-readable list used by the deploy scripts lives in `extensions.txt`.

**What this list is curated for (REC-O-187).** Citizen 000 reads code and runs it; he does not
author it by hand. Every extension below earns its place against one of three real uses:

1. **Reading code someone else wrote** -- navigation, definitions, history, blame.
2. **Running Python scripts** -- interpreter selection, the Run button, the debugger.
3. **Converting markdown to PDF** -- the deliverable format.

Anything whose value lands only while a human is typing was removed. See "What was removed, and
why" at the bottom, which exists so the same extensions are not re-added later on the assumption
they were forgotten.

---

## Git

| Extension | Description | Docs |
|---|---|---|
| [GitLens](https://marketplace.visualstudio.com/items?itemName=eamodio.gitlens) | Reading history. Inline blame (who wrote each line and when), full commit history, file and line history, and comparison tools. The single most useful extension for reading a codebase you did not write. | [Docs](https://help.gitkraken.com/gitlens/gitlens-start-here/) |

---

## Python

| Extension | Description | Docs |
|---|---|---|
| [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | The Microsoft Python extension. Interpreter selection, the Run button, and terminal integration. This is what makes `python server.py` a click instead of a command. | [Docs](https://code.visualstudio.com/docs/languages/python) |
| [Pylance](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance) | The language server, kept for READING rather than writing. Go-to-definition, find-all-references, and hover types are how you follow a call through a file you did not write. | [Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-pylance) |
| [Debugpy](https://marketplace.visualstudio.com/items?itemName=ms-python.debugpy) | The debugger, and not optional even if you never set a breakpoint: the Run button routes through debugpy, so removing it removes the ability to run a file from the editor. | [Docs](https://code.visualstudio.com/docs/python/debugging) |
| [Python Envs](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-python-envs) | Microsoft's environment manager. Picks WHICH conda env a script runs in, which on a machine with miniforge base plus named envs is the difference between a script working and a confusing ImportError. | [Marketplace](https://marketplace.visualstudio.com/items?itemName=ms-python.vscode-python-envs) |

---

## Documents

| Extension | Description | Docs |
|---|---|---|
| [Markdown PDF](https://marketplace.visualstudio.com/items?itemName=yzane.markdown-pdf) | Converts markdown to PDF. The corpora are markdown and the deliverables are PDFs, so this is the bridge between them. Pointed at Edge rather than bundling Chromium. | [Marketplace](https://marketplace.visualstudio.com/items?itemName=yzane.markdown-pdf) |

---

## The AI assistant extension

Deliberately **not** in `extensions.txt`. Which assistant a machine gets is a per-machine decision
recorded in `config.env` as `DOTFILES_AI_EXTENSION`, and `3_deploy` installs it from there. A
client machine with no local administrator may not be permitted Claude Code at all, so `none` is a
valid and complete answer. Note that VS Code now ships Copilot as a built-in, and built-in
extensions never appear in `code --list-extensions` -- absence from that listing is not evidence of
absence from the editor.

---

## What was removed, and why

Recorded so these are not re-added later as things that were merely forgotten.

### Authoring aids -- value lands only while a human types

| Removed | Why |
|---|---|
| `christian-kohler.path-intellisense` | Completes file paths as you type them |
| `kevinrose.vsc-python-indent` | Fixes indentation as you type |
| `njpwerner.autodocstring` | Generates a docstring template when you type triple quotes |
| `ms-python.black-formatter` | Formats on save, which only fires when a human is editing in the editor |
| `ms-python.mypy-type-checker` | Surfaces type errors inline for an author to react to |

### Redundant or superseded

| Removed | Why |
|---|---|
| `donjayamanne.python-environment-manager` | Duplicates `ms-python.vscode-python-envs`, which is Microsoft's own and is the one kept |
| `donjayamanne.python-extension-pack` | An opaque bundle that drags in Django, Jinja, IntelliCode, docstring and indent extensions, all authoring aids, none of them individually chosen. **Uninstalling it cascades:** removing the pack also removed `ms-python.python`, `debugpy`, `vscode-pylance` and `vscode-python-envs`, which are keepers. Reinstall those four after removing the pack, or run `3_deploy` which reinstalls everything in `extensions.txt` anyway. This is the pack's whole problem in one sentence: it owns extensions you chose for your own reasons |
| `matangover.mypy` | Was replaced by `ms-python.mypy-type-checker` (which bundles its own mypy) and never removed. Its stale `mypy.dmypyExecutable` setting was dropped from `global/settings.json` at the same time |

### Unused, on the evidence

| Removed | Evidence |
|---|---|
| `ms-toolsai.jupyter`, `-keymap`, `-renderers`, `vscode-jupyter-cell-tags`, `vscode-jupyter-slideshow` | Zero `.ipynb` files exist anywhere under the GitHub checkout tree |
| `github.vscode-pull-request-github` | There is no PR workflow. Every merge commit in the grid's history is a `git pull` reconciliation between machines, not a reviewed pull request |
| `akamud.vscode-theme-onedark` | `global/settings.json` sets `workbench.colorTheme` to `Default High Contrast`. The theme was installed and not selected |
| `pkief.material-icon-theme` | `global/settings.json` sets no `workbench.iconTheme` at all, so VS Code's built-in Seti icons are what is actually on screen. Same status as the color theme: installed, not selected |
