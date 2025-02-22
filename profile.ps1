# More PowerShell functionality with my Gists (https://gist.github.com/kcrossman)

function Import-ModuleInternal([string]$moduleFullPath) {
  $moduleName = [regex]::Match($moduleFullPath, "^.*[\/\\](\w+).ps[m]?1$").Captures.Groups[1].Value
  try {
    Import-Module $moduleFullPath -DisableNameChecking -Force
    Write-Host "Imported '$moduleName'." -ForegroundColor Gray
  }
  catch {
    Write-Host "Failed to import '$moduleName'." -ForegroundColor Red
  }
}

function Import-ModulesInternal([string]$modulesTargetDir) {
  Write-Host "Importing '$modulesTargetDir'..."
  $modulesPath = Join-Path $PSScriptRoot $modulesTargetDir
  Get-ChildItem $modulesPath -Recurse -Include '*.psm1', '*.ps1' |
  ForEach-Object {
    Import-ModuleInternal $_.FullName
  }
}

Import-ModulesInternal "OpenModules"
Import-ModulesInternal "PrivateModules"

function Add-ToEnvPath {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$pathToAdd,

    [Parameter(Position = 1)]
    [ValidateSet("Machine", "User", "Session")]
    [string]$pathLocation = "Session"
  )

  Write-Host "Adding location ('$pathToAdd') to $pathLocation path..." -ForegroundColor White

  if ($pathLocation -ne "Session") {
    $envPath = [Environment]::GetEnvironmentVariable("Path", $pathLocation)
    $currentEnvPath = $envPath -split ";"

    if ($currentEnvPath -notcontains $pathToAdd) {
      $currentEnvPath += $pathToAdd
      $envPath = ($currentEnvPath -join ";") -replace ";;", ";"
      [Environment]::SetEnvironmentVariable("Path", $envPath, $pathLocation)
      Write-Host "Location added." -ForegroundColor Cyan
    }
    else {
      Write-Host "Location already exists." -ForegroundColor Cyan
    }
  }

  $env:Path += ";$pathToAdd"
  Write-Host "Location added to PowerShell session." -ForegroundColor Gray
}

Clear-Host

Write-Host "Welcome to PowerShell $($PSVersionTable.PSVersion), $($env:USERNAME)." -ForegroundColor Gray
Write-Host

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
  Import-Module "$ChocolateyProfile"
}
