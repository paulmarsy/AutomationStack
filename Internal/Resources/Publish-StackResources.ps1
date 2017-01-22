function Publish-StackResources {
    param(
        [switch]$ResetStorage,
        [ValidateSet('ARM','DSC','OctopusDeploy','TeamCity','All')]$Upload = 'All'
    )

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
    $octopusEncoder.Hash('OctopusAdminPasswordHash', $CurrentContext.Get('StackAdminPassword')) 
    $octopusEncoder.Hash('ApiKeyHash', $CurrentContext.Get('ApiKey'))
    $octopusEncoder.ApiKeyID('ApiKeyId', $CurrentContext.Get('ApiKey'))

    $teamCityEncoder = New-Object TeamCityEncoder @($CurrentContext)
    $teamCityEncoder.Hash('TeamCityPasswordHash', $CurrentContext.Get('StackAdminPassword'))

    if ($Upload -in @('All','ARM')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading ARM Custom Scripts..."
        Upload-ToBlobContainer -ContainerName scripts -Source (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -TokeniseFiles @('OctopusImport.ps1','TeamCityPrepare.sh') -Context $stackresources -ResetStorage:$ResetStorage
    }
    if ($Upload -in @('All','DSC')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading DSC Configurations..."
        Upload-ToFileShare -FileShareName dsc -Source (Join-Path -Resolve $ResourcesPath 'DSC Configurations') -TokeniseFiles @() -Context $stackresources -ResetStorage:$ResetStorage
    }
    if ($Upload -in @('All','OctopusDeploy')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading Octopus Deploy Data Import..."
        Upload-ToFileShare -FileShareName octopusdeploy -Source (Join-Path -Resolve $ExportsPath 'OctopusDeploy') -TokeniseFiles @('metadata.json','server.json','Automation Stack Parameters-VariableSet.json','Microsoft Azure Service Principal.json','Tentacle Auth.json','#{ApiKeyId}.json','#{StackAdminUsername}.json') -Context $stackresources -ResetStorage:$ResetStorage
    }
    if ($Upload -in @('All','TeamCity')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading TeamCity Data Import..."
        Upload-ToFileShare -FileShareName teamcity -Source (Join-Path -Resolve $ExportsPath 'TeamCity') -TokeniseFiles @('vcs_username','users','database.properties') -Context $stackresources -ResetStorage:$ResetStorage
    }
    Write-Host
}