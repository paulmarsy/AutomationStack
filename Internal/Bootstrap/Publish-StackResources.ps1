function Publish-StackResources {
    param([switch]$ResetStorage)

    Write-Host 'Configuring Stack Resources Storage Account...'

    $CurrentContext.Set('StackResourcesName', 'stackresources#{UDP}')
    $CurrentContext.Set('StackResourcesKey', (Get-AzureRmStorageAccountKey -ResourceGroupName $CurrentContext.Get('InfraRg')  -Name $CurrentContext.Get('StackResourcesName'))[0].Value)
    $stackresources = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')
  
    Write-Host

    Write-Host 'Encoding required values for Octopus & TeamCity data import...'
    $octopusEncoder = New-Object  OctopusEncoder @($CurrentContext, $CurrentContext.Get('Password'))
    $octopusEncoder.Encrypt('ProtectedImportHello', 'Hello')
    $octopusEncoder.Encrypt('ServicePrincipalPassword', $CurrentContext.Get('ServicePrincipalClientSecret'))
    $octopusEncoder.Encrypt('SSHPassword', $CurrentContext.Get('Password'))
    $octopusEncoder.Hash('OctopusPasswordHash', $CurrentContext.Get('Password')) 
    $CurrentContext.Set('ApiKey', ('API-AUTOMATION{0}' -f $CurrentContext.Get('UDP')))
    $octopusEncoder.Hash('ApiKeyHash', $CurrentContext.Get('ApiKey'))
    $octopusEncoder.ApiKeyID('ApiKeyId', $CurrentContext.Get('ApiKey'))

    $teamCityEncoder = New-Object TeamCityEncoder @($CurrentContext)
    $teamCityEncoder.Hash('TeamCityPasswordHash', $CurrentContext.Get('Password'))

    # Write-Host "Encoding ARM Templates into Octopus Deploy import..."
    # Get-ChildItem -Path (Join-Path -Resolve $ResourcesPath 'ARM Templates') -File | % {
    #     $name = $_.BaseName
    #     $content = Get-Content -Path $_.FullName -Raw
    #     if ($name.EndsWith('.parameters')) {
    #         $name = $name.Substring(0,($name.Length-'.parameters'.Length))
    #         Write-Host "Adding ARM Parameter File $name"
    #         $CurrentContext.SetARMParameters($name, $content)
    #     } else {
    #         Write-Host "Adding ARM Template File $name"
    #         $CurrentContext.SetARMTemplate($name, $content)
    #     }
    # }

    Write-Host
    Write-Host -ForegroundColor Green "`tUploading ARM Custom Scripts..."
    Upload-ToBlobContainer -ContainerName scripts -Source (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -TokeniseFiles @('OctopusImport.ps1','TeamCityPrepare.sh') -Context $stackresources -ResetStorage:$ResetStorage
    
    Write-Host
    Write-Host -ForegroundColor Green "`tUploading DSC Configurations..."
    Upload-ToFileShare -FileShareName dsc -Source (Join-Path -Resolve $ResourcesPath 'DSC Configurations') -TokeniseFiles @() -ARMTemplateFiles @() -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
    Write-Host -ForegroundColor Green "`tUploading Octopus Deploy Data Import..."
    Upload-ToFileShare -FileShareName octopusdeploy -Source (Join-Path -Resolve $ResourcesPath 'OctopusDeploy Export') -TokeniseFiles @('metadata.json','server.json','Automation Stack Parameters-VariableSet.json','Microsoft Azure Service Principal.json','Tentacle Auth.json','#{AzureRegion}.json','#{ApiKeyId}.json','#{Username}.json') -ARMTemplateFiles @('ARM Template - App Server.json','ARM Template - Docker Linux.json','ARM Template - Enable Encryption.json') -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
    Write-Host -ForegroundColor Green "`tUploading TeamCity Data Import..."
    Upload-ToFileShare -FileShareName teamcity -Source (Join-Path -Resolve $ResourcesPath 'TeamCity Export') -TokeniseFiles @('vcs_username','users','database.properties') -ARMTemplateFiles @() -Context $stackresources -ResetStorage:$ResetStorage

    Write-Host
}