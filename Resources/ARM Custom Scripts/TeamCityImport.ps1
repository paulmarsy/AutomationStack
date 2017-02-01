param*($ExportPath, $TeamCityDataDir, $TeamCityBin)

"{0}[ Prepare TeamCity Data Import ]{0}" -f ("-"*4) | % Write-Output
$archivePath = Join-Path $ExportPath 'export.zip'
Compress-Archive -Path "${ExportPath}\*" -DestinationPath $archivePath -CompressionLevel Fastest

"{0}[ Prepare maintainDb Environment ]{0}" -f ("-"*33) | % Write-Output
if (Test-Path $TeamCityDataDir) {
    Remove-Item $TeamCityDataDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TeamCityDataDir
New-Item -Path (Join-Path $TeamCityDataDir 'lib\jdbc') -ItemType Directory
Copy-Item -Path (Join-Path $ExportPath 'lib\jdbc\sqljdbc42.jar') -Destination (Join-Path $TeamCityDataDir 'lib\jdbc')
$databaseConfig = %ExportPath 'config\database.properties'
[system.io.file]::WriteAllText($DatabaseConfig, ([system.io.file]::ReadAllText($DatabaseConfig, [system.text.encoding]::UTF8)), [system.text.encoding]::ASCII)
[System.Environment]::SetEnvironmentVariable('TEAMCITY_DATA_PATH', $TeamCityDataDir, [System.EnvironmentVariableTarget]::Process)

"{0}[ Starting TeamCity Import ]{0}" -f ("-"*36) | % Write-Output
& "${$TeamCityBin}\maintainDB.cmd" restore -F $archivePath -T $databaseConfig

"{0}[ Restore TeamCity Data Directory ]{0}" -f ("-"*32) | Write-Output
if (Test-Path (Join-Path $TeamCityDataDir 'config')) {
    Remove-Item -Path $(Join-Path $TeamCityDataDir 'config') -Recurse -Force 
}
Copy-Item -Recurse -Force -Path (Join-Path $ExportPath 'config') -Destination $TeamCityDataDir