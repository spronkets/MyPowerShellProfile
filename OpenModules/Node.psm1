function Install-NodePackageManager {
  & npm i -g npm@latest
}

Set-Alias -Name Install-NPM -Value Install-NodePackageManager

function Install-VueCli {
  & npm install -g @vue/cli
}

function Install-SvelteCli {
  & npm install -g sv@latest
  if ($LASTEXITCODE -ne 0) {
    throw "Svelte CLI installation failed with exit code $LASTEXITCODE."
  }
}

function Install-AngularCli {
  & npm install -g @angular/cli@latest
}

function New-AngularRoot([string]$rootName) {
  & ng new $rootName --style=scss --createApplication=false --skip-git --skip-install @args
}

function New-AngularApp([string]$appName) {
  & ng new $appName --directory . --style=scss --routing --skip-git --skip-install @args
}

function New-AngularApplication([string]$appName) {
  & ng g application $appName --style=scss --routing --skip-install @args
}

function New-AngularDemoApplication([string]$appName) {
  & ng g application $appName --style=scss --routing --minimal --skip-install @args
}

function New-AngularLibrary([string]$libName) {
  & ng g library $libName --skip-install @args
}
