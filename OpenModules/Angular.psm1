function Install-AngularCLI {
    & npm install -g @angular/cli
}

function Update-NodePackageManager {
    & npm i -g npm
}

function New-AngularApp([string]$appName) {
    & ng new $appName --directory . --style=scss --minimal --routing  --skip-git --skip-install
}
