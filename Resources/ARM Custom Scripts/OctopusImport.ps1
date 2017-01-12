if (!(Test-Path 'C:\CustomScriptLogs')) { New-Item -ItemType Directory -Path 'C:\CustomScriptLogs' | Out-Null }

$logFile = 'C:\CustomScriptLogs\{0}.log' -f ([datetime]::UtcNow.tostring('o').Replace(':','.').Substring(0,19))

# Force DSC to run... a hack as DSC isn't reliably reporting node compliance 
# Find and kill the WmiPrvSE.exe process hosting the DSC Engine
Get-WmiObject msft_providers | ? { $_.provider -like 'dsccore' } | select -ExpandProperty HostProcessIdentifier | % {
    $process = Get-Process -Id $_
    Write-Output "Killing DSC Host Process $($process.Name) ($_). Process was running since $($process.StartTime.ToString())"
    $process | Stop-Process -Force
}  *>> $logFile
Write-Output 'Updating DSC Configuration...'     *>> $logFile
Update-DscConfiguration -Wait -Verbose *>> $logFile *>> $logFile

# Octopus Deploy Initial Data Import
& net use O: \\#{StackresourcesName}.file.core.windows.net\octopusdeploy /u:#{StackResourcesName} #{StackResourcesKey} *>> $logFile
& "C:\Program Files\Octopus Deploy\Octopus\Octopus.Migrator.exe" import --console --directory="O:\" --password=#{StackAdminPassword} --overwrite *>> $logFile

Copy-Item -Path $logFile -Destination O:\CustomScript.log -Force *>> $logFile

& net use O: /DELETE *>> $logFile