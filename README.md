# OpenPowerShellProfile
This is my PowerShell Profile, open-sourced primarily for my own re-use and potentially be of some help to others.

`vs`
Opens the first .sln file found with Visual Studio.

`vsc`
Opens the current folder with Visual Studio Code.

`dev`
Opens the dev folder.

`dt`
Prints the current date in the format 'yyyyMMddHHmmss'.

## OpenModules
Modules that are created by me to separate functionality and purpose.

Installed Modules/Scripts aren't included in this repository. Run the following commands:

```PowerShell
# Posh-Git - https://github.com/dahlbyk/posh-git
Install-Module posh-git # Update-Module posh-git
```

### GitModule
This module provides some extended Git functionality.

`gite`
Quickly open Git Extensions in the current directory.

`git-reset`
Reset immediate changes.

`pull`
Pull latest, provide a branch name to merge those changes into your current branch.

`pull-all`
Pull latest for all Git repositories in the current folder.

`stash`
Stashes all current changes

`pop`
Gets the last stash.

`branch`
Creates a branch with the bugfix, feature, release, hotfix paradigm with just the first letter. Ex: `branch f/my-new-stuff`.

`push`
Pushes the current branch given a message to origin. Won't commit .json or .config files automatically, must pass with `-allowConfigs`. Also won't push directly to a develop/master branch without `-override`. Ex: `push 'my new stuff' -ac -o`.

### DotnetModule

### ChocolateyModule

## PrivateModules
Custom Modules that will automatically be imported. Modules intended to be used for work, personal projects, etc.
