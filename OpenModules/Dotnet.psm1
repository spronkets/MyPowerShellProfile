function dev {
  & Set-Location "C:\dev\"
}

function vs {
  & ./*.sln
}

function vsc {
  & code .
}

function dt {
  Get-Date -Format "yyyyMMddHHmmss"
}

function clean {
  Get-ChildItem .\ -include bin, obj -Recurse | ForEach-Object ($_) { remove-item $_.fullname -Force -Recurse }
}

function dr {
  dotnet restore
}

function drn {
  dotnet restore --no-cache
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

function Install-VisualStudioTemplates {
  & dotnet new -i Microsoft.Azure.WebJobs.ProjectTemplates
  & dotnet new -i Microsoft.Azure.WebJobs.ItemTemplates
  & dotnet new -i Microsoft.DotNet.Web.ProjectTemplates.2.2
  & dotnet new -i Microsoft.DotNet.Web.ProjectTemplates.3.0
  & dotnet new -i Microsoft.AspNetCore.SpaTemplates
  & dotnet new -i Microsoft.DotNet.Web.Spa.ProjectTemplates.2.2
  & dotnet new -i Microsoft.DotNet.Web.Spa.ProjectTemplates.3.0
  & dotnet new -i Microsoft.AspNetCore.Blazor.Templates
  & dotnet new -i Microsoft.PowerShell.Standard.Module.Template
    
  # More dotnet new templates:
  # https://github.com/dotnet/templating/wiki/Available-templates-for-dotnet-new
  # https://dotnetnew.azurewebsites.net/
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
