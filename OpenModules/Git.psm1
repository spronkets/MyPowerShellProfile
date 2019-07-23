Set-Alias find 'C:/Program Files/git/usr/bin/find.exe'

# Posh-Git - https://github.com/dahlbyk/posh-git
Import-Module posh-git

# Git Extensions - https://github.com/gitextensions/gitextensions
function gite {
    & 'C:/Program Files (x86)/GitExtensions/GitExtensions.exe' 
}

# Helper Functions
function Test-DirectoryIsGitRepository {
    [boolean]$isGitRepository = git rev-parse --is-inside-work-tree 2>/dev/null
    return $isGitRepository
}

function Get-GitBranchName {
    $isGitRepository = Test-DirectoryIsGitRepository
    if ($isGitRepository) {
        $branchName = (& git rev-parse --abbrev-ref HEAD).Trim()
        Write-Host "Branch Name: $branchName" -ForegroundColor Gray
        return $branchName
    }
    return $null
}

function Get-GitLastRemoteHash {
    $branchName = Get-GitBranchName
    if ($branchName) {
        $lastRemoteHash = git rev-parse origin/$branchName
        Write-Host "Last Remote Hash: $lastRemoteHash" -ForegroundColor Gray
        return $lastRemoteHash
    }
    return $null
}

function git-merge {
    param (
        [alias("b")]
        [string] $branchName
    )

    if (!$branchName) {
        $branchName = Get-GitBranchName
    }

    if ($branchName) {
        & git pull origin $branchName
    }
    else {
        throw [System.ArgumentException] "Can't merge a non-branch!"
    }
}

function git-reset {
    $lastRemoteHash = Get-GitLastRemoteHash
    if ($lastRemoteHash) {
        & git fetch
        & git reset --hard $lastRemoteHash
    }
    else {
        throw [System.ArgumentException] "Can't reset a non-branch!"
    }
}

function pull {
    param (
        [alias("b")]
        [string] $branchName
    )
	
    if (![string]::IsNullOrEmpty($branchName)) {
        & git-merge $branchName
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
                & git pull
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
    
    & git checkout -b $branchName
    Write-Host "& git checkout -b $branchName"
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

    $branchName = Get-GitBranchName

    if (!$branchName) {
        throw [System.ArgumentException] "Can't push to a non-branch!"
    }

    if ($branchName -ieq "master" -or $branchName -ieq "develop") {
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
    
    & git push --set-upstream origin $branchName
}
