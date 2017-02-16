param($LogFileName, $StorageAccountName, $StorageAccountKey)

$teamcityStateFile =  "${env:SystemDrive}\TeamCity\firstrun.statefile"     
if (Test-Path $teamcityStateFile) { throw 'TeamCity Configuration Already Run' }

. (Join-Path -Resolve $PSScriptRoot '\Shared\CustomScriptLogging.ps1') -LogFileName $LogFileName -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

& (Join-Path -Resolve $PSScriptRoot '\Shared\AutomationNodeCompliance.ps1')
& (Join-Path -Resolve $PSScriptRoot '\TeamCity\TeamCityImport.ps1')

"{0}[ Starting TeamCity Service ]{0}" -f ("-"*35) | Write-Log
& "${env:SystemDrive}\TeamCity\bin\teamcity-server.bat" service install /runAsSystem *>&1 | Write-Log
Start-Service TeamCity -Verbose *>&1 | Write-Log

"{0}[ Finished ]{0}" -f ("-"*44) | Write-Log
[System.IO.FIle]::WriteAllText($teamcityStateFile, (Get-Date -Format 'u'), [System.Text.Encoding]::ASCII)
Send-SignalTerminate