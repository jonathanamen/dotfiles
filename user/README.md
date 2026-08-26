# user/ — the no-admin, no-WSL deploy

The same dotfiles, for a machine where you are **not a local administrator** and WSL is not
available. Everything here installs into your own user profile and touches nothing that needs
elevation.

## A WSL machine may need one module from here

The tree as a whole is for a machine with no WSL, and that is still what `bootstrap.ps1` is for. But
**`1_conda` is also the way a WSL machine gets a Windows interpreter**, and one job needs that:
building the EDOM executable. PyInstaller does not cross-compile — it bundles the interpreter and
libraries of the machine it runs on, so a Linux host produces a Linux binary and a Windows artifact
must be built by a Windows Python. ENIAC and ANGLACHEL run their citizens inside WSL and still need
this module's half of the install to produce an exe.

Run that one module on its own, never the whole bootstrap:

```powershell
cd user\1_conda
.\0_setup.ps1     # checks only
.\3_deploy.ps1    # miniforge to %LOCALAPPDATA%, shared packages, then windows-packages.txt
```

**In a normal PowerShell window, not an elevated one.** `0_setup.ps1` refuses an elevated shell on
purpose: conda installed under an administrator token lands machine-wide and is not on your PATH.
This was found the hard way — an assistant session installed miniforge with `winget --scope user`
from an elevated shell and it went to `C:\ProgramData` with a machine-wide registry entry, which is
not the path the grid documents (`%LOCALAPPDATA%\miniforge3`) and not what `machine.python_exe()`
looks for.

### Reading 4_test.ps1 on a WSL machine

`4_test.ps1` will report the base packages -- fastembed, sqlite-vec, flask, pdfplumber,
matplotlib, openpyxl, python-pptx and nflreadpy -- as failures and exit 1 there, and on a WSL
machine **that is expected rather than broken**. Those are the grid's retrieval and harness dependencies, and on a WSL machine the grid
runs on `~/miniforge3/bin/python3` inside WSL, where the root `1_conda` module installs them. The
Windows interpreter exists on that machine for one job, and the line that answers whether it can do
it is the build-toolchain block, which is reported separately and never counted as a failure.

On a `platform: windows` machine there is no WSL to hold them, the grid itself runs on this
interpreter, and those failures are real.

## Why a second tree and not a flag

The modules at the repo root are bash scripts targeting a Linux userland: `1_conda` fetches the
Linux Miniforge behind `sudo apt install wget`, `4_node` runs `sudo apt install nodejs npm`,
`5_annex` installs `git-annex` the same way. Those are not options that a switch can turn off —
they are a different operating system. Note that it is the `sudo apt` and the Linux binaries that
separate the trees, not bash itself: this tree now writes a `~/.bashrc` too, for Git Bash, which
is Windows-native and needs no elevation. A flag would have meant a conditional in every script and two
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
| `3_shell` | yes | Both shells: the PowerShell profile *and* `~/.bashrc` for Git Bash. See below |
| `4_azure_cli` | yes | Az PowerShell module from PSGallery, into the user's module path. No elevation |
| `5_pac_cli` | yes | Power Platform CLI (`pac`) via winget |
| `4_node` | **no counterpart** | Node is only here for Claude Code, which this deploy does not use |
| `5_annex` | **no counterpart** | `git-annex` has no user-scope Windows install, and this machine is not an L0 backup target |

`bootstrap.ps1` deploys all five that say yes, in that order.

### Which shell you land in

`3_shell` deploys the same configuration twice: to the PowerShell profile, and to `~/.bashrc` for
**Git Bash**. Both stay working, and **PowerShell stays the default**. Nothing in this repo sets
`terminal.integrated.defaultProfile.windows`, so a dev who prefers bash sets it themselves:

```json
"terminal.integrated.defaultProfile.windows": "Git Bash"
```

The reason both are deployed is that a Git Bash terminal otherwise starts with nothing — no conda
on PATH, no TDBI bin, no aliases — so choosing bash used to mean choosing a worse environment.
Now it does not, and the choice is a preference rather than a downgrade.

Git Bash is worth supporting because it ships with Git for Windows, installs per-user with no
elevation, and gives a real POSIX shell on a machine that has no WSL, which is the same constraint
the whole `user/` tree exists to satisfy. The scripts themselves stay PowerShell: they run once at
deploy, and rewriting them would buy nothing a dev can see.

Three managed blocks land on the bash side, each with its own markers and its own presence check:
the main block and the TDBI PATH block in `~/.bashrc`, and a sourcing line in `~/.bash_profile`.
That last one is not optional. Git Bash opens a **login** shell, which reads `.bash_profile` and
never touches `.bashrc` on its own, so without it everything else is written correctly and loaded
by nothing.

`HOME` matters here. Git Bash takes it from `%USERPROFILE%` unless something already set it, which
is where `3_deploy.ps1` writes. If your `HOME` points elsewhere, Git Bash reads a different file
than the one the deploy wrote, and `0_setup.ps1` says so rather than letting you find out later.

The bash files are written with LF endings and no BOM, through .NET rather than `Add-Content`.
Windows PowerShell 5.1 gives you CRLF and a BOM, and bash answers a CRLF `.bashrc` with
``$'\r': command not found`` on every line it manages to read. `4_test.ps1` checks for stray CR
bytes for exactly that reason, and then launches a real login shell to confirm `python` resolves
to the dotfiles Miniforge -- because a file that reads correctly and loads into nothing is the
failure mode this module keeps producing.

**The slot numbers do not pair with the root tree.** `4_azure_cli` is not a Windows `4_node` and
`5_pac_cli` is not a Windows `5_annex`; the root tree's 4 and 5 have no counterpart here at all,
and these two have none there. The number orders this tree's own bootstrap and says nothing about
the other side.

Because there is no annex module here, this machine declares `backup_remote: false` in its machine file,
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
    .\0_personalize.ps1    <- asks eight questions, writes config.env and the machine file
    .\bootstrap.ps1

`0_personalize.ps1` **asks** rather than making you hand-edit `config.env`, unlike the bash
`0_personalize.sh` at the repo root. On a machine with no WSL and possibly no editor configured
yet, "open config.env and fill it in" is a worse first instruction than a short interview.
Re-running it offers your current values as defaults, so pressing Enter through it changes nothing.

It asks eight: your name, email, GitHub username, Windows username, the GitHub directory, which AI
extension this machine deploys, whether a git-annex backup remote is available, and your first
project. The last three are the ones a hand-edited `config.env` most often ends up missing, and two
of them are what TDBI reads to learn what this machine can do.

It also writes `TDBI/config/machine.local.json` — this machine's capabilities, recorded where the
grid reads them. If TDBI is not cloned yet (the normal case on a fresh machine) it prints the file
and where to put it, which is why the order below works either way.

Or one module at a time, exactly like the root tree:

    cd user\1_conda; .\2_wipe.ps1; .\3_deploy.ps1; .\4_test.ps1

`0_setup.ps1` in each module checks prerequisites and changes nothing.
