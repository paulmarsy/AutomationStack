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

    if ($Upload -in @('All','ARM')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading ARM Custom Scripts..."
        Upload-ToBlobContainer -ContainerName scripts -Source (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -TokeniseFiles @('OctopusImport.ps1','TeamCityPrepare.sh') -Context $stackresources -ResetStorage:$ResetStorage -Octosprache $clonedContext
    }
    if ($Upload -in @('All','DSC')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading DSC Configurations..."
        Upload-ToFileShare -FileShareName dsc -Source (Join-Path -Resolve $ResourcesPath 'DSC Configurations') -TokeniseFiles @() -Context $stackresources -ResetStorage:$ResetStorage -Octosprache $clonedContext
    }
    if ($Upload -in @('All','OctopusDeploy')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading Octopus Deploy Data Import..."
        Upload-ToFileShare -FileShareName octopusdeploy -Source (Join-Path -Resolve $ExportsPath 'OctopusDeploy') -TokeniseFiles @('metadata.json','server.json','Automation Stack Parameters-VariableSet.json','Microsoft Azure Service Principal.json','Tentacle Auth.json','#{Encoding[OctopusApiKeyId].ApiKey}.json','#{StackAdminUsername}.json') -Context $stackresources -ResetStorage:$ResetStorage -Octosprache $clonedContext
    }
    if ($Upload -in @('All','TeamCity')) {
        Write-Host
        Write-Host -ForegroundColor Green "`tUploading TeamCity Data Import..."
        Upload-ToFileShare -FileShareName teamcity -Source (Join-Path -Resolve $ExportsPath 'TeamCity') -TokeniseFiles @('vcs_username','users','database.properties','agentpush-presets.xml','arm-1.xml') -Context $stackresources -ResetStorage:$ResetStorage -Octosprache $clonedContext
    }
    Write-Host
}