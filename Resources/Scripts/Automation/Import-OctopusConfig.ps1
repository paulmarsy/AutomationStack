param($Path, $InfraRg, $AutomationAccountName, $VMName, $ConnectionString, $OctopusHostName, $OctopusVersionToInstall)

& (Join-Path $PSScriptRoot 'Import-DSCConfiguration.ps1') -Path $Path -ResourceGroupName $InfraRg -AutomationAccountName $AutomationAccountName -ConfigurationName 'OctopusDeploy' -Parameters @{
    OctopusNodeName = $VMName
    ConnectionString = $ConnectionString
    HostHeader = ('http://{0}/' -f $OctopusHostName)
    FullyQualifiedUrl = ('http://{0}:80/' -f $OctopusHostName)
    OctopusVersionToInstall = $OctopusVersionToInstall
}