function Import-Chocolatey {
  $ChocolateyProfile = "$env:ChocolateyInstall/helpers/chocolateyProfile.psm1"
  if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
  }
}

function Install-Chocolatey {
  & Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  if (-not (Find-Chocolatey)) {
    throw 'Chocolatey installation did not produce a usable choco executable. Check the installer output before retrying.'
  }
  Import-Chocolatey
}

function Find-Chocolatey {
  $command = Get-Command choco -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($command) {
    return $command.Source
  }

  $roots = @($env:ChocolateyInstall, [Environment]::GetEnvironmentVariable('ChocolateyInstall', 'Machine'), "$env:ProgramData\chocolatey") | Where-Object { $_ }
  foreach ($root in $roots) {
    $candidate = Join-Path $root 'bin\choco.exe'
    if (Test-Path $candidate) {
      $env:ChocolateyInstall = $root
      $env:Path = "$(Join-Path $root 'bin');$env:Path"
      return $candidate
    }
  }

  return $null
}

function Update-Chocolatey {
  $choco = Find-Chocolatey
  if (-not $choco) {
    throw "Chocolatey was not found. If 'Install-Chocolatey' reports an existing installation, the folder at $env:ProgramData\chocolatey is incomplete: back it up, delete it, and run Install-Chocolatey again."
  }

  & $choco upgrade chocolatey -y
  if ($LASTEXITCODE -ne 0) {
    throw "Chocolatey upgrade failed with exit code $LASTEXITCODE."
  }
  Import-Chocolatey
}

function Invoke-ChocolateyUpdateAll {
  & choco upgrade all -y
}

function Enable-IisHosting {
  $ErrorActionPreference = 'Stop'
  & dism.exe /Online /Enable-Feature /FeatureName:IIS-WebServerRole /FeatureName:IIS-StaticContent /All /NoRestart
  if ($LASTEXITCODE -eq 3010) {
    throw 'IIS installation requires a Windows restart. Restart Windows, then rerun the .NET installation or update.'
  }
  if ($LASTEXITCODE -ne 0) {
    throw "IIS installation failed with exit code $LASTEXITCODE. Run PowerShell as Administrator and check the DISM output for details."
  }

  $featureInfo = & dism.exe /Online /Get-FeatureInfo /FeatureName:IIS-StaticContent /English
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to verify IIS installation with DISM (exit code $LASTEXITCODE)."
  }
  if (-not ($featureInfo -match '^\s*State\s*:\s*Enabled\s*$')) {
    throw 'IIS Static Content is not enabled. Check the DISM output and restart Windows if the feature is pending, then retry.'
  }
}

function Install-Dotnet {
  & choco install dotnet-sdk -y
  if ($LASTEXITCODE -notin @(0, 1641, 3010)) {
    throw ".NET installation failed with exit code $LASTEXITCODE. Check the Chocolatey output for details."
  }
}

function Update-Dotnet {
  & choco upgrade dotnet-sdk -y
  if ($LASTEXITCODE -notin @(0, 1641, 3010)) {
    throw ".NET upgrade failed with exit code $LASTEXITCODE. Check the Chocolatey output for details."
  }
}

function Install-DotnetWindowsHosting {
  Enable-IisHosting

  & choco install dotnet-windowshosting -y
  if ($LASTEXITCODE -notin @(0, 1641, 3010)) {
    throw ".NET Windows Hosting installation failed with exit code $LASTEXITCODE. Check the Chocolatey output for details."
  }
}

function Update-DotnetWindowsHosting {
  Enable-IisHosting

  & choco upgrade dotnet-windowshosting -y
  if ($LASTEXITCODE -notin @(0, 1641, 3010)) {
    throw ".NET Windows Hosting upgrade failed with exit code $LASTEXITCODE. Check the Chocolatey output for details."
  }
}

if (Find-Chocolatey) {
  Import-Chocolatey
}
else {
  Install-Chocolatey
}
