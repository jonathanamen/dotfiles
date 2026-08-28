# personal_overlay

Personal-only additions layered on top of a team dotfiles deploy (e.g. `dotfiles-team`), for
machines that run both. Not part of `bootstrap.ps1` on purpose -- this runs standalone, and always
AFTER whichever team slug is deployed, never before.

**Siloed from the team repo by design.** Nothing here edits, hooks into, or is even referenced by
`dotfiles-team`. It only reads/patches what a team deploy already wrote (`%APPDATA%\Code\User\settings.json`,
the PowerShell profile, `.bashrc`) and adds to it -- a team repo stays fully independent and
editable with zero awareness this exists.

## What it does

| Step | Adds |
|---|---|
| Settings merge | Patches the keys in `settings-overlay.json` into the live `settings.json`, leaving every other key (including whatever the team deploy wrote) untouched |
| `..\5_pac_cli\3_deploy.ps1` | Power Platform CLI, reused as-is |
| `..\3_shell\3_deploy.ps1` | TDBI citizen shims/PATH, reused as-is -- already safe to run after a team shell deploy: every block it writes checks its OWN marker before appending, so it skips the main nav/listing block a team deploy already supplied and still adds the TDBI-specific blocks (see that script's own comments) |

## Usage

```powershell
.\0_setup.ps1     # checks only
.\3_deploy.ps1    # merge settings, install pac_cli, add TDBI shell bits
.\4_test.ps1      # verify
.\2_wipe.ps1      # remove ONLY what this overlay added -- never touches the team's own blocks/keys
```

## Why settings needs a real merge, not the marker trick

The shell scripts get to reuse a marker-delimited block because a block is either present or not.
Settings is one JSON object with no such boundary, and both `dotfiles-team` and this repo's own
`2_vscode\3_deploy.ps1` write it with a flat `Copy-Item ... -Force` -- whichever deploy runs last
wins the whole file. `3_deploy.ps1` here does a real merge instead: read the live file, set only
`settings-overlay.json`'s keys, write it back. `2_wipe.ps1` is the same operation in reverse --
remove only those keys, leave the rest exactly as the team deploy left it.
