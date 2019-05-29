Set-Alias find 'C:/Program Files/git/usr/bin/find.exe'

# Posh-Git - https://github.com/dahlbyk/posh-git
Import-Module posh-git

# Git Extensions - https://github.com/gitextensions/gitextensions
function gite {
    & 'C:/Program Files (x86)/GitExtensions/GitExtensions.exe' 
}

function git-reset {
    & git fetch
    & git reset --hard HEAD~1
    & git clean -d -f
    & git pull
}

function pull {
    param (
        [alias("b")]
        [string] $branchName
    )
	
    if (![string]::IsNullOrEmpty($branchName)) {
        & git pull origin $branchName
    }
    else {
        & git pull
    }
}

function pull-all {
    Write-Host "Running the Git Pull All tool..."
    Write-Host "Note: This tool will call 'git pull' for each git repository under it." -ForegroundColor Cyan

    Push-Location .
    Write-Host "`r`nParent Directory: $PSScriptRoot" -ForegroundColor Cyan

    foreach ($path in Get-ChildItem) {
        if ($path.Attributes -eq "Directory") {
            Write-Host "`r`nChild Directory: $($path.FullName)" -ForegroundColor Cyan
            Set-Location $path.FullName
            if (& git rev-parse --is-inside-git-dir) {
                Write-Host "Getting latest... " -ForegroundColor Green
                & pull
            }
            else {
                Write-Host "This is not a Git Repository. Skipping..." -ForegroundColor Yellow
            }
        }
    }
    
    Pop-Location
}

function stash {
    & git stash -u
}

function pop {
    & git stash pop
}

function branch {
    param (
        [alias("b")]
        [string] $branchName
    )
	
    if ($branchName.StartsWith("b/")) {
        $branchName = "bugfix/$($branchName.Remove(0,2))"
    }
    elseif ($branchName.StartsWith("f/")) {
        $branchName = "feature/$($branchName.Remove(0,2))"
    }
    elseif ($branchName.StartsWith("r/")) {
        $branchName = "release/$($branchName.Remove(0,2))"
    }
    elseif ($branchName.StartsWith("h/")) {
        $branchName = "hotfix/$($branchName.Remove(0,2))"
    }
    
    & git checkout -b $typeText$branchName
    Write-Host "& git checkout -b $typeText$branchName"
}

function push {
    param (
        [alias("m")]
        [string] $message,
        [alias("ac")]
        [switch] $allowConfigs,
        [alias("o")]
        [switch] $override
    )

    $branch = (& git rev-parse --abbrev-ref HEAD).Trim()

    if (!$branch) {
        throw [System.ArgumentException] "Can't push to a non-branch!"
    }

    if ($branch -ieq "master" -or $branch -ieq "develop") {
        if ($override -eq $true) {
            Write-Host "WARNING!!! You just pushed directly to master/develop!" -ForegroundColor Yellow
        }
        else {
            throw [System.ArgumentException] "Not allowed to push directly to master/develop!"
        }
    }

    if (![string]::IsNullOrEmpty($message)) {
        & git add -A
        
        if ($allowConfigs -ne $true) {
            & git reset *.json
            & git reset *.config
        }

        & git commit -m $message
        & git commit --amend -m $message
    }
    
    & git push --set-upstream origin $branch
    Write-Host "& git push --set-upstream origin $branch" -ForegroundColor Cyan
}
