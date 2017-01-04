function Publish-StackResources {
    param([switch]$ResetStorage)

    Write-Host 'Configuring Stack Resources Storage Account...'

    $CurrentContext.Set('StackResourcesName', 'stackresources#{UDP}')
    $CurrentContext.Set('StackResourcesKey', (Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('InfraRg')  -Name $CurrentContext.Get('StackResourcesName'))[0].Value)
    $stackresources = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')

    $CurrentContext.SetSensitive($CurrentContext.Get('Password'), 'ProtectedImportHello', 'Hello')
    $CurrentContext.SetSensitive($CurrentContext.Get('Password'), 'ServicePrincipalPassword', $CurrentContext.Get('Password'))
    $CurrentContext.SetSensitive($CurrentContext.Get('Password'), 'SSHPassword', $CurrentContext.Get('Password'))
    $CurrentContext.SetTeamCityHashed('TeamCityPasswordHash', $CurrentContext.Get('Password'))
    $CurrentContext.SetOctopusHashed('OctopusPasswordHash', $CurrentContext.Get('Password'))
    $CurrentContext.Set('ApiKey', ('API-AUTOMATION{0}' -f $CurrentContext.Get('UDP')))
    $CurrentContext.SetApiKeyId('ApiKeyId', $CurrentContext.Get('ApiKey'))
    $CurrentContext.SetOctopusHashed('ApiKeyHash', $CurrentContext.Get('ApiKey'))


    Write-Host
    Write-Host -ForegroundColor Green "`tARM Custom Scripts..."
    Upload-ToBlobContainer -ContainerName scripts -Source (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -TokeniseFiles @('OctopusImport.ps1','TeamCityPrepare.sh') -Context $stackresources -ResetStorage:$ResetStorage
    
    Write-Host
    Write-Host -ForegroundColor Green "`tDSC Configurations..."
    Upload-ToFileShare -FileShareName dsc -Source (Join-Path -Resolve $ResourcesPath 'DSC Configurations') -TokeniseFiles @() -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
    Write-Host -ForegroundColor Green "`tOctopus Deploy..."
    Upload-ToFileShare -FileShareName octopusdeploy -Source (Join-Path -Resolve $ResourcesPath 'OctopusDeploy Export') -TokeniseFiles @('metadata.json','server.json','Automation Stack Parameters-VariableSet.json','Microsoft Azure Service Principal.json','Tentacle Auth.json','#{AzureRegion}.json','#{ApiKeyId}.json','#{Username}.json') -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
    Write-Host -ForegroundColor Green "`tTeamCity..."
    Upload-ToFileShare -FileShareName teamcity -Source (Join-Path -Resolve $ResourcesPath 'TeamCity Export') -TokeniseFiles @('vcs_username','users','database.properties') -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
}