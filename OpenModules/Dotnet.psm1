function dev {
  if (Test-Path 'D:\dev\' -PathType Container) {
    Set-Location 'D:\dev\' -ErrorAction Stop
  }
  elseif (Test-Path 'C:\dev\' -PathType Container) {
    Set-Location 'C:\dev\' -ErrorAction Stop
  }
  else {
    throw 'Neither D:\dev\ nor C:\dev\ exists.'
  }
}

function vs {
  $solutions = @(Get-ChildItem -File -Recurse -Depth 2 -ErrorAction Stop |
    Where-Object { $_.Extension -in '.sln', '.slnx' })

  if ($solutions.Count -eq 0) {
    Write-Host 'No .sln or .slnx files found.'
    return
  }

  $solution = if ($solutions.Count -eq 1) {
    $solutions[0]
  }
  else {
    $selectedIndex = Show-Menu -Items $solutions.FullName
    $solutions[$selectedIndex]
  }

  Write-Host "Opening solution: $($solution.FullName)"
  Start-Process -FilePath $solution.FullName -ErrorAction Stop
}

function vsc {
  & code . @args
}

function dd {
  Get-Date -Format "yyyyMMddHHmmss"
}

function dt {
  & dotnet test @args
}

function clean {
  [CmdletBinding(SupportsShouldProcess)]
  param ()

  $findArtifactDirectories = {
    param ([string]$Path, [bool]$IsRoot)

    foreach ($directory in Get-ChildItem -LiteralPath $Path -Directory -Force -ErrorAction Stop) {
      if ($directory.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        continue
      }

      if ($directory.Name -in 'bin', 'obj' -or
        ($IsRoot -and $directory.Name -in 'artifacts', 'TestResults')) {
        $directory
      }
      else {
        & $findArtifactDirectories $directory.FullName $false
      }
    }
  }

  $directories = @(& $findArtifactDirectories (Get-Location).Path $true)
  foreach ($directory in $directories) {
    if ($PSCmdlet.ShouldProcess($directory.FullName, 'Remove build artifacts')) {
      Remove-Item -LiteralPath $directory.FullName -Force -Recurse -ErrorAction Stop
    }
  }
}

function dr {
  dotnet restore @args
}

function drn {
  dotnet restore --no-cache @args
}

function Invoke-MsBuildForProject([string]$projectPath, [string]$config = "Debug") {
  Write-Host "Building '$projectPath'..." -ForegroundColor White
  msbuild $projectPath /t:Clean /m /p:Configuration=$config
  nuget restore $projectPath -NoCache
  msbuild $projectPath /t:ReBuild /m /p:Configuration=$config
  if (! $?) {
    $ErrorMsg = ($_ | Out-String);
    throw "Failed to build '$projectPath'. $ErrorMsg"
  }
  else {
    Write-Host "Sucessfully built '$projectPath'." -ForegroundColor Green
  }
}

function Stop-MsBuildProcesses {
  Write-Host "Engaging the enemy..." -NoNewline -ForegroundColor White
  Stop-Process -processname msbuild -ErrorAction SilentlyContinue
  Write-Host " Hostiles eliminated!" -ForegroundColor Green
}

function Stop-DotnetWebAppPool([string]$appPoolName) {
  $status = (Get-WebAppPoolState $appPoolName).Value
  $stopped = $status -eq "Stopped"
  if (!$stopped) {
    Stop-WebAppPool $appPoolName
    while (!$stopped) {
      $status = (Get-WebAppPoolState $appPoolName).Value
      $stopped = $status -eq "Stopped"
    }
  }
}
