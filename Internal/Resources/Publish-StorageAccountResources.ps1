function Publish-StorageAccountResources {
    param(
        [switch]$ResetStorage,
        [ValidateSet('AzureCustomScripts','DSCConfigurations','OctopusDeployDataSet','TeamCityDataSet','NuGetPackages','All')]$Upload = 'All'
    )

    Write-Host 'Configuring Stack Resources Storage Account...'

    $context = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StorageAccountName') -StorageAccountKey $CurrentContext.Get('StorageAccountKey')
  
    Write-Host

    Write-Host 'Encoding required values for Octopus & TeamCity data import...'
    $clonedContext = $CurrentContext.Clone()
    $octopusEncoder = New-Object  OctopusEncoder @($clonedContext, $clonedContext.Get('StackAdminPassword'))
    $octopusEncoder.Encrypt('Hello', 'Hello')
    $octopusEncoder.Encrypt('ServicePrincipalClientSecret', $clonedContext.Get('ServicePrincipalClientSecret'))
    $octopusEncoder.Encrypt('StackAdminPassword', $clonedContext.Get('StackAdminPassword'))
    $octopusEncoder.Hash('StackAdminPassword', $clonedContext.Get('StackAdminPassword')) 
    $octopusEncoder.Hash('ApiKey', $clonedContext.Get('ApiKey'))
    $octopusEncoder.ApiKeyID('ApiKey', $clonedContext.Get('ApiKey'))

    $teamCityEncoder = New-Object TeamCityEncoder @($clonedContext)
    $teamCityEncoder.Hash('StackAdminPassword', $clonedContext.Get('StackAdminPassword'))
    $teamCityEncoder.Scramble('Null', $null)
    $teamCityEncoder.Scramble('StackAdminPassword', $clonedContext.Get('StackAdminPassword'))
    $agentCloudName = 'AgentStack'
    $clonedContext.Set('AgentCloudName', $agentCloudName)
    $agentCloudPasswordData = @{$agentCloudName = $clonedContext.Get('StackAdminPassword') } | ConvertTo-Json -Compress
    $teamCityEncoder.Scramble('AgentCloudPasswordData', $agentCloudPasswordData)
    $teamCityEncoder.Scramble('ServicePrincipalClientSecret', $clonedContext.Get('ServicePrincipalClientSecret'))

    if ($Upload -in @('All','AzureCustomScripts')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading Azure Custom Scripts..."
        Upload-ToBlobContainer -ContainerName scripts -Source (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -TokeniseFiles @('OctopusImport.ps1','TeamCityPrepare.sh') -Context $context -ResetStorage:$ResetStorage -Octosprache $clonedContext
    }
    if ($Upload -in @('All','DSCConfigurations')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading DSC Configurations..."
        Upload-ToFileShare -FileShareName dsc -Source (Join-Path -Resolve $ResourcesPath 'DSC Configurations') -TokeniseFiles @() -Context $context -ResetStorage:$ResetStorage -Octosprache $clonedContext
    }
    if ($Upload -in @('All','OctopusDataSet')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading Octopus Deploy DataSet..."
        Upload-ToFileShare -FileShareName octopusdeploy -Source (Join-Path -Resolve $ExportsPath 'OctopusDeploy') -TokeniseFiles @('metadata.json','server.json','Automation Stack Parameters-VariableSet.json','Microsoft Azure Service Principal.json','Tentacle Auth.json','#{Encoding[OctopusApiKeyId].ApiKey}.json','#{StackAdminUsername}.json') -Context $context -ResetStorage:$ResetStorage -Octosprache $clonedContext
    }
    if ($Upload -in @('All','TeamCityDataSet')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading TeamCity DataSet..."
        Upload-ToFileShare -FileShareName teamcity -Source (Join-Path -Resolve $ExportsPath 'TeamCity') -TokeniseFiles @('vcs_username','users','database.properties','agentpush-presets.xml','arm-1.xml') -Context $context -ResetStorage:$ResetStorage -Octosprache $clonedContext
    }
    Write-Host
}