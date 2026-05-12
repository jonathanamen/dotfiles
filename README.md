# dotfiles

Dev environment management repo. Follow this runbook top to bottom on any fresh Windows 11 machine and you will end up fully set up — WSL, Git, conda, VS Code, and all project configs deployed.

Written to be readable, not just runnable. Each command has an explanation so you understand what you are doing and why. Every step tells you what it does, why it matters, and what to expect.

---

## Table of contents

0. [Wipe and reinstall VS Code](#0-wipe-and-reinstall-vs-code)
1. [Prerequisites](#1-prerequisites)
2. [Install WSL](#2-install-wsl)
3. [Configure your Linux environment](#3-configure-your-linux-environment)
4. [Install and configure Git](#4-install-and-configure-git)
5. [Clone this repo](#5-clone-this-repo)
6. [Install VS Code](#6-install-vs-code)
7. [Personalize and deploy](#7-personalize-and-deploy)
8. [Verify everything works](#8-verify-everything-works)
9. [Ongoing workflow](#9-ongoing-workflow)
10. [System test](#10-system-test)
11. [Nuclear rebuild](#11-nuclear-rebuild)

---

## 0. Wipe and reinstall VS Code

Follow this section when you want a clean VS Code install on a machine that already has VS Code. Skip to step 1 if you are setting up a brand new machine.

### Why you might do this

VS Code accumulates extensions, settings, and cached data over time. A clean reinstall removes all of that and lets you redeploy a known good state from this repo. This is also useful after a major VS Code update causes unexpected behavior.

### Pre-wipe checklist

Before uninstalling, confirm the following are saved in this repo and pushed to GitHub:

- Extensions are documented in 2_vscode/global/extensions.txt and 2_vscode/global/extensions.md
- Settings are saved in 2_vscode/global/settings.json
- Keybindings are saved in 2_vscode/global/keybindings.json
- Any custom snippets have been exported (File, Preferences, Configure User Snippets)
- Any project workspace configs are saved under 2_vscode/projects/
- All changes are committed and pushed to GitHub

If anything is missing, run 2_vscode/1_save.sh first before wiping.

### Uninstall VS Code

1. Open Windows Settings, go to Apps, click Installed Apps, search "Visual Studio Code", click Uninstall

2. After uninstall, delete these two leftover folders. The uninstaller does not remove them automatically:
   - C:\Users\YOUR_WINDOWS_USERNAME\AppData\Roaming\Code  (settings and extension data)
   - C:\Users\YOUR_WINDOWS_USERNAME\.vscode  (installed extensions)

   Skipping this step means your old settings survive the wipe and the clean install is not actually clean.

Note: Registry cleanup is intentionally skipped. The VS Code uninstaller handles its own registry entries and all meaningful config lives in the two folders above.

### Reinstall VS Code

1. Download the installer from code.visualstudio.com
2. Run the installer and accept defaults
3. Check "Add to PATH" during install. This lets you open VS Code from the WSL terminal with the command "code ."
4. Install the WSL extension: open VS Code, go to Extensions (Ctrl+Shift+X), search "WSL", install the Microsoft WSL extension. This extension is what allows VS Code on Windows to connect to your Linux environment.
5. Open your WSL terminal and run:

    cd ~/repos/dotfiles
    code .

6. Deploy your saved environment:

    chmod +x 2_vscode/3_deploy.sh
    ./2_vscode/3_deploy.sh p008-arcane-predictive

7. Restart VS Code to apply all settings

---

## 1. Prerequisites

Before starting, make sure you have:

- Windows 11 (any edition)
- Administrator access on your machine
- An internet connection
- A GitHub account — you will need this for SSH authentication in step 4

No other software is required. WSL, Git, conda, and everything else gets installed during this runbook.

---

## 2. Install WSL

### What is WSL and why do we use it

WSL (Windows Subsystem for Linux) runs a full Ubuntu Linux environment inside Windows. This is where all development work happens — bash scripts, Python, git, and conda all run here. VS Code on Windows connects into WSL so you get a familiar editor with a real Linux toolchain underneath.

This approach is how most professional developers on Windows work. It gives you scripts that run identically on Linux servers and CI/CD pipelines, which is not possible with PowerShell or Git Bash.

### Install

Open PowerShell as Administrator (search "PowerShell" in the Start menu, right-click, Run as administrator) and run:

    wsl --install

This installs WSL 2 and Ubuntu in one command. WSL 2 is required — it runs a real Linux kernel rather than a compatibility layer.

Restart your machine when prompted. This is required for WSL to finish setup.

After restarting, Ubuntu finishes setup automatically and asks you to create a user account:

    Enter new UNIX username: yourname
    Enter new UNIX password:

Pick a username (lowercase, no spaces) and a password. The password will not show characters as you type — that is normal Linux behavior, not a bug.

### Verify

    cat /etc/os-release    # confirms Ubuntu is installed
    echo $SHELL            # should output /bin/bash

---

## 3. Configure your Linux environment

### What this does

Updates Ubuntu's package list and installs the essential command-line tools needed for everything else in this runbook. This only needs to be done once per machine.

### Update the package manager

Ubuntu uses apt to install software. Always update before installing anything:

    sudo apt update && sudo apt upgrade -y

sudo means "run as administrator." apt update refreshes the list of available packages. apt upgrade -y installs all pending updates, with -y auto-confirming each one.

### Install essential tools

    sudo apt install -y curl wget git build-essential

- curl and wget: download files from the internet, used by scripts throughout this repo
- git: version control, covered in step 4
- build-essential: a bundle of compilers and libraries that many packages depend on

### Verify

    bash --version    # should show bash 5.x

---

## 4. Install and configure Git

### What this does

Configures your identity so every commit you make is tagged with your name and email. Also sets up SSH authentication with GitHub so you can push and pull without typing a password.

### Set your identity

    git config --global user.name "Your Name"
    git config --global user.email "you@example.com"

Use the same name and email as your GitHub account. --global means this applies to all repos on this machine.

### Set the default branch name

GitHub uses "main" as the default branch. This makes git match:

    git config --global init.defaultBranch main

### Set up SSH authentication with GitHub

SSH keys are how you authenticate to GitHub without a password. You generate a key pair — a private key that stays on your machine and a public key that you give to GitHub.

Generate a key pair:

    ssh-keygen -t ed25519 -C "you@example.com"

Press Enter to accept the default file location. You can leave the passphrase blank.

This creates two files:
- ~/.ssh/id_ed25519: your private key — never share this
- ~/.ssh/id_ed25519.pub: your public key — this is what you give to GitHub

Copy your public key:

    cat ~/.ssh/id_ed25519.pub

Copy the entire output. Go to GitHub, Settings, SSH and GPG keys, New SSH key, paste it in, save.

Test the connection:

    ssh -T git@github.com

Expected output: Hi username! You have successfully authenticated...

### Verify

    git config --list    # shows your name, email, and defaultBranch

---

## 5. Clone this repo

### What this does

Downloads this dotfiles repo into your WSL home directory. All subsequent steps run from inside this repo.

    cd ~
    mkdir repos && cd repos
    git clone git@github.com:YOUR_USERNAME/dotfiles.git
    cd dotfiles

~ is shorthand for your home directory (/home/yourusername). Work inside WSL's filesystem (/home/...) not the Windows filesystem (/mnt/c/...). WSL can read Windows files but runs much faster on its own filesystem.

---

## 6. Install VS Code

### What this does

Installs VS Code on Windows (not inside WSL). VS Code runs on Windows for performance and UI, but connects into WSL so all file access and terminal sessions happen in Linux.

1. Download from code.visualstudio.com
2. Run the installer, accept defaults
3. Check "Add to PATH" — this enables the "code ." command from the terminal

Install the WSL extension:

Open VS Code, go to Extensions (Ctrl+Shift+X), search "WSL", install the Microsoft WSL extension. This extension is the bridge between VS Code on Windows and your Linux environment.

Connect VS Code to WSL. From your WSL terminal:

    cd ~/repos/dotfiles
    code .

The first time you run this, VS Code installs a small server component inside WSL. After that, VS Code opens on Windows but everything runs in Linux. You can verify the connection by checking the bottom-left corner of VS Code — it should say "WSL: Ubuntu".

---

## 7. Personalize and deploy

### What this does

This is a two-step process. First you fill in your personal details in a config file. Then you run personalize to validate and apply them, and bootstrap to deploy the full environment.

### Why the config file approach

Your name, email, GitHub username, and project details are personal — they should never be committed to the repo. config.env is gitignored so your details stay local. config.env.example is the committed template that shows anyone cloning this repo what values they need to fill in.

### Step 1 — Fill in config.env

    cp config.env.example config.env
    nano config.env

Fill in all five values:

- DOTFILES_USER_NAME: your full name, used for git commit attribution
- DOTFILES_USER_EMAIL: your email, must match your GitHub account
- DOTFILES_GITHUB_USERNAME: your GitHub username, used in clone URLs
- DOTFILES_WINDOWS_USERNAME: your Windows login name (the folder name under C:\Users\)
- DOTFILES_FIRST_PROJECT: your first project in p###-name format (e.g. p008-my-project)

To find your Windows username if you are unsure:

    ls /mnt/c/Users/

Save with Ctrl+X, Y, Enter.

### Step 2 — Run personalize

    chmod +x 0_personalize.sh bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh
    ./0_personalize.sh

What personalize does:
- Validates all values in config.env (checks format, checks Windows username exists)
- Configures your git identity (name, email, default branch)
- Creates your first VS Code project folder under 2_vscode/projects/

If any validation fails, it tells you exactly what to fix and exits without making changes.

### Step 3 — Run bootstrap

    ./bootstrap.sh

What bootstrap does, in order:

1. Wipes all modules in reverse dependency order (shell, vscode, conda)
2. Deploys all modules in dependency order (conda, vscode, shell)
3. Runs all module tests and reports pass/fail

Wiping before deploying guarantees a clean state every time. Updates to any module config are always applied on the next bootstrap run.

After bootstrap completes, open a new terminal or restart VS Code, then run:

    source ~/.bashrc

---

## 8. Verify everything works

### What this does

Runs each module's test script to confirm the full environment deployed correctly. Each test is non-destructive — it only checks state and reports pass/fail. Bootstrap runs these automatically but you can run them individually at any time.

    cd ~/repos/dotfiles/1_conda && ./4_test.sh
    cd ~/repos/dotfiles/2_vscode && ./4_test.sh
    cd ~/repos/dotfiles/3_shell && ./4_test.sh

What each test checks:

- conda: Miniforge installed, conda accessible, Python accessible, conda-forge is the only channel
- vscode: VS Code accessible from WSL, settings files exist, all extensions installed
- shell: bash is default shell, config block in ~/.bashrc, all aliases defined, env vars set

All tests should pass. If any fail, the error message tells you exactly which script to run to fix it.

---

## 9. Ongoing workflow

### Saving your VS Code state

Whenever you change settings or install new extensions, snapshot and commit:

    cd ~/repos/dotfiles
    ./2_vscode/1_save.sh
    git status
    git add -A
    git commit -m "chore: snapshot vscode env $(date +%Y-%m-%d)"
    git push

### Saving your shell config

Whenever you update ~/.bashrc outside of the deploy script:

    cd ~/repos/dotfiles
    ./3_shell/1_save.sh
    git status
    git add -A
    git commit -m "chore: snapshot shell config $(date +%Y-%m-%d)"
    git push

### Deploying to a new machine

    git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/repos/dotfiles
    cd ~/repos/dotfiles
    chmod +x 0_personalize.sh bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh
    cp config.env.example config.env
    nano config.env
    ./0_personalize.sh
    ./bootstrap.sh

### Adding a new project

1. Create a folder under 2_vscode/projects/:

    mkdir -p 2_vscode/projects/p###-your-project
    touch 2_vscode/projects/p###-your-project/settings.json
    touch 2_vscode/projects/p###-your-project/extensions.txt

2. Add workspace settings and project-specific extensions
3. Deploy with:

    ./2_vscode/3_deploy.sh p###-your-project

### Wiping and redeploying a single module

If one module breaks, you can wipe and redeploy it independently without touching the others:

    cd ~/repos/dotfiles/1_conda && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
    cd ~/repos/dotfiles/2_vscode && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh
    cd ~/repos/dotfiles/3_shell && ./2_wipe.sh && ./3_deploy.sh && ./4_test.sh

---

## 10. System test

### What this does

Verifies the full deploy pipeline works end to end by cloning a fresh copy and running bootstrap. Do this after significant changes to the repo or before sharing it with someone new.

### Full system test

    mv ~/repos/dotfiles ~/repos/dotfiles.bak               # rename current folder as backup
    git clone git@github.com:YOUR_USERNAME/dotfiles.git ~/repos/dotfiles
    cd ~/repos/dotfiles
    chmod +x 0_personalize.sh bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh
    cp config.env.example config.env
    nano config.env                                         # fill in your values
    ./0_personalize.sh
    ./bootstrap.sh

    rm -rf ~/repos/dotfiles.bak                            # clean up if test passed
    # mv ~/repos/dotfiles.bak ~/repos/dotfiles             # restore if test failed

### Smoke test (quick check without full redeploy)

    cd ~/repos/dotfiles
    git status                                             # repo is clean and up to date
    git log --oneline -5                                   # recent commits look correct
    diff 2_vscode/global/extensions.txt <(code --list-extensions | sort | grep -v '^Extensions')
    ls -la 2_vscode/*.sh                                   # scripts are executable

---

## 11. Nuclear rebuild

### What this does

Complete wipe and rebuild from zero — Windows, WSL, VS Code, conda, and shell config all removed and reinstalled. Use this when something is fundamentally broken and you want a guaranteed clean state.

### Phase 1 — Windows cleanup (manual)

These steps must be done on Windows before touching WSL.

1. Uninstall VS Code: Settings, Apps, Installed Apps, search "Visual Studio Code", Uninstall
2. Delete C:\Users\YOUR_WINDOWS_USERNAME\AppData\Roaming\Code (VS Code user data)
3. Delete C:\Users\YOUR_WINDOWS_USERNAME\.vscode (installed extensions)
4. Uninstall Ubuntu: open PowerShell as Administrator and run:

    wsl --unregister Ubuntu

   This completely removes the Ubuntu installation including all files inside WSL.

5. Restart Windows

### Phase 2 — Reinstall WSL and VS Code (manual)

6. Open PowerShell as Administrator and run:

    wsl --install -d Ubuntu

7. Restart Windows when prompted
8. Ubuntu opens automatically — create your username and password
9. Download and install VS Code from code.visualstudio.com — check "Add to PATH"
10. Open VS Code, install the WSL extension: Extensions (Ctrl+Shift+X), search "WSL", install

### Phase 3 — Configure WSL (manual, one-time)

These steps set up the base Linux environment before the repo can do its work.

11. Open Ubuntu from the Start menu and run:

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git build-essential

12. Generate SSH key and add to GitHub (see step 4 for full details):

    ssh-keygen -t ed25519 -C "you@example.com"
    cat ~/.ssh/id_ed25519.pub

    Copy the output and add it to GitHub, Settings, SSH and GPG keys, New SSH key.

### Phase 4 — Clone, personalize, and bootstrap (automated from here)

From this point forward everything is handled by the repo.

13. Clone this repo:

    cd ~
    mkdir repos && cd repos
    git clone git@github.com:YOUR_USERNAME/dotfiles.git
    cd dotfiles

14. Make scripts executable:

    chmod +x 0_personalize.sh bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh

15. Fill in your personal config:

    cp config.env.example config.env
    nano config.env

    To find your Windows username: ls /mnt/c/Users/

16. Run personalize — validates your config and sets git identity:

    ./0_personalize.sh

17. Run bootstrap — wipes, deploys, and tests all modules in the correct order:

    ./bootstrap.sh

18. Open a new terminal or restart VS Code, then run:

    source ~/.bashrc

### Phase 5 — Verify

19. Run each module test:

    cd ~/repos/dotfiles/1_conda && ./4_test.sh
    cd ~/repos/dotfiles/2_vscode && ./4_test.sh
    cd ~/repos/dotfiles/3_shell && ./4_test.sh

All tests should pass. If any fail, check the error message — each failure tells you exactly which script to run to fix it.

---

## Repo structure

    dotfiles/
    ├── README.md                                          <- this runbook
    ├── CONTRIBUTING.md                                    <- standards and conventions
    ├── config.env.example                                 <- template for personal config (committed)
    ├── config.env                                         <- your personal config (gitignored, never committed)
    ├── .gitignore                                         <- excludes config.env and other personal files
    ├── 0_personalize.sh                                   <- validates config.env and applies personal settings
    ├── bootstrap.sh                                       <- wipes, deploys, and tests all modules in order
    ├── 1_conda/                                           <- Python environment module
    │   ├── 0_setup.sh                                     <- prerequisites check
    │   ├── 1_save.sh                                      <- snapshot environments to repo
    │   ├── 2_wipe.sh                                      <- clean uninstall of Miniforge
    │   ├── 3_deploy.sh                                    <- install Miniforge and conda-forge
    │   ├── 4_test.sh                                      <- validate conda state
    │   └── environments/                                  <- saved environment .yml definitions
    ├── 2_vscode/                                          <- VS Code module
    │   ├── 0_setup.sh                                     <- prerequisites check
    │   ├── 1_save.sh                                      <- snapshot settings and extensions to repo
    │   ├── 2_wipe.sh                                      <- clean uninstall of extensions and settings
    │   ├── 3_deploy.sh                                    <- install extensions and deploy settings
    │   ├── 4_test.sh                                      <- validate VS Code state
    │   ├── global/
    │   │   ├── settings.json                              <- global editor settings
    │   │   ├── keybindings.json                           <- global keybindings
    │   │   ├── extensions.txt                             <- curated extension list (machine-readable)
    │   │   ├── extensions.snapshot                        <- live installed extensions (auto-generated)
    │   │   └── extensions.md                              <- extension reference with descriptions and docs
    │   └── projects/
    │       └── p008-arcane-predictive/                    <- example project config
    │           ├── settings.json                          <- workspace-level settings overrides
    │           └── extensions.txt                         <- project-specific extensions
    └── 3_shell/                                           <- shell config module
        ├── 0_setup.sh                                     <- prerequisites check, backs up ~/.bashrc with rotation
        ├── 1_save.sh                                      <- snapshot shell config to repo
        ├── 2_wipe.sh                                      <- remove dotfiles block from ~/.bashrc, backs up with rotation
        ├── 3_deploy.sh                                    <- deploy aliases and env vars to ~/.bashrc
        ├── 4_test.sh                                      <- validate shell config state
        └── config/
            └── .bashrc                                    <- saved shell config snapshot

---

## Projects

### p008-arcane-predictive

MTG trading company (Arcane Predictive). Python/data stack. See 2_vscode/projects/p008-arcane-predictive/ for workspace settings and extensions. This folder serves as an example of how to add a project to your dotfiles.
