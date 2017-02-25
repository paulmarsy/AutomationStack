param($ComputeVmShutdownStatus, $ComputeVmShutdownTime, $OctopusDscConnectionString, $OctopusDscHostName)

Write-Output "Starting DeployOctopusDeploy Runbook..."
$ErrorActionPreference = "Stop"
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Write-Output ("Authenticating with:`n{0}" -f ($ServicePrincipalConnection | Out-String | % Trim))
Add-AzureRmAccount -ServicePrincipal -TenantId $ServicePrincipalConnection.TenantId -ApplicationId $ServicePrincipalConnection.ApplicationId -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint | Out-Null
Write-Output 'Connected to Azure'
$ResourceGroupName = Get-AutomationVariable -Name "ResourceGroupName"
Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName (Get-AutomationVariable -Name "StorageAccountName") | Out-Null
Write-Output 'Storage Account Context Set'
Write-Output ("AzureRm Context:`nResource Group: {0}`n{1}" -f $ResourceGroupName, (Get-AzureRmContext | Out-String | % Trim))

$octopusCustomScriptLogFile = 'OctopusDeploy.{0}.log' -f ([datetime]::UtcNow.ToString('o').Replace(':','.').Substring(0,19))

.\StartTemplateDeployment.ps1 -ServicePrincipalConnection $ServicePrincipalConnection -ResourceGroupName $resourceGroupName -Template octopusdeploy -TemplateParameters @{
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
        computeVmShutdownStatus = $ComputeVmShutdownStatus
        computeVmShutdownTime = $ComputeVmShutdownTime
        octopusDscJobId = [System.Guid]::NewGuid().ToString()
        octopusDscConfiguration = (Get-AzureStorageBlob -Container dsc -Blob 'OctopusDeploy.ps1').ICloudBlob.DownloadText()
        octopusDscConfigurationData =  (Get-AzureStorageBlob -Container dsc -Blob 'OctopusDeploy.psd1').ICloudBlob.DownloadText()
        octopusDscConnectionString = $OctopusDscConnectionString
        octopusDscHostName = $OctopusDscHostName
        octopusCustomScriptLogFile = $octopusCustomScriptLogFile 
}

#Invoke-SharedScript Compute 'Receive-CustomScriptOutput' -LogFileName $CurrentContext.Get('OctopusCustomScriptLogFile') -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
