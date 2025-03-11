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

function Show-Menu {
  param (
    [string[]]$Items
  )

  $selectedIndex = 0
  while ($true) {
    Clear-Host
    Write-Host "Multiple .sln files found. Please select one (use arrow keys and press Enter):`r`n"

    for ($i = 0; $i -lt $Items.Count; $i++) {
      if ($i -eq $selectedIndex) {
        Write-Host "> $($Items[$i])" -ForegroundColor Green
      }
      else {
        Write-Host "  $($Items[$i])"
      }
    }

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode

    if ($key -eq 38) {
      # Up arrow
      $selectedIndex = [math]::Max(0, $selectedIndex - 1)
    }
    elseif ($key -eq 40) {
      # Down arrow
      $selectedIndex = [math]::Min($Items.Count - 1, $selectedIndex + 1)
    }
    elseif ($key -eq 13) {
      # Enter key
      return $selectedIndex
    }
  }
}

Clear-Host

Write-Host "Welcome to PowerShell $($PSVersionTable.PSVersion), $($env:USERNAME)." -ForegroundColor Gray
Write-Host

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
  Import-Module "$ChocolateyProfile"
}
