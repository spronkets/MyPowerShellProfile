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

function Install-VisualStudioSpaTemplates {
    & dotnet new -i Microsoft.AspNetCore.SpaTemplates::*
    & dotnet new -i Microsoft.AspNetCore.Blazor.Templates
    
    # More dotnet new templates:
    # https://github.com/dotnet/templating/wiki/Available-templates-for-dotnet-new
    # https://dotnetnew.azurewebsites.net/
}
