function Update-NodePackageManager {
    & npm i -g npm@latest
}

function Update-AngularCli {
    & npm install -g @angular/cli@latest
}

function New-AngularRoot([string]$rootName) {
    & ng new $rootName --style=scss --createApplication=false --skip-git --skip-install
}

function New-AngularApp([string]$appName) {
    & ng new $appName --directory . --style=scss --routing --skip-git --skip-install
}

function New-AngularApplication([string]$appName) {
    & ng g application $appName --style=scss --routing --skip-install
}

function New-AngularDemoApplication([string]$appName) {
    & ng g application $appName --style=scss --routing --minimal --skip-install
}

function New-AngularLibrary([string]$libName) {
    & ng g library $libName --skip-install
}
