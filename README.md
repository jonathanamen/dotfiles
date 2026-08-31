# dotfiles

Dev environment management repo. Written to be readable, not just runnable. Each command has an
explanation so you understand what you are doing and why. Every step tells you what it does, why it
matters, and what to expect.

## Which tree is this machine?

**Read this before step 0.** There are two deploys in this repo and only one of them applies to you.

| If the machine has | Use | Start at |
|---|---|---|
| Administrator rights and WSL | the **root** tree (bash) | this runbook, top to bottom |
| No local administrator, or no WSL | the **`user/`** tree (PowerShell) | [`user/README.md`](user/README.md) |

Everything in this runbook assumes Windows plus WSL plus administrator. On a locked-down machine
none of it will run, and following it to the end before finding that out is the failure this table
exists to prevent. The `user/` tree installs entirely into your own profile and needs no elevation.

The two trees share their configuration data and differ only in their scripts, so a setting changed
in one applies to both. One case runs the other way: a WSL machine also needs `user/1_conda`,
because building a Windows executable requires a Windows interpreter. `user/README.md` covers it.

### Already have a team dotfiles repo (e.g. `dotfiles-team`) deployed on this machine?

**Do not run `user/bootstrap.ps1` or any `user/*/2_wipe.ps1` / `user/*/3_deploy.ps1` script here.**
Those deploy a full, standalone machine setup and will WIPE and REPLACE whatever a team repo already
installed -- VS Code settings become a flat `Copy-Item -Force`, and the team's curated extension list
gets uninstalled and swapped for this repo's own list. This has actually happened: an assistant ran
`user/bootstrap.ps1` on a machine that already had `dotfiles-team` deployed, and it silently stripped
the team's 13 VS Code extensions down to this repo's 6.

What you actually want is **[`user/personal_overlay/`](user/personal_overlay/README.md)** -- the one
piece of this repo built to layer on top of an existing team deploy without touching it. Read its
README before running anything else in this repo on a machine that is not exclusively yours.

## Table of contents

0. Wipe and reinstall VS Code
1. Prerequisites
2. Install VS Code
3. Install Git for Windows
4. Install WSL
5. Configure your Linux environment
6. Install Node.js and Claude Code
7. Install and configure Git
8. Clone this repo
9. Connect VS Code to WSL
10. Personalize and deploy
11. Verify everything works
12. Ongoing workflow
13. System test
14. Nuclear rebuild

Then two reference sections that are not steps: [Repo structure](#repo-structure) and
[Projects](#projects). The numbers above are the section numbers used in the body, so a
cross-reference from elsewhere in the repo lands where it says it does.

---

## 0. Wipe and reinstall VS Code

Follow this section when you want a clean VS Code install on a machine that already has VS Code. Skip to step 1 if you are setting up a brand new machine.

### Why you might do this

VS Code accumulates extensions, settings, and cached data over time. A clean reinstall removes all of that and lets you redeploy a known good state from this repo.

### Pre-wipe checklist

Before uninstalling, confirm the following are saved in this repo and pushed to GitHub:

- Extensions are documented in 2_vscode/global/extensions.txt and 2_vscode/global/extensions.md
- Settings are saved in 2_vscode/global/settings.json
- Keybindings are saved in 2_vscode/global/keybindings.json
- Any custom snippets have been exported
- Any project workspace configs are saved under 2_vscode/projects/
- All changes are committed and pushed to GitHub

If anything is missing, save before wiping. Which script depends on the tree this machine
uses: `2_vscode/1_save.sh` on a WSL machine, `user\2_vscode\1_save.ps1` on a machine running
the `user/` tree. Both write the same shared files under `2_vscode/global/`.

### Uninstall VS Code

1. Open Windows Settings, go to Apps, click Installed Apps, search "Visual Studio Code", click Uninstall

2. After uninstall, delete these two leftover folders:
   - C:\Users\YOUR_WINDOWS_USERNAME\AppData\Roaming\Code
   - C:\Users\YOUR_WINDOWS_USERNAME\.vscode

### Reinstall VS Code

Follow step 2 below.

---

## 1. Prerequisites

Before starting, make sure you have:

- Windows 10 or Windows 11 (any edition)
- Administrator access on your machine
- An internet connection
- A GitHub account

---

## 2. Install VS Code

Install VS Code on Windows before WSL. The deploy scripts require VS Code to be accessible from WSL, and installing it first avoids connection issues during bootstrap.

1. Download from code.visualstudio.com
2. Run the installer and accept defaults
3. Check "Add to PATH" during install — this enables the `code .` command from the terminal
4. Install the WSL extension: open VS Code, go to Extensions (Ctrl+Shift+X), search "WSL", install the Microsoft WSL extension

---

## 3. Install Git for Windows

Git for Windows installs a native git binary on the Windows side, which is required for VS Code's Source Control panel to work. This is separate from the git you use inside WSL.

1. Download from git-scm.com
2. Run the installer — safe to install over an existing Git Desktop installation
3. Accept all defaults
4. When prompted with "Adjusting your PATH environment", select "Git from the command line and also from 3rd-party software" (the default)
5. Complete the install and open a new PowerShell window

Verify:

```powershell
git --version
```

Expected output: `git version 2.x.x.windows.x`

Note: you must open a new terminal after install for PATH changes to take effect. Restart VS Code after install to connect Source Control.

---

## 4. Install WSL

### What is WSL and why do we use it

WSL (Windows Subsystem for Linux) runs a full Ubuntu Linux environment inside Windows. This is where all development work happens — bash scripts, Python, git, and conda all run here.

### Install via PowerShell (preferred)

Open PowerShell as Administrator (search "PowerShell" in the Start menu, right-click, Run as administrator) and run:

```
wsl --install
```

Restart your machine when prompted.

After restarting, Ubuntu finishes setup automatically and asks you to create a user account:

```
Enter new UNIX username: ubuntu
Enter new UNIX password:
```

Use `ubuntu` as the username for consistency across machines. The password will not show characters as you type — that is normal.

### Fallback: Install Ubuntu via Microsoft Store

If `wsl --install` fails with a network error (error code 0x80072ee7):

1. Open the Microsoft Store
2. Search "Ubuntu 22.04" or "Ubuntu 24.04"
3. Click Install

Then open Ubuntu from the Start menu to complete setup and create your user account.

### Verify

```bash
cat /etc/os-release    # confirms Ubuntu is installed
echo $SHELL            # should output /bin/bash
```

---

## 5. Configure your Linux environment

### Update the package manager

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git build-essential
```

### Verify

```bash
bash --version    # should show bash 5.x
```

---

## 6. Install Node.js and Claude Code

Node.js is required for Claude Code, Anthropic's agentic coding CLI.

**`bootstrap.sh` already does this**, through `4_node/3_deploy.sh`. Run the commands below only if
you want Claude Code before bootstrapping, or you are deploying that one module by hand. Do not run
the module itself under `sudo`; it refuses an elevated shell on purpose and calls `sudo` internally
where apt genuinely needs it.

```bash
sudo apt install nodejs npm
sudo npm install -g @anthropic-ai/claude-code
```

Verify:

```bash
node --version     # should show v18.x or higher
npm --version
claude --version   # should show 2.x.x (Claude Code)
```

### Launch Claude Code

Claude Code launches from inside any repo directory:

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/YOUR_REPO
claude
```

### VS Code extension

The VS Code extension is recommended over the terminal interface. It puts Claude Code in a sidebar panel directly inside VS Code — code on the left, Claude on the right, terminal at the bottom.

Install from the Extensions panel (Ctrl+Shift+X), search "Claude Code", install the extension published by Anthropic. It picks up your existing auth automatically.

### CLAUDE.md

Claude Code reads `CLAUDE.md` at repo root on every session start. Seed this file with allowed paths, project context, agent inventory, naming conventions, and working standards. This eliminates per-session permission prompts and gives Claude Code standing context without re-explaining every time.

---

## 7. Install and configure Git

### Set your identity

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

### Set up SSH authentication with GitHub

```bash
ssh-keygen -t ed25519 -C "you@example.com"
```

Press Enter to accept the default file location. Leave the passphrase blank.

Copy your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Go to GitHub → Settings → SSH and GPG keys → New SSH key → paste it in → save.

Test the connection:

```bash
ssh -T git@github.com
```

Expected output: `Hi username! You've successfully authenticated...`

---

## 8. Clone this repo

Repos live on the Windows filesystem for cross-tool compatibility. Do not clone into the WSL home directory.

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub
git clone git@github.com:YOUR_USERNAME/dotfiles.git
cd dotfiles
```

To find your Windows username:

```bash
ls /mnt/c/Users/
```

---

## 9. Connect VS Code to WSL

From your WSL terminal inside the dotfiles folder:

```bash
code .
```

The first time you run this, VS Code installs a small server component inside WSL. After that, VS Code opens on Windows but everything runs in Linux. Verify the connection by checking the bottom-left corner of VS Code — it should say "WSL: Ubuntu".

---

## 10. Personalize and deploy

### Step 1 — Fill in config.env

```bash
cp config.env.example config.env
nano config.env
```

Fill in all nine values. `config.env.example` carries the full commentary for each; this is the
summary.

**Identity and paths**

- `DOTFILES_USER_NAME`: your full name
- `DOTFILES_USER_EMAIL`: your email, must match your GitHub account
- `DOTFILES_GITHUB_USERNAME`: your GitHub username
- `DOTFILES_WINDOWS_USERNAME`: your Windows login name (the folder name under C:\Users)
- `DOTFILES_GITHUB_PATH`: your GitHub directory in WSL terms, used by the shell navigation aliases
- `DOTFILES_GITHUB_PATH_WIN`: the same directory in Windows terms, for the `user/` tree only.
  Never a translation of the WSL path, because a machine with no WSL has no `/mnt/c`

**Machine attributes.** These describe what this machine IS, and `0_personalize` writes them into
TDBI's `config/machine.local.json`. That file is how the grid learns a machine's capabilities
instead of matching its name against a hardcoded list, so leaving them out does not merely skip a
setting, it leaves the grid unable to answer what machine it is standing on.

- `DOTFILES_AI_EXTENSION`: which AI assistant this machine deploys, as a VS Code extension id.
  A closed set: `GitHub.copilot`, `anthropic.claude-code`, `Continue.continue` or `none`. Current
  VS Code ships Copilot as a built-in, so `none` is the right answer on many machines
- `DOTFILES_BACKUP_REMOTE`: whether this machine has a git-annex remote it can actually copy L0
  content to. Answering `true` without a real remote creates a TDBI evidence gate nothing can clear

**Optional**

- `DOTFILES_FIRST_PROJECT`: your first project in `p###-name` format, or `none`.
  Never name it after a client, because `2_vscode/projects/` is committed

Save with Ctrl+X, Y, Enter.

### Step 2 — Run personalize

```bash
chmod +x 0_personalize.sh bootstrap.sh [1-5]_*/*.sh
./0_personalize.sh
```

### Step 3 — Run bootstrap

```bash
./bootstrap.sh
```

After bootstrap completes, run:

```bash
source ~/.bashrc
```

Then restart VS Code to apply all settings.

---

## 11. Verify everything works

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/1_conda && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/2_vscode && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/3_shell && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/4_node && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/5_annex && ./4_test.sh
```

All five modules, not three. If any fail, the error message tells you exactly which script to run
to fix it.

---

## 12. Ongoing workflow

### Saving your VS Code state

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles
./2_vscode/1_save.sh
git add -A
git commit -m "chore: snapshot vscode env $(date +%Y-%m-%d)"
git push
```

### Saving your shell config

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles
./3_shell/1_save.sh
git add -A
git commit -m "chore: snapshot shell config $(date +%Y-%m-%d)"
git push
```

### Deploying to a new machine

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub
git clone git@github.com:YOUR_USERNAME/dotfiles.git
cd dotfiles
chmod +x 0_personalize.sh bootstrap.sh [1-5]_*/*.sh
cp config.env.example config.env
nano config.env
./0_personalize.sh
./bootstrap.sh
```

### Adding a new project

1. Create a folder under 2_vscode/projects/:

```bash
mkdir -p 2_vscode/projects/p###-your-project
touch 2_vscode/projects/p###-your-project/settings.json
touch 2_vscode/projects/p###-your-project/extensions.txt
```

2. Add workspace settings and project-specific extensions

3. Deploy with:

```bash
./2_vscode/3_deploy.sh p###-your-project
```

### Wiping and redeploying a single module

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/1_conda && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/2_vscode && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/3_shell && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/4_node && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/5_annex && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
```

`5_annex/2_wipe.sh` removes the tool and never the annexed content. The L0 tier is evidence, so a
wipe must not be able to destroy it: reinstall and `git annex get` restores access.

---

## 13. System test

```bash
mv /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles.bak
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub
git clone git@github.com:YOUR_USERNAME/dotfiles.git
cd dotfiles
chmod +x 0_personalize.sh bootstrap.sh [1-5]_*/*.sh
cp config.env.example config.env
nano config.env
./0_personalize.sh
./bootstrap.sh

rm -rf /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles.bak   # clean up if test passed
```

---

## 14. Nuclear rebuild

### Phase 1 — Windows cleanup (manual)

1. Uninstall VS Code: Settings → Apps → Installed Apps → search "Visual Studio Code" → Uninstall
2. Delete C:\Users\YOUR_WINDOWS_USERNAME\AppData\Roaming\Code
3. Delete C:\Users\YOUR_WINDOWS_USERNAME\.vscode
4. Uninstall Ubuntu — open PowerShell as Administrator:

```powershell
wsl --unregister Ubuntu
```

5. Restart Windows

### Phase 2 — Reinstall

Follow the runbook from step 2 top to bottom.

---

## Repo structure

```
dotfiles/
├── README.md                     <- this runbook
├── CONTRIBUTING.md               <- standards and conventions
├── config.env.example            <- template for personal config (committed)
├── config.env                    <- your personal config (gitignored, never committed)
├── .gitignore
├── 0_personalize.sh              <- validates config.env and applies personal settings
├── bootstrap.sh                  <- wipes, deploys, and tests all modules in order
├── 1_conda/                      <- Python environment module
│   ├── 0_setup.sh
│   ├── 1_save.sh
│   ├── 2_wipe.sh
│   ├── 3_deploy.sh
│   ├── 4_test.sh
│   ├── base-packages.txt         <- packages for the miniforge BASE env, installed by 3_deploy.sh
│   └── environments/
├── 2_vscode/                     <- VS Code module
│   ├── 0_setup.sh
│   ├── 1_save.sh
│   ├── 2_wipe.sh
│   ├── 3_deploy.sh
│   ├── 4_test.sh
│   ├── global/
│   │   ├── settings.json
│   │   ├── keybindings.json
│   │   ├── extensions.txt
│   │   ├── extensions.snapshot
│   │   └── extensions.md
│   ├── claude/
│   │   └── settings.json         <- Claude Code global settings, deployed to the WINDOWS profile
│   └── projects/
│       └── p008-arcane-predictive/
├── 3_shell/                      <- shell config module
│   ├── 0_setup.sh
│   ├── 1_save.sh
│   ├── 2_wipe.sh
│   ├── 3_deploy.sh
│   ├── 4_test.sh
│   └── config/
│       ├── .bashrc
│       └── .bash_aliases         <- repo navigation aliases; no company repo is ever aliased here
├── 4_node/                       <- Node.js and Claude Code module
│   ├── 0_setup.sh
│   ├── 2_wipe.sh                 <- no 1_save.sh: node state is fixed (always Node + Claude Code), nothing to capture
│   ├── 3_deploy.sh
│   └── 4_test.sh
├── 5_annex/                      <- git-annex module (content backend for the TDBI intake L0 tier)
│   ├── 0_setup.sh
│   ├── 1_save.sh
│   ├── 2_wipe.sh                 <- never touches annexed content: L0 is evidence, nothing may delete it
│   ├── 3_deploy.sh
│   ├── 4_test.sh
│   └── config/                   <- version and global annex settings, written by 1_save.sh
└── user/                          <- the no-admin, no-WSL Windows deploy (see user/README.md)
    ├── README.md
    ├── 0_personalize.ps1         <- asks for config and writes config.env + TDBI's machine file
    ├── bootstrap.ps1             <- wipes, deploys and tests the Windows modules in order
    ├── 1_conda/                  <- Miniforge "Just Me" into %LOCALAPPDATA%
    ├── 2_vscode/                 <- settings and extensions into %APPDATA%\Code\User
    ├── 3_shell/                  <- PowerShell profile, the counterpart of ~/.bashrc
    ├── 4_azure_cli/              <- Az PowerShell module, user scope, no elevation
    └── 5_pac_cli/                <- Power Platform CLI (pac) via winget
```

The `user/` modules carry no configuration data of their own. They read `config.env`,
`1_conda/base-packages.txt` and `2_vscode/global/` from the paths above, so a setting changed
once applies to both platforms.

**The numbers do not pair across the two trees.** Slots 4 and 5 hold different modules on each
side, and reading `user/4_azure_cli` as a Windows `4_node` is the mistake the numbering invites.
The root tree's `4_node` and `5_annex` have no `user/` counterpart at all: Node is here only for
Claude Code, which that deploy does not use, and `git-annex` has no user-scope Windows install, so
such a machine is never an L0 backup target and declares `backup_remote: false`. What sits in those
slots under `user/` is Windows-only client tooling the WSL tree has no equivalent for.

---

## Projects

A project here is a VS Code workspace overlay under `2_vscode/projects/`, deployed on top of the
global config with `./2_vscode/3_deploy.sh p###-name`. The overlay is additive and never removes
anything the global config installed.

Never name a project after a client. `2_vscode/projects/` is committed, and a company name in the
committed tree is exactly what the gitignored company registry exists to prevent.

### p008-arcane-predictive

MTG trading company (Arcane Predictive). Python and data stack. See
`2_vscode/projects/p008-arcane-predictive/` for workspace settings and extensions.

Its `extensions.txt` now lists only `ms-python.python` and `ms-python.vscode-pylance`, both of
which the global list already installs, so the overlay adds nothing beyond its `settings.json`
(tab size, rulers, excludes and a `.venv` interpreter path). It is kept for those settings.
