function Publish-StackResources {
    param([switch]$ResetStorage)

    Write-Host 'Configuring Stack Resources Storage Account...'

    $CurrentContext.Set('StackResourcesName', 'stackresources#{UDP}')
    $CurrentContext.Set('StackResourcesKey', (Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('InfraRg')  -Name $CurrentContext.Get('StackResourcesName'))[0].Value)
    $stackresources = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')
  
    Write-Host

    Write-Host 'Encoding required values for Octopus & TeamCity data import...'
    $octopusEncoder = New-Object  OctopusEncoder @($CurrentContext, $CurrentContext.Get('StackAdminPassword'))
    $octopusEncoder.Encrypt('ProtectedImportHello', 'Hello')
    $octopusEncoder.Encrypt('ServicePrincipalPassword', $CurrentContext.Get('ServicePrincipalClientSecret'))
    $octopusEncoder.Encrypt('SSHPassword', $CurrentContext.Get('StackAdminPassword'))
    $octopusEncoder.Hash('OctopusPasswordHash', $CurrentContext.Get('StackAdminPassword')) 
    $octopusEncoder.Hash('ApiKeyHash', $CurrentContext.Get('ApiKey'))
    $octopusEncoder.ApiKeyID('ApiKeyId', $CurrentContext.Get('ApiKey'))

    $teamCityEncoder = New-Object TeamCityEncoder @($CurrentContext)
    $teamCityEncoder.Hash('TeamCityPasswordHash', $CurrentContext.Get('StackAdminPassword'))

    Write-Host
    Write-Host -ForegroundColor Green "`tUploading ARM Custom Scripts..."
    Upload-ToBlobContainer -ContainerName scripts -Source (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -TokeniseFiles @('OctopusImport.ps1','TeamCityPrepare.sh') -Context $stackresources -ResetStorage:$ResetStorage
    
    Write-Host
    Write-Host -ForegroundColor Green "`tUploading DSC Configurations..."
    Upload-ToFileShare -FileShareName dsc -Source (Join-Path -Resolve $ResourcesPath 'DSC Configurations') -TokeniseFiles @() -ARMTemplateFiles @() -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
    Write-Host -ForegroundColor Green "`tUploading Octopus Deploy Data Import..."
    Upload-ToFileShare -FileShareName octopusdeploy -Source (Join-Path -Resolve $ExportsPath 'OctopusDeploy') -TokeniseFiles @('metadata.json','server.json','Automation Stack Parameters-VariableSet.json','Microsoft Azure Service Principal.json','Tentacle Auth.json','#{AzureRegion}.json','#{ApiKeyId}.json','#{Username}.json') -ARMTemplateFiles @('ARM Template - App Server.json','ARM Template - Docker Linux.json','ARM Template - Enable Encryption.json') -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
    Write-Host -ForegroundColor Green "`tUploading TeamCity Data Import..."
    Upload-ToFileShare -FileShareName teamcity -Source (Join-Path -Resolve $ExportsPath 'TeamCity') -TokeniseFiles @('vcs_username','users','database.properties') -ARMTemplateFiles @() -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
}