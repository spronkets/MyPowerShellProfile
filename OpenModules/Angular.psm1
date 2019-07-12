function Install-AngularCLI {
    & npm install -g @angular/cli
}

function Update-NodePackageManager {
    & npm i -g npm
}

function New-AngularApp([string]$appName) {
    & ng new $appName --directory . --style=scss --routing  --skip-git --skip-install
}

function New-AngularLib([string]$libName) {
    & ng g library $libName --skip-install
}
