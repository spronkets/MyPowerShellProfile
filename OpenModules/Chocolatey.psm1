function Import-Chocolatey {
    $ChocolateyProfile = "$env:ChocolateyInstall/helpers/chocolateyProfile.psm1"
    if (Test-Path($ChocolateyProfile)) {
        Import-Module "$ChocolateyProfile"
    }
}

Import-Chocolatey

function Install-Chocolatey {
    & Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Import-Chocolatey
}

function Invoke-ChocolateyUpdateAll {
    & choco upgrade all -y
}

function Install-DotnetCore {
    # .NET Core 2.2 SDK
    & choco install dotnetcore-sdk
    # .NET Core 2.2 runtime
    # IIS .NET Core Module
    & choco install dotnetcore-windowshosting
}
