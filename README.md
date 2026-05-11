# dotfiles

Dev environment management repo. Follow this runbook top to bottom on any fresh Windows 11 machine and you will end up fully set up — WSL, Git, conda, VS Code, and all project configs deployed.

Written to be readable, not just runnable. Each command has an explanation so you understand what you are doing and why.

---

## Table of contents

0. [Wipe and reinstall VS Code](#0-wipe-and-reinstall-vs-code)
1. [Prerequisites](#1-prerequisites)
2. [Install WSL](#2-install-wsl)
3. [Configure your Linux environment](#3-configure-your-linux-environment)
4. [Install and configure Git](#4-install-and-configure-git)
5. [Clone this repo](#5-clone-this-repo)
6. [Install VS Code](#6-install-vs-code)
7. [Deploy your environment](#7-deploy-your-environment)
8. [Verify everything works](#8-verify-everything-works)
9. [Ongoing workflow](#9-ongoing-workflow)
10. [System test](#10-system-test)
11. [Nuclear rebuild](#11-nuclear-rebuild)

---

## 0. Wipe and reinstall VS Code

Follow this section when you want a clean VS Code install on a machine that already has VS Code. Skip to step 1 if you are setting up a brand new machine.

### Pre-wipe checklist

Before uninstalling, confirm the following are saved:

- Extensions are documented in 2_vscode/global/extensions.txt and 2_vscode/global/extensions.md
- Settings are saved in 2_vscode/global/settings.json
- Keybindings are saved in 2_vscode/global/keybindings.json
- Any custom snippets have been exported (File, Preferences, Configure User Snippets)
- Any project workspace configs are saved under 2_vscode/projects/
- All changes are committed and pushed to GitHub

If anything is missing, run 1_save.sh first before wiping.

### Uninstall VS Code

1. Open Windows Settings, go to Apps, click Installed Apps, then search "Visual Studio Code" and click Uninstall
2. After uninstall completes, delete leftover user data:
   - Delete C:\Users\thene\AppData\Roaming\Code
   - Delete C:\Users\thene\.vscode

These folders are not removed by the uninstaller. If you skip this step your old settings will survive the wipe.

Note: Registry cleanup is intentionally skipped — the VS Code uninstaller handles its own registry entries and all user config lives in the filesystem folders above.

### Reinstall VS Code

1. Download the installer from code.visualstudio.com
2. Run the installer and accept defaults
3. Check "Add to PATH" during install — this lets you open VS Code from the terminal
4. Install the WSL extension: open VS Code, go to Extensions (Ctrl+Shift+X), search "WSL", install the Microsoft WSL extension
5. Open your WSL terminal and run:

    cd ~/repos/dotfiles
    code .

6. Deploy your saved environment:

    chmod +x 2_vscode/1_save.sh 2_vscode/3_deploy.sh
    ./2_vscode/3_deploy.sh p008-arcane-predictive

7. Restart VS Code to apply all settings

---

## 1. Prerequisites

Before starting, make sure you have:

- Windows 11 (any edition)
- Administrator access on your machine
- An internet connection
- A GitHub account (you will need this for Git in step 4)

No other software is required. WSL and everything else gets installed in this runbook.

---

## 2. Install WSL

WSL (Windows Subsystem for Linux) lets you run a real Linux environment inside Windows. This is where you will run bash and do all your development work.

Open PowerShell as Administrator (search "PowerShell" in the Start menu, right-click, Run as administrator) and run:

    wsl --install

This installs WSL 2 and Ubuntu (the default Linux distribution) in one command. It will take a few minutes.

Restart your machine when prompted.

After restarting, Ubuntu will finish setting up automatically and open a terminal asking you to create a user account:

    Enter new UNIX username: yourname
    Enter new UNIX password:

Pick a username (lowercase, no spaces) and a password. The password will not show characters as you type — that is normal.

What just happened? You now have a full Ubuntu Linux installation running inside Windows. It has its own filesystem, its own package manager, and its own bash shell. VS Code can connect to it directly.

Verify WSL is running correctly:

    cat /etc/os-release
    echo $SHELL
    # Expected output: /bin/bash

---

## 3. Configure your Linux environment

You are now working inside Ubuntu. These steps set up the basics every Linux environment needs.

### Update the package manager

Ubuntu uses apt to install software. Always update it before installing anything new:

    sudo apt update && sudo apt upgrade -y

sudo means "run as administrator." apt update refreshes the list of available packages. apt upgrade -y installs any updates, with -y auto-confirming.

### Install essential tools

    sudo apt install -y curl wget git build-essential

These are the tools you will reach for constantly. curl and wget download files from the internet. build-essential is a bundle of compilers and tools many packages depend on. git is version control, covered more in step 4.

### Check your bash version

    bash --version

Should show bash 5.x.

---

## 4. Install and configure Git

Git is version control. It tracks changes to your code and lets you push to GitHub. You installed it in step 3; now configure it.

### Set your identity

Git tags every commit you make with your name and email. Set them to match your GitHub account:

    git config --global user.name "Your Name"
    git config --global user.email "you@example.com"

--global means this applies to all repos on this machine, not just one project.

### Set the default branch name

    git config --global init.defaultBranch main

### Set up SSH authentication with GitHub

SSH lets you push and pull from GitHub without typing your password every time.

Generate an SSH key:

    ssh-keygen -t ed25519 -C "you@example.com"

When prompted for a file location, press Enter to accept the default. You can leave the passphrase blank.

This creates two files: ~/.ssh/id_ed25519 (your private key, never share this) and ~/.ssh/id_ed25519.pub (your public key, this is what you give to GitHub).

Copy your public key:

    cat ~/.ssh/id_ed25519.pub

Copy the entire output. Then go to GitHub, Settings, SSH and GPG keys, New SSH key, paste it in, and save.

Test the connection:

    ssh -T git@github.com

You should see: Hi username! You have successfully authenticated...

### Verify your Git config

    git config --list

---

## 5. Clone this repo

    cd ~
    mkdir repos && cd repos
    git clone git@github.com:jonathanamen/dotfiles.git
    cd dotfiles

~ is shorthand for your home directory (/home/yourusername). All your work should live here inside WSL, not in /mnt/c/. WSL can access Windows files but performance is better working natively in the Linux filesystem.

---

## 6. Install VS Code

Install VS Code on Windows (not inside WSL — VS Code runs on Windows but connects into WSL):

1. Download from code.visualstudio.com
2. Run the installer, accept defaults
3. Check "Add to PATH" during install — this lets you open VS Code from the terminal

Install the WSL extension:

Open VS Code, go to Extensions (Ctrl+Shift+X), search "WSL", install the Microsoft WSL extension.

Open VS Code connected to WSL. From your WSL terminal:

    cd ~/repos/dotfiles
    code .

The first time you run "code ." from WSL it installs a small VS Code server inside your Linux environment. After that, VS Code opens on Windows but all file access and terminal sessions run inside WSL.

This is the setup. Your editor is Windows (familiar UI, good performance), your environment is Linux (real bash, real tools). This is how most professional developers on Windows work.

---

## 7. Deploy your environment

Make all scripts executable first (only needed once after cloning):

    chmod +x bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh

Run the full bootstrap to deploy everything in the correct order:

    ./bootstrap.sh

Or deploy individual modules:

    cd 1_conda && ./3_deploy.sh                            # Python environments only
    cd 2_vscode && ./3_deploy.sh p008-arcane-predictive    # VS Code only
    cd 3_shell && ./3_deploy.sh                            # shell config only

Open a new terminal or restart VS Code after bootstrap completes.

---

## 8. Verify everything works

Run each module test:

    cd ~/repos/dotfiles/1_conda && ./4_test.sh
    cd ~/repos/dotfiles/2_vscode && ./4_test.sh
    cd ~/repos/dotfiles/3_shell && ./4_test.sh

All tests should pass. If any fail, the error message tells you exactly which script to run to fix it.

---

## 9. Ongoing workflow

### Saving your VS Code state

Whenever you change settings or install new extensions, snapshot them:

    cd ~/repos/dotfiles
    ./2_vscode/1_save.sh
    git diff
    git add -A
    git commit -m "chore: snapshot vscode env $(date +%Y-%m-%d)"
    git push

### Deploying to a new machine

    git clone git@github.com:jonathanamen/dotfiles.git ~/repos/dotfiles
    cd ~/repos/dotfiles
    chmod +x bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh
    ./bootstrap.sh

### Adding a new project

1. Create a folder under 2_vscode/projects/:

    mkdir -p 2_vscode/projects/your-project-name
    touch 2_vscode/projects/your-project-name/settings.json
    touch 2_vscode/projects/your-project-name/extensions.txt

2. Add workspace settings and extensions
3. Deploy with ./2_vscode/3_deploy.sh your-project-name

---

## 10. System test

Run this to verify the full deploy pipeline works end to end. Do this after any significant changes to the repo or when setting up a new machine.

### Full system test

    mv ~/repos/dotfiles ~/repos/dotfiles.bak               # rename current folder as backup
    git clone git@github.com:jonathanamen/dotfiles.git ~/repos/dotfiles  # clone fresh
    cd ~/repos/dotfiles                                     # move into fresh clone
    chmod +x bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh
    ./bootstrap.sh                                          # run full bootstrap

    # Verify each module:
    cd ~/repos/dotfiles/1_conda && ./4_test.sh
    cd ~/repos/dotfiles/2_vscode && ./4_test.sh
    cd ~/repos/dotfiles/3_shell && ./4_test.sh

    rm -rf ~/repos/dotfiles.bak                            # clean up backup if test passed
    # mv ~/repos/dotfiles.bak ~/repos/dotfiles             # restore backup if test failed

### Smoke test (quick check without full redeploy)

    cd ~/repos/dotfiles
    git status
    git log --oneline -5
    diff 2_vscode/global/extensions.txt <(code --list-extensions | sort | grep -v '^Extensions')
    ls -la 2_vscode/*.sh

---

## 11. Nuclear rebuild

Follow this section when you want to wipe everything and start from scratch. This is the full procedure — Windows, WSL, VS Code, and all dev tools — rebuilt from zero.

### Phase 1 — Windows cleanup (manual)

1. Uninstall VS Code: Settings → Apps → Installed Apps → search "Visual Studio Code" → Uninstall
2. Delete C:\Users\thene\AppData\Roaming\Code
3. Delete C:\Users\thene\.vscode
4. Uninstall Ubuntu WSL — open PowerShell as Administrator and run:

    wsl --unregister Ubuntu

5. Restart Windows

### Phase 2 — Reinstall WSL and VS Code (manual)

6. Open PowerShell as Administrator and run:

    wsl --install -d Ubuntu

7. Restart Windows when prompted
8. Ubuntu will open automatically — create your username and password
9. Download and install VS Code from code.visualstudio.com — check "Add to PATH"
10. Open VS Code, install the WSL extension: Extensions (Ctrl+Shift+X) → search "WSL" → install

### Phase 3 — Configure WSL (manual, one-time)

11. Open Ubuntu from the Start menu and run:

    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git build-essential

12. Configure git identity:

    git config --global user.name "Your Name"
    git config --global user.email "you@example.com"
    git config --global init.defaultBranch main

13. Generate SSH key and add to GitHub (see step 4 for full details):

    ssh-keygen -t ed25519 -C "you@example.com"
    cat ~/.ssh/id_ed25519.pub

    Copy the output and add it to GitHub → Settings → SSH and GPG keys → New SSH key

### Phase 4 — Clone and bootstrap (automated)

14. Clone this repo:

    cd ~
    mkdir repos && cd repos
    git clone git@github.com:jonathanamen/dotfiles.git
    cd dotfiles

15. Make scripts executable:

    chmod +x bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh

16. Run bootstrap:

    ./bootstrap.sh

17. Open a new terminal or restart VS Code, then run:

    source ~/.bashrc

### Phase 5 — Verify

18. Run each module test:

    cd ~/repos/dotfiles/1_conda && ./4_test.sh
    cd ~/repos/dotfiles/2_vscode && ./4_test.sh
    cd ~/repos/dotfiles/3_shell && ./4_test.sh

All tests should pass. If any fail, check the error message — each failure tells you exactly which script to run to fix it.

---

## Repo structure

    dotfiles/
    ├── README.md                                          <- this runbook
    ├── CONTRIBUTING.md                                    <- standards and conventions
    ├── bootstrap.sh                                       <- deploy all modules in order
    ├── 1_conda/                                           <- Python environment module
    │   ├── 0_setup.sh                                     <- prerequisites
    │   ├── 1_save.sh                                      <- snapshot environments
    │   ├── 2_wipe.sh                                      <- clean uninstall
    │   ├── 3_deploy.sh                                    <- full install
    │   ├── 4_test.sh                                      <- validate
    │   └── environments/                                  <- saved environment definitions
    ├── 2_vscode/                                          <- VS Code module
    │   ├── 0_setup.sh                                     <- prerequisites
    │   ├── 1_save.sh                                      <- snapshot settings and extensions
    │   ├── 2_wipe.sh                                      <- clean uninstall
    │   ├── 3_deploy.sh                                    <- full install
    │   ├── 4_test.sh                                      <- validate
    │   ├── global/
    │   │   ├── settings.json                              <- global editor settings
    │   │   ├── keybindings.json                           <- global keybindings
    │   │   ├── extensions.txt                             <- curated extension list
    │   │   ├── extensions.snapshot                        <- live installed extensions
    │   │   └── extensions.md                              <- extension reference with docs
    │   └── projects/
    │       └── p008-arcane-predictive/
    │           ├── settings.json                          <- workspace-level overrides
    │           └── extensions.txt                         <- project-specific extensions
    └── 3_shell/                                           <- shell config module
        ├── 0_setup.sh                                     <- prerequisites
        ├── 1_save.sh                                      <- snapshot shell config
        ├── 2_wipe.sh                                      <- clean uninstall
        ├── 3_deploy.sh                                    <- full install
        ├── 4_test.sh                                      <- validate
        └── config/                                        <- shell config files

---

## Projects

### p008-arcane-predictive

MTG trading company (Arcane Predictive). Python/data stack. See 2_vscode/projects/p008-arcane-predictive/ for workspace settings and extensions.
