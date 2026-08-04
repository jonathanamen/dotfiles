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
    .\bootstrap.ps1

Or one module at a time, exactly like the root tree:

    cd user\1_conda; .\2_wipe.ps1; .\3_deploy.ps1; .\4_test.ps1

`0_setup.ps1` in each module checks prerequisites and changes nothing.
