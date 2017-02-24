param($ComputeVmShutdownStatus, $ComputeVmShutdownTime, $OctopusDscConnectionString, $OctopusDscHostName)

Write-Output "Starting DeployOctopusDeploy Runbook..."
$VerbosePreference = "SilentlyContinue"
$DebugPreference = "SilentlyContinue"
$ProgressPreference = "SilentlyContinue"

$ServicePrincipalConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
Write-Output ($ServicePrincipalConnection | Out-String)
$azureRmContext = Add-AzureRmAccount -ServicePrincipal -TenantId $ServicePrincipalConnection.TenantId -ApplicationId $ServicePrincipalConnection.ApplicationId -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint
Write-Output "Connected to AzureRm`nContext:"
Write-Output ($azureRmContext | Out-String)

$resourceGroupName = Get-AutomationVariable -Name "ResourceGroupName"
Write-Output "ResourceGroupName: $resourceGroupName"
$storageAccountName = Get-AutomationVariable -Name "StorageAccountName"
Write-Output "StorageAccountName: $storageAccountName"
$context = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName).Context

$dscContainer = Get-AzureStorageContainer -Name dsc -Context $context
$octopusCustomScriptLogFile = 'OctopusDeploy.{0}.log' -f ([datetime]::UtcNow.ToString('o').Replace(':','.').Substring(0,19))

.\StartTemplateDeployment.ps1 -ServicePrincipalConnection $ServicePrincipalConnection -ResourceGroupName $resourceGroupName -Context $context -Template octopusdeploy -TemplateParameters @{
        timestamp = ([DateTimeOffset]::UtcNow.ToString("o"))
        computeVmShutdownStatus = $ComputeVmShutdownStatus
        computeVmShutdownTime = $ComputeVmShutdownTime
        octopusDscJobId = [System.Guid]::NewGuid().ToString()
        octopusDscConfiguration = $dscContainer.CloudBlobContainer.GetBlockBlobReference('OctopusDeploy.ps1').DownloadText()
        octopusDscConfigurationData =  $dscContainer.CloudBlobContainer.GetBlockBlobReference('OctopusDeploy.psd1').DownloadText()
        octopusDscConnectionString = $OctopusConnectionString
        octopusDscHostName = $OctopusHostName
        octopusCustomScriptLogFile = $octopusCustomScriptLogFile 
}

#Invoke-SharedScript Compute 'Receive-CustomScriptOutput' -LogFileName $CurrentContext.Get('OctopusCustomScriptLogFile') -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
