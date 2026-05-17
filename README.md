# dotfiles

Dev environment management repo. Follow this runbook top to bottom on any fresh Windows 11 machine and you will end up fully set up — WSL, Git, conda, VS Code, and all project configs deployed.

Written to be readable, not just runnable. Each command has an explanation so you understand what you are doing and why. Every step tells you what it does, why it matters, and what to expect.

## Table of contents

1. Wipe and reinstall VS Code
2. Prerequisites
3. Install VS Code
4. Install WSL
5. Configure your Linux environment
6. Install and configure Git
7. Clone this repo
8. Personalize and deploy
9. Verify everything works
10. Ongoing workflow
11. System test
12. Nuclear rebuild

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

If anything is missing, run 2_vscode/1_save.sh first before wiping.

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

- Windows 11 (any edition)
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

## 3. Install WSL

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

## 4. Configure your Linux environment

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

## 5. Install and configure Git

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

## 6. Clone this repo

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

## 7. Connect VS Code to WSL

From your WSL terminal inside the dotfiles folder:

```bash
code .
```

The first time you run this, VS Code installs a small server component inside WSL. After that, VS Code opens on Windows but everything runs in Linux. Verify the connection by checking the bottom-left corner of VS Code — it should say "WSL: Ubuntu".

---

## 8. Personalize and deploy

### Step 1 — Fill in config.env

```bash
cp config.env.example config.env
nano config.env
```

Fill in all five values:

- DOTFILES_USER_NAME: your full name
- DOTFILES_USER_EMAIL: your email, must match your GitHub account
- DOTFILES_GITHUB_USERNAME: your GitHub username
- DOTFILES_WINDOWS_USERNAME: your Windows login name (the folder name under C:\Users)
- DOTFILES_FIRST_PROJECT: your first project in p###-name format

Save with Ctrl+X, Y, Enter.

### Step 2 — Run personalize

```bash
chmod +x 0_personalize.sh bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh
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

## 9. Verify everything works

```bash
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/1_conda && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/2_vscode && ./4_test.sh
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles/3_shell && ./4_test.sh
```

All tests should pass. If any fail, the error message tells you exactly which script to run to fix it.

---

## 10. Ongoing workflow

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
chmod +x 0_personalize.sh bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh
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
```

---

## 11. System test

```bash
mv /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles.bak
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub
git clone git@github.com:YOUR_USERNAME/dotfiles.git
cd dotfiles
chmod +x 0_personalize.sh bootstrap.sh 1_conda/*.sh 2_vscode/*.sh 3_shell/*.sh
cp config.env.example config.env
nano config.env
./0_personalize.sh
./bootstrap.sh

rm -rf /mnt/c/Users/YOUR_WINDOWS_USERNAME/Documents/GitHub/dotfiles.bak   # clean up if test passed
```

---

## 12. Nuclear rebuild

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
│   └── projects/
│       └── p008-arcane-predictive/
└── 3_shell/                      <- shell config module
    ├── 0_setup.sh
    ├── 1_save.sh
    ├── 2_wipe.sh
    ├── 3_deploy.sh
    ├── 4_test.sh
    └── config/
        └── .bashrc
```

---

## Projects

### p008-arcane-predictive

MTG trading company (Arcane Predictive). Python/data stack. See 2_vscode/projects/p008-arcane-predictive/ for workspace settings and extensions.
