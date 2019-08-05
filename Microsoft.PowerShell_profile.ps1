# More PowerShell functionality with my Gists (https://gist.github.com/kcrossman)

function Import-ModuleInternal([string]$moduleFullPath) {
  $moduleName = [regex]::Match($moduleFullPath, "^.*[\/\\](\w+).ps[m]?1$").captures.groups[1].value
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
  Foreach-Object {
    Import-ModuleInternal $_.FullName
  }
}

Import-ModulesInternal "OpenModules"
Import-ModulesInternal "PrivateModules"

function Add-ToEnvPath {
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [String]
    $pathToAdd,
    [Parameter(Position = 1)]
    [ValidateSet("Machine", "User", "Session")]
    [String]
    $pathLocation = "Session"
  )

  Write-Host "Adding location ('$pathToAdd') to $pathLocation path..." -ForegroundColor White

  if ($pathLocation -ne "Session") {
    [String]$envPath = [Environment]::GetEnvironmentVariable("Path", $pathLocation)
    [string[]]$currentEnvPath = @($envPath -split ";")
    if ($currentEnvPath -notcontains $pathToAdd) {
      $currentEnvPath = += $pathToAdd

      $envPath = ($currentEnvPath -join ";") -replace ";;", ";"
      [Environment]::SetEnvironmentVariable("Path", $envPath, $pathLocation)
      Write-Host "Location added." -ForegroundColor Cyan
    }
    else {
      Write-Host "Location already exists." -ForegroundColor Cyan
    }
  }
    
  $env:Path += ";$pathLocation"
  Write-Host "Location added to PowerShell session." -ForegroundColor Gray
}

Clear-Host

$user = [Environment]::UserName

Write-Host "Welcome PowerShell Master, $user." -ForegroundColor Gray
Write-Host

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
