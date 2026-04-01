# eclipse-scripts

Bulk Git and GitHub helper commands for Eclipse-related repositories.

## Requirements

1. Install [GitHub CLI](https://cli.github.com/).
2. Make sure `git`, `gh`, and PowerShell (`powershell` or `pwsh`) are available on your `PATH`.

## Calling the functions directly

Load [`lib.ps1`](./lib.ps1) and call the function you want. All configuration parameters are optional and are passed when you dot-source the file.

These examples assume you keep this repository at `$HOME/dev/eclipse-scripts`, which works well across Windows, Linux, and macOS:

```powershell
. "$HOME/dev/eclipse-scripts/lib.ps1"
fetchAll
```

Default values:

- `GitFolder`: `"$PSScriptRoot\..\platform-master2\git"`
- `GhUsername`: `"fedejeanne"`
- `RemoteName`: `"origin"`
- `UserRemoteName`: defaults to `GhUsername`

Pass custom configuration when loading the file:

```powershell
. "$HOME/dev/eclipse-scripts/lib.ps1" -GitFolder "$HOME/git" -GhUsername myuser -UserRemoteName myfork
fetchAll
```

## Available functions

```powershell
syncFork
cleanGone
addRemotes
fetchRemoteBranches
fetchAll
switchToMaster
switchToTaggedVersion "I20260318-1800"
switchToBranch "R4_35_maintenance"
changeForksToHTTPS
```

## Add functions to your PowerShell profile

This is the recommended setup if you want short commands available in every PowerShell session.

PowerShell can load a personal startup script every time a new session opens. That startup script is called your profile.

The `$PROFILE` variable contains the full path to that file on your machine.

Run this to edit (or create) your profile file:

```powershell
if (!(Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force }
```

Then open the file in an editor and add shortcut functions like these:

```powershell
function eclipse-fetch-all {
    . "$HOME/dev/eclipse-scripts/lib.ps1" -GitFolder "$HOME/git"
    fetchAll
}
```

```powershell
function eclipse-clean-gone {
    . "$HOME/dev/eclipse-scripts/lib.ps1" -GitFolder "$HOME/git"
    cleanGone
}
```

```powershell
function eclipse-switch-branch {
    param([string]$Branch)
    . "$HOME/dev/eclipse-scripts/lib.ps1" -GitFolder "$HOME/git"
    switchToBranch $Branch
}
```

Save the file, then reload it in your current shell:

```powershell
. $PROFILE
```

That command tells PowerShell to run the profile file right away, so you do not need to close and reopen the terminal.

After that, you can invoke your shortcuts directly:

```powershell
eclipse-fetch-all
eclipse-clean-gone
eclipse-switch-branch R4_37_maintenance
```

## Notes

- The script operates on every repository directly under `GitFolder`.
- Only directories that actually contain a `.git` folder are processed.
- `SwitchToMaster`, `SwitchToTaggedVersion`, and `SwitchToBranch` perform destructive Git operations such as `checkout -f`, `reset --hard`, and `clean -df`.
