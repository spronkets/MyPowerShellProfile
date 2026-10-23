# MyPowerShellProfile

A Windows PowerShell profile with helpers for Git, .NET, Chocolatey, Docker, Angular, Node.js, and Vue.

## Setup and startup

PowerShell editions and hosts can use different profile folders. The paths below are defaults; Documents may be redirected to OneDrive or another location. In each shell, check `$PROFILE` for the current-host profile and `$PROFILE.CurrentUserAllHosts` for the profile shared by that edition's hosts.

| Application / shell | Typical current-user profile location | Notes |
|---|---|---|
| Windows PowerShell 5.1 console | `Documents\WindowsPowerShell\profile.ps1` | Separate from PowerShell 7. |
| PowerShell 7 console | `Documents\PowerShell\profile.ps1` | This repository's usual clone location. |
| VS Code PowerShell extension | Depends on the selected PowerShell edition and host | The extension runs Windows PowerShell 5.1 or PowerShell 7. Its VS Code-specific profile is typically `Microsoft.VSCode_profile.ps1` in that edition's profile folder. When profile loading is enabled, the edition's all-host profile can also run. |

The repository only affects a shell when that shell loads its `profile.ps1`. To share this profile with VS Code, for example, put the repository in the selected edition's profile directory and make sure profile loading is enabled, or dot-source the repository's `profile.ps1` from the VS Code-specific profile. A PowerShell 7 folder does not automatically affect Windows PowerShell 5.1, and vice versa.

1. Open the target shell and check `$PROFILE` and `$PROFILE.CurrentUserAllHosts` to find its actual profile paths.
2. Back up any existing profile folder before replacing it.
3. Clone this repository into the appropriate profile directory. For example, for PowerShell 7:

   ```powershell
   git clone https://github.com/kcrossman/MyPowerShellProfile.git PowerShell
   ```

4. Move personal modules into [PrivateModules](./PrivateModules).
5. Ensure the target shell loads [profile.ps1](./profile.ps1). You can also load it explicitly, adjusting the path for your Documents location and edition:

   ```powershell
   . "$HOME\Documents\PowerShell\profile.ps1"
   ```

The profile recursively imports `.ps1` and `.psm1` files from [OpenModules](./OpenModules) and [PrivateModules](./PrivateModules), clears the screen, and prints a welcome message.

**Startup side effects:**

- The Chocolatey module checks for Chocolatey, installs it if missing, and imports its profile if available.
- The Git module installs posh-git if missing and imports it. It does not update an existing installation automatically.
- Missing dependencies may require network access, repository confirmation, and Administrator permissions. Once installed, startup does not intentionally run package upgrades.
- The profile reports failed module imports, but does not print the underlying exception.

## Function reference

The tables below cover functions defined by this repository, not commands supplied by third-party modules or external programs. Modules do not restrict their exports, so helper functions are also available; they are listed separately where appropriate.

Arguments in square brackets are optional. Examples assume the profile has loaded successfully.

### Profile utilities

Source: [profile.ps1](./profile.ps1).

| Function / syntax | Behavior |
|---|---|
| `Import-ModuleInternal -moduleFullPath <path>` | Imports one module or script using `-Force -DisableNameChecking`. Prints success or failure. Despite its name, it remains callable in the profile session. |
| `Import-ModulesInternal -modulesTargetDir <folder>` | Recursively imports `.ps1` and `.psm1` files from a folder relative to the profile directory. Used for `OpenModules` and `PrivateModules`. |
| `Show-Menu -Items <string[]>` | Interactive arrow-key menu; Enter returns the selected zero-based index. Clears the screen and displays a solution-file prompt. Requires an interactive console supporting `ReadKey`; does not provide a cancel action. |

### Chocolatey and .NET installation

Source: [Chocolatey.psm1](./OpenModules/Chocolatey.psm1).

Run installation, upgrade, and IIS setup commands from **Administrator PowerShell**. Package operations require access to the configured Chocolatey sources. Unversioned package names track the latest versions available there, potentially including new major .NET releases.

| Function | Behavior |
|---|---|
| `Install-Chocolatey` | Downloads and executes the Chocolatey bootstrap script, verifies that `choco` can be found, then imports Chocolatey's profile. Sets execution policy to Bypass for the current process. Does not overwrite or delete an incomplete installation automatically. |
| `Update-Chocolatey` | Locates Chocolatey, runs `choco upgrade chocolatey -y`, and imports its profile. Throws if the executable is missing or the upgrade exits nonzero. |
| `Invoke-ChocolateyUpdateAll` | Runs `choco upgrade all -y`, upgrading all installed Chocolatey packages, not just Chocolatey itself. |
| `Install-Dotnet` | Installs only `dotnet-sdk` with `-y`. Does not enable IIS or install its Hosting Bundle. |
| `Update-Dotnet` | Upgrades only `dotnet-sdk` with `-y`. |
| `Install-DotnetWindowsHosting` | Enables and verifies IIS, then installs `dotnet-windowshosting` with `-y`. Separate from SDK installation. |
| `Update-DotnetWindowsHosting` | Enables and verifies IIS, then upgrades `dotnet-windowshosting` with `-y`. |
| `Enable-IisHosting` | Uses native `dism.exe` to enable `IIS-WebServerRole` and `IIS-StaticContent` with dependencies. Verifies Static Content is enabled. Throws on failure or a required restart; never restarts Windows automatically. |
| `Find-Chocolatey` | Helper returning the executable path or `$null`. Searches PATH, process/machine `ChocolateyInstall`, and `%ProgramData%\chocolatey`. When found outside PATH, sets process `ChocolateyInstall` and prepends its `bin` directory to the session PATH. |
| `Import-Chocolatey` | Imports `helpers\chocolateyProfile.psm1` under `$env:ChocolateyInstall` if present. Does not install Chocolatey. |

The four .NET package commands accept exit codes `0`, `1641`, and `3010`; other codes throw. Check Chocolatey's output for reboot requirements. If IIS setup requests a restart, restart Windows and rerun the hosting command before proceeding.

```powershell
Install-Dotnet
Update-Dotnet

# Only needed for hosting ASP.NET Core applications in IIS:
Install-DotnetWindowsHosting
Update-DotnetWindowsHosting

Update-Chocolatey
```

### .NET development and workspace shortcuts

Source: [Dotnet.psm1](./OpenModules/Dotnet.psm1).

Install the tools needed by each command: .NET SDK, Visual Studio/MSBuild, NuGet CLI, VS Code CLI, or IIS PowerShell administration commands. They are not all installed by loading this module.

| Function / syntax | Behavior |
|---|---|
| `dev` | Changes to `D:\dev\` if that folder exists; otherwise uses `C:\dev\` if it exists. Errors if neither folder exists or the selected folder cannot be opened. |
| `vs` | Searches the current directory and descendants using `-Depth 2` for `.sln` and `.slnx` files. Opens a single result directly or uses `Show-Menu` to select among multiple results. Prints a message if none is found. Uses the Windows file association; associate both extensions with Visual Studio. Search and launch errors are surfaced. |
| `vsc` | Runs `code .` to open the current directory in VS Code. Forwards extra arguments, for example `vsc --new-window`. |
| `dd` | Returns the current local timestamp formatted as `yyyyMMddHHmmss`. |
| `dt` | Runs `dotnet test` in the current directory. Forwards supplied arguments, for example `dt --no-build` or `dt .\Example.Tests.csproj`. |
| `clean [-WhatIf] [-Confirm]` | **Destructive:** removes all `bin` and `obj` directories below the current directory, plus root-level `artifacts` and `TestResults`, including hidden contents. Preserves source, solution/project files, and `.vs`. Skips linked directories and stops on discovery or deletion errors. Close running builds/apps and check your working directory first; use `clean -WhatIf` to preview. |
| `dr` | Runs `dotnet restore` in the current directory and forwards extra arguments, for example `dr .\Example.sln --verbosity detailed`. |
| `drn` | Runs `dotnet restore --no-cache` and forwards extra arguments. |
| `Invoke-MsBuildForProject -projectPath <path> [-config <configuration>]` | Runs MSBuild Clean, NuGet restore with `-NoCache`, then MSBuild ReBuild with parallel builds. Configuration defaults to `Debug`. Checks the final command's result. |
| `Stop-MsBuildProcesses` | **Disruptive:** force-stops processes named `msbuild`, potentially affecting unrelated builds. |
| `Install-VisualStudioTemplates` | Installs the latest stable Functions isolated-worker project and item template packages using `dotnet new install`. Standard .NET 10 templates come with the SDK and are not installed separately. Stops on an installation failure. |
| `Update-VisualStudioTemplates` | Runs `dotnet new update` for installed template packages, not just those in the install function. Forwards extra arguments, for example `Update-VisualStudioTemplates --check-only`. Requires an SDK supporting this command. |
| `Stop-DotnetWebAppPool -appPoolName <name>` | Stops the named IIS application pool and polls until its state is `Stopped`. Requires `Get-WebAppPoolState`/`Stop-WebAppPool` and appropriate IIS permissions. Has no polling timeout. |

Use the .NET 10 SDK for .NET 10 projects. ASP.NET Core (`webapi`, `mvc`, `webapp`), Blazor (`blazor`, `blazorwasm`), console, library, and test templates are [included in the SDK](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-new-sdk-templates). Inspect available templates with `dotnet new list`, and choose `--framework net10.0` when supported.

Additional packages installed by `Install-VisualStudioTemplates`:

- [Microsoft.Azure.Functions.Worker.ProjectTemplates](https://www.nuget.org/packages/Microsoft.Azure.Functions.Worker.ProjectTemplates)
- [Microsoft.Azure.Functions.Worker.ItemTemplates](https://www.nuget.org/packages/Microsoft.Azure.Functions.Worker.ItemTemplates)

Despite the function name, these are .NET CLI template packages, not Visual Studio extensions. Functions templates have their own framework options and release lifecycle. The function no longer installs legacy WebJobs, .NET Core 2.2/3.0 web/SPA, standalone Blazor, or PowerShell Standard module templates. It does not uninstall previously installed templates; inspect them with `dotnet new uninstall` and remove unwanted packages explicitly with `dotnet new uninstall <package-id>`. Updating SDK-bundled templates requires updating the SDK, not `Update-VisualStudioTemplates`.

```powershell
vs
Invoke-MsBuildForProject -projectPath 'C:\dev\Example\Example.sln' -config Release
```

### Git

Source: [Git.psm1](./OpenModules/Git.psm1).

Requires Git on PATH. Loading this module imports [posh-git](https://github.com/dahlbyk/posh-git) and defines the `find` alias for `C:\Program Files\git\usr\bin\find.exe`.

| Function / syntax | Behavior |
|---|---|
| `Install-PoshGit` | Installs posh-git if missing; otherwise explicitly runs `Update-Module posh-git`. Startup calls this only when the module is absent. |
| `gite` | Launches Git Extensions from the hard-coded `C:\Program Files (x86)\GitExtensions\GitExtensions.exe`. |
| `Test-DirectoryIsGitRepository` | Returns the Boolean conversion of `git rev-parse --is-inside-work-tree` output. Intended for checking the current working directory; not a general repository-validation API. |
| `Get-GitBranchName` | Returns and prints the current branch when the repository helper succeeds; otherwise returns `$null`. Detached HEAD can produce `HEAD`, rather than a branch name. |
| `Get-GitLastRemoteHash` | Resolves and prints the current branch's local `origin/<branch>` tracking hash. Does not fetch first. |
| `git-merge [-branchName <name>]` | Runs `git pull origin <branch>`. Defaults to the current branch. `-b` aliases `-branchName`. This is a pull wrapper, not a direct `git merge` wrapper. |
| `git-reset` | **Destructive:** obtains the current remote-tracking hash, fetches, runs `git clean -d -f`, and hard-resets to the previously obtained hash. Deletes untracked files/directories and discards tracked changes. The reset target is resolved before the fetch. |
| `pull [-branchName <name>]` | Runs plain `git pull` without a branch argument; with a branch, delegates to `git-merge`. Supports `-b`. |
| `pull-all` | Attempts to visit child directories and pull each Git repository. Uses the current location, changes location while iterating, and is not recursive. Directory attribute checks can skip directories with extra attributes; verify results rather than assuming all siblings were updated. |
| `stash` | Runs `git stash -u`, including untracked files but not ignored files. |
| `pop` | Runs `git stash pop`; may produce merge conflicts. |
| `branch -branchName <name>` | Creates and checks out a branch. Expands `b/`, `f/`, `r/`, and `h/` to `bugfix/`, `feature/`, `release/`, and `hotfix/`. Supports `-b`; other names pass through unchanged. Supply a name. |
| `push [-message <text>] [-allowConfigs] [-override]` | Pushes the current branch to origin and sets upstream. With a message, stages all changes, unstages `*.json`/`*.config` unless `-allowConfigs`, creates a commit, then immediately amends that commit with the same message. Blocks `master`/`develop` unless `-override`. Aliases: `-m`, `-ac`, `-o`. |

**Review before using `push`:** it stages broadly, may commit files you did not intend, and does not explicitly stop after a failed commit. If the initial commit fails, its subsequent amend can affect the existing latest commit. Use ordinary Git commands when you need precise staging or commit control.

```powershell
branch f/my-new-feature
pull -b develop
push -m 'Describe the changes' -ac
```

### Angular

Source: [Node.psm1](./OpenModules/Node.psm1), shared with the npm and Vue helpers below. Requires Node.js/npm; generation commands also require Angular CLI (`ng`) on PATH.

| Function / syntax | Behavior |
|---|---|
| `Install-AngularCli` | Globally installs the latest `@angular/cli` with npm. Can also be rerun to obtain the latest CLI. |
| `New-AngularRoot -rootName <name>` | Creates an Angular workspace without an initial application, using SCSS and skipping Git initialization and dependency installation. |
| `New-AngularApp -appName <name>` | Creates a workspace/application in the current directory (`--directory .`) with SCSS and routing, skipping Git initialization and dependency installation. Use an appropriate empty directory. |
| `New-AngularApplication -appName <name>` | Generates an application in an existing Angular workspace with SCSS and routing; skips dependency installation. |
| `New-AngularDemoApplication -appName <name>` | Generates a minimal application in an existing workspace with SCSS and routing; skips dependency installation. |
| `New-AngularLibrary -libName <name>` | Generates a library in an existing Angular workspace; skips dependency installation. |

Run `npm install` separately where required after scaffolding. There is currently no separate `Update-AngularCli` function.

All five `New-Angular*` functions forward extra arguments to `ng` after their preset options. For example, `New-AngularApplication -appName web --prefix demo`. The named workspace/application/library argument is consumed by the wrapper and is not forwarded a second time.

```powershell
Install-AngularCli
New-AngularRoot -rootName demo
Set-Location .\demo
New-AngularApplication -appName web
npm install
```

### Node.js / npm

Source: [Node.psm1](./OpenModules/Node.psm1). Requires an existing Node.js/npm installation; this function does not install Node.js itself.

| Function | Behavior |
|---|---|
| `Install-NodePackageManager` | Runs `npm i -g npm@latest` to install the latest npm globally. |
| `Install-NPM` | Alias for `Install-NodePackageManager`. |

Rerun `Install-NodePackageManager` to update npm. The latest npm may require a newer Node.js version. Global installation permissions depend on your npm configuration.

### Vue

Source: [Node.psm1](./OpenModules/Node.psm1). Requires Node.js/npm.

| Function | Behavior |
|---|---|
| `Install-VueCli` | Globally installs `@vue/cli` using npm. |

Rerun `Install-VueCli` to install the currently published default version.

### Svelte

Source: [Node.psm1](./OpenModules/Node.psm1). Requires Node.js/npm.

| Function | Behavior |
|---|---|
| `Install-SvelteCli` | Globally installs the latest Svelte CLI (`sv`) using `npm install -g sv@latest`. Throws if npm exits nonzero. Rerun to update it. |

After installation, use `sv create my-app` to create an application. The [official CLI](https://svelte.dev/docs/cli/overview) also supports `npx sv create my-app` without a global installation.

### Docker

Source: [Docker.psm1](./OpenModules/Docker.psm1). Requires Docker CLI and a running engine supporting Linux containers. Ensure host ports are free and enough memory/disk space is available. Docker itself is not installed by these commands.

#### Local network and services

Run `Install-DockerLocalnet` before installing the database or Kafka containers. It creates `localnet` with subnet `172.18.0.0/16`; make sure this does not conflict with existing networks.

| Function | Behavior |
|---|---|
| `Install-DockerLocalnet` | Creates `localnet`; an existing network with that name causes Docker to report an error. |
| `Update-DockerLocalnet` | Creates `localnet` only if absent. Does not validate or change an existing network's subnet. |

Each service has separate install and update functions:

| Install function | Update function | Container / IP | Published host ports | Image |
|---|---|---|---|---|
| `Install-DockerSqlServerDb` | `Update-DockerSqlServerDb` | `sqlserver` / `172.18.0.22` | `1433` | `mcr.microsoft.com/mssql/server:latest` (Express edition) |
| `Install-DockerMysqlDb` | `Update-DockerMysqlDb` | `mysql` / `172.18.0.23` | `3306` | `mysql:latest` |
| `Install-DockerPostgresDb` | `Update-DockerPostgresDb` | `postgres` / `172.18.0.24` | `5432` | `postgres:latest` |
| `Install-DockerMongoDb` | `Update-DockerMongoDb` | `mongo` / `172.18.0.25` | `27017` | `mongo:latest` |
| `Install-Kafka` | `Update-Kafka` | `kafka` / `172.18.0.26` | `9092` | `apache/kafka` (implicit `latest`) |
| `Install-DockerOracleDb` | `Update-DockerOracleDb` | `oracle` / `172.18.0.27` | `1521`, `5500` | `gvenzl/oracle-xe:latest` |

All six install functions accept optional `-VolumesFrom <container>` to reuse another container's mounts through Docker's `--volumes-from`; the update helpers use this internally. They use fixed names, IP addresses, and `unless-stopped` restart policies. Repeating an install against an existing container name does not update it.

**Credentials and exposure:** these are development defaults, not production deployments. The module sets database passwords to `Password!2`; PostgreSQL and MongoDB use user `dev`, SQL Server uses `sa`, MySQL uses `root`, and Oracle uses `SYS`/`SYSTEM`. Database and Kafka ports are published without a loopback-only restriction. Change the defaults and restrict network access before use outside a trusted development environment.

**Update limitations:**

- Updates require an existing container. They pull the configured image, stop the container if running, disconnect its networks, and rename it to `<name>-update-backup-<id>`.
- The replacement uses install defaults and reuses the old container's mounts. Custom environment variables, network settings, and other runtime configuration are not copied.
- Retained containers are **not independent data backups**: old and new containers share volumes. Data stored only in a container's writable layer is not transferred. Take application-consistent backups first.
- Floating image tags may introduce incompatible database major versions or changed data paths. Check the image's upgrade instructions before updating.
- Updates cause downtime and do not automatically roll back on failure. Retained containers may need manual network reconnection before recovery. Do not run old and new database containers against the same volume simultaneously.

```powershell
Install-DockerLocalnet
Install-DockerPostgresDb

# Back up data and check image compatibility before updating:
Update-DockerPostgresDb
```

#### Ollama and Open WebUI

| Function / syntax | Behavior |
|---|---|
| `Install-DockerOllama [-OllamaVolume <name>] [-WebUiVolume <name>]` | Creates or reuses Ollama and Open WebUI on `ollama-network`. Defaults to volumes `ollama` and `open-webui`. Configures restart policies, starts stopped services, waits up to 60 seconds for Ollama, and pulls the models listed below. Existing containers may be replaced to enable NVIDIA access or configure local-only, no-login WebUI, retaining stopped prior containers. |
| `Update-DockerOllama` | Pulls `ollama/ollama` and `ghcr.io/open-webui/open-webui:main`, retains the old containers, then recreates both through the install function and refreshes models. Requires both containers and one Docker volume at each expected data mount; reuses their existing volume names. Does not copy arbitrary custom configuration or automatically roll back. |

Installed models:

- `qwen2.5-coder:7b`
- `llama3.1:8b`
- `nomic-embed-text:latest`

Open WebUI is available at **http://localhost:3000**, bound to `127.0.0.1`, with authentication disabled. Ollama publishes port `11434` without a loopback-only restriction. Restrict access appropriately.

NVIDIA acceleration is detected using `nvidia-smi`. When detected, the function requests `--gpus all` and verifies GPU access inside the container. NVIDIA hardware with missing/broken driver tools causes an error rather than silently selecting CPU mode. Without NVIDIA detection it uses CPU mode. Docker Desktop on Windows needs a GPU-capable configuration such as WSL 2.

Model downloads can be large, and initial WebUI startup may take several minutes. The volume-sharing, downtime, and backup caveats above also apply here.

```powershell
Install-DockerOllama
Update-DockerOllama
```

#### Exported Docker update helpers

Prefer the service-specific update functions. These helpers are exported because the module does not define an explicit export list.

| Function / syntax | Behavior |
|---|---|
| `Move-DockerContainerForUpdate -Name <container>` | Checks the container, stops it if running, disconnects all its networks, renames it to a generated backup name, and returns that name. Does not create a replacement or copy data. This directly changes service availability. |
| `Update-DockerContainer -Name <container> -Image <image> -InstallCommand <function>` | Pulls the image, retains the old container through the move helper, then invokes the supplied install function with `-VolumesFrom <backup>`. The install function must support that parameter. Reports the retained name; no automatic rollback. |

## Private modules

[PrivateModules](./PrivateModules) is for personal `.ps1`/`.psm1` files imported at startup and excluded from version control. Keep machine-specific customizations there. Third-party installed modules are separate dependencies and are not documented as repository-defined functions above.
