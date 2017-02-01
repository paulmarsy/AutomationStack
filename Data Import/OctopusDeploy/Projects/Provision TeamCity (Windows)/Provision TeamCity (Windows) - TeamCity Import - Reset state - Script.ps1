Stop-Service TeamCity -Force -ErrorAction Ignore
Start-Process -FilePath "${TeamCityBin}teamcity-server.bat" -UseNewEnvironment -ArgumentList @('service','delete') -Wait -NoNewWindow
if (Test-Path $ExportPath) {
    Remove-Item $ExportPath -Recurse -Force
}
New-Item -ItemType Directory -Path $ExportPath

if (Test-Path $TeamCityDataDir) {
    Remove-Item $TeamCityDataDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TeamCityDataDir
