# user/ — the no-admin, no-WSL deploy

The same dotfiles, for a machine where you are **not a local administrator** and WSL is not
available. Everything here installs into your own user profile and touches nothing that needs
elevation.

## Why a second tree and not a flag

The modules at the repo root are bash scripts targeting a Linux userland: `1_conda` fetches the
Linux Miniforge behind `sudo apt install wget`, `3_shell` writes `~/.bashrc`, `4_node` runs
`sudo apt install nodejs npm`. Those are not options that a switch can turn off — they are a
different operating system. A flag would have meant a conditional in every script and two
untested paths through each one.

What is genuinely shared is the **configuration data**, and that is not duplicated here:

| Shared file | Read by |
|---|---|
| `../config.env` | every module, same as the root tree |
| `../1_conda/base-packages.txt` | `user/1_conda/3_deploy.ps1` |
| `../2_vscode/global/settings.json`, `keybindings.json`, `extensions.txt` | `user/2_vscode/3_deploy.ps1` |

Only the scripts differ. Edit a setting once and both platforms get it.

## What is here, and what is deliberately not

| Module | Status | Note |
|---|---|---|
| `1_conda` | yes | Miniforge, "Just Me", into `%LOCALAPPDATA%\miniforge3` |
| `2_vscode` | yes | Settings, keybindings and extensions into `%APPDATA%\Code\User` |
| `3_shell` | yes | PowerShell profile, the counterpart of `~/.bashrc` |
| `4_node` | **no** | Node is only here for Claude Code, which this deploy does not use |
| `5_annex` | **no** | `git-annex` has no user-scope Windows install, and this machine is not an L0 backup target |

Because there is no `5_annex`, this machine declares `backup_remote: false` in its machine file,
and TDBI's evidence gate warns rather than blocks. That is the designed behaviour for a machine
with nowhere to copy L0 content to, not a workaround.

## Where to clone the repos

Clone into the Documents folder **Windows reports**, not `%USERPROFILE%\Documents`. OneDrive
redirects Documents on most machines, and on a redirected one those are two different folders:

```powershell
[Environment]::GetFolderPath('MyDocuments')    # the real one
```

`mkdir -Force` on the assumed path does not fail on a redirected machine — it silently creates a
second Documents that Explorer never shows under that name. The repos then work perfectly and sync
nowhere, which is only noticed when someone goes looking for the folder.

`0_personalize.ps1` reads the real path and offers it as the default. Take the default.

## Prerequisites you install by hand, once

None of these need administrator rights. Install them before running `bootstrap.ps1`.

| Tool | How |
|---|---|
| VS Code | The **User Installer** (`VSCodeUserSetup-x64-*.exe`), not the System Installer |
| Git | Run the Git for Windows installer as a normal user; it installs per-user. `PortableGit` also works |
| SSH keys | Windows ships OpenSSH. Keys go in `%USERPROFILE%\.ssh`, not in WSL |

If SSH to `github.com` on port 22 is blocked or throttled on the network, put this in
`%USERPROFILE%\.ssh\config`:

    Host github.com
      Hostname ssh.github.com
      Port 443

## Running it

    cd user
    .\0_personalize.ps1    <- asks four questions, writes config.env and the machine file
    .\bootstrap.ps1

`0_personalize.ps1` **asks** rather than making you hand-edit `config.env`, unlike the bash
`0_personalize.sh` at the repo root. On a machine with no WSL and possibly no editor configured
yet, "open config.env and fill it in" is a worse first instruction than four questions. Re-running
it offers your current values as defaults, so pressing Enter through it changes nothing.

It also writes `TDBI/config/machine.local.json` — this machine's capabilities, recorded where the
grid reads them. If TDBI is not cloned yet (the normal case on a fresh machine) it prints the file
and where to put it, which is why the order below works either way.

Or one module at a time, exactly like the root tree:

    cd user\1_conda; .\2_wipe.ps1; .\3_deploy.ps1; .\4_test.ps1

`0_setup.ps1` in each module checks prerequisites and changes nothing.
