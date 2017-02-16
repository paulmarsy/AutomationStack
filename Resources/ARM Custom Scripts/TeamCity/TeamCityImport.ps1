try {
    & net use T: \\#{StorageAccountName}.file.core.windows.net\teamcity /USER:"#{StorageAccountName}" "#{StorageAccountKey}" *>&1 | Write-Log

    "{0}[ Prepare TeamCity Data Import ]{0}" -f ("-"*34) | Write-Log
    $archivePath = 'D:\TeamCityData.zip'
    Compress-Archive -Path 'T:\*' -DestinationPath $archivePath -CompressionLevel Fastest

    "{0}[ Prepare maintainDb Environment ]{0}" -f ("-"*33) | Write-Log
    $dataPath = "${env:ALLUSERSPROFILE}\JetBrains\TeamCity"

    if (Test-Path $dataPath) {
        Remove-Item $dataPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path $dataPath
    New-Item -Path (Join-Path $dataPath 'lib\jdbc') -ItemType Directory
    Copy-Item -Path 'T:\lib\jdbc\sqljdbc42.jar' -Destination (Join-Path $dataPath 'lib\jdbc')
    
    $databaseConfig = 'T:\config\database.properties'
    [System.IO.File]::WriteAllText($DatabaseConfig, ([System.IO.File]::ReadAllText($DatabaseConfig, [System.Text.Encoding]::UTF8)), [System.Text.Encoding]::ASCII)

    [System.Environment]::SetEnvironmentVariable('TEAMCITY_DATA_PATH', $dataPath, [System.EnvironmentVariableTarget]::Process)


    "{0}[ Starting TeamCity Import ]{0}" -f ("-"*36) | Write-Log
    & "${env:SystemDrive}\TeamCity\bin\maintainDB.cmd" restore -F $archivePath -T $databaseConfig

    "{0}[ Restore TeamCity Data Directory ]{0}" -f ("-"*32) | Write-Log
    if (Test-Path (Join-Path $dataPath 'config')) {
        Remove-Item -Path (Join-Path $dataPath 'config') -Recurse -Force 
    }
    Copy-Item -Recurse -Force -Path (Join-Path $exportPath 'config') -Destination $dataPath
}
finally {
    & net use T: /DELETE /Y *>&1 | Write-Log
}