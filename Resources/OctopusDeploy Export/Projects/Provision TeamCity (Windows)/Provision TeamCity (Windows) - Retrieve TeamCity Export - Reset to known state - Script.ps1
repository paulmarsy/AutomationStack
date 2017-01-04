Stop-Service TeamCity -Force

if (Test-Path $ExportPath) {
    Remove-Item $ExportPath -Recurse -Force
}
New-Item -ItemType Directory -Path $ExportPath

if (Test-Path $TeamCityDataDir) {
    Remove-Item $TeamCityDataDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TeamCityDataDir
