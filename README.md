# MyPowerShellProfile
This is my PowerShell Profile, open-sourced primarily for my own re-use and potentially be of some reference to others.

### Cloning
1. Open PowerShell
2. Navigate to your Documents folder
3. Rename, move, or delete your existing WindowsPowerShell folder
4. Clone this repository into the Documents folder using your preferred Git toolset

Ex:
```PowerShell
%UserProfile%\Documents > git clone https://github.com/kcrossman/MyPowerShellProfile.git WindowsPowerShell
```

5. If you renamed or moved your existing WindowsPowerShell folder, migrate your desired commands/functionality into your own module(s) within the PrivateModules folder.

*Note: The profile will automatically attempt to import them they are .ps[m]1 files in either the OpenModules or PrivateModules folders...*

### Basic Commands
There will be a few basic commands within the profile itself. These may belong in another module., but haven't been moved yet.

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

### AngularModule
TODO

### ChocolateyModule
TODO

### DockerModule
TODO

### DotnetModule
TODO

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

## PrivateModules
Custom Modules that will automatically be imported but not checked in to this repository. This is intended for Modules to enhance personal projects, work, etc.
