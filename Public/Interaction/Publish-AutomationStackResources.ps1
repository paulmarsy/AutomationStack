function Publish-AutomationStackResources {
    param(
        [ValidateSet('StackResources','DataImports','OctopusFeedPackages','All')]$Upload = 'All',
        [Parameter(DontShow)][switch]$SkipAuth
    )
    if (!$SkipAuth) { Connect-AzureRmServicePrincipal }
    try {
        $context = Get-StackResourcesContext

        if ($Upload -in @('All','StackResources')) {
            Write-Host
            Write-Host -ForegroundColor Green "`tUploading Azure Resource Manager Templates..."
            Upload-StackResources -Type BlobStorage -Name arm -Path (Join-Path -Resolve $ResourcesPath 'ARM Templates') -Tokenizer $CurrentContext -Context $context
         
            Write-Host
            Write-Host -ForegroundColor Green "`tUploading Azure Custom Scripts..."
            Upload-StackResources -Type BlobStorage -Name scripts -Path (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -Tokenizer $CurrentContext -Context $context `
                -FilesToTokenise @('OctopusImport.ps1','TeamCityImport.ps1','TeamCityPrepare.sh')
        
            Write-Host
            Write-Host -ForegroundColor Green "`tUploading DSC Configurations..."
            Upload-StackResources -Type FileShare  -Name dsc -Path (Join-Path -Resolve $ResourcesPath 'DSC Configurations') -Tokenizer $CurrentContext -Context $context `
        }
        if ($Upload -in @('All','DataImports')) {
            Write-Host
            Write-Host 'Encoding required values for Octopus & TeamCity data import...'
            $clonedContext = $CurrentContext.Clone()
            $octopusEncoder = New-Object  OctopusEncoder @($clonedContext, $clonedContext.Get('StackAdminPassword'))
            $octopusEncoder.Encrypt('Hello', 'Hello')
            $octopusEncoder.Encrypt('ServicePrincipalClientSecret', $clonedContext.Get('ServicePrincipalClientSecret'))
            $octopusEncoder.Encrypt('StackAdminPassword', $clonedContext.Get('StackAdminPassword'))
            $octopusEncoder.Encrypt('SqlServerPassword', $clonedContext.Get('SqlServerPassword'))
            $octopusEncoder.Encrypt('StorageAccountKey', $clonedContext.Get('StorageAccountKey'))
            $octopusEncoder.Encrypt('AutomationRegistrationKey', $clonedContext.Get('AutomationRegistrationKey'))
            $octopusEncoder.Hash('StackAdminPassword', $clonedContext.Get('StackAdminPassword')) 
            $octopusEncoder.Hash('ApiKey', $clonedContext.Get('ApiKey'))
            $octopusEncoder.ApiKeyID('ApiKey', $clonedContext.Get('ApiKey'))

            $teamCityEncoder = New-Object TeamCityEncoder @($clonedContext)
            $teamCityEncoder.Hash('StackAdminPassword', $clonedContext.Get('StackAdminPassword'))
            $teamCityEncoder.Scramble('Null', $null)
            $teamCityEncoder.Scramble('StackAdminPassword', $clonedContext.Get('StackAdminPassword'))
            $agentCloudName = $clonedContext.Eval('TCAgents#{UDP | ToUpper}') 
            $clonedContext.Set('AgentCloudName', $agentCloudName)
            $agentCloudPasswordData = @{$agentCloudName = $clonedContext.Get('StackAdminPassword') } | ConvertTo-Json -Compress
            $teamCityEncoder.Scramble('AgentCloudPasswordData', $agentCloudPasswordData)
            $teamCityEncoder.Scramble('ServicePrincipalClientSecret', $clonedContext.Get('ServicePrincipalClientSecret'))

            Write-Host
            Write-Host -ForegroundColor Green "`tUploading Octopus Deploy DataSet..."
            Upload-StackResources -Type FileShare  -Name octopusdeploy -Path (Join-Path -Resolve $DataImportPath 'OctopusDeploy') -Tokenizer $clonedContext -Context $context `
                 -FilesToTokenise @('metadata.json'
                                    'Microsoft Azure Service Principal.json' # Accounts
                                    'Tentacle Auth.json' # Accounts
                                    '#{Encoding[OctopusApiKeyId].ApiKey}.json' # ApiKeys
                                    'server.json' # Configuration
                                    'Automation Stack Parameters-VariableSet.json' # LibraryVariableSets
                                    '#{StackAdminUsername}.json' # Users
                                    'AutomationStack.json') # Users

            Write-Host
            Write-Host -ForegroundColor Green "`tUploading TeamCity DataSet..."
            Upload-StackResources -Type FileShare  -Name teamcity -Path (Join-Path -Resolve $DataImportPath 'TeamCity') -Tokenizer $clonedContext -Context $context `
                -FilesToTokenise @('vcs_username','users','database.properties','agentpush-presets.xml','arm-1.xml')
        }
        if ($Upload -in @('All','OctopusFeedPackages')) {
            Publish-OctopusPackage (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') 'ARMCustomScripts'
            Publish-OctopusPackage (Join-Path -Resolve $ResourcesPath 'ARM Templates') 'ARMTemplates'
            Get-ChildItem -Path $ScriptsPath -Directory | % {
                Publish-OctopusPackage ($_.FullName | Convert-Path) ('AutomationStackScripts.{0}' -f $_.BaseName)
            }
        }
        Write-Host
    }
    finally {
        if (!$SkipAuth) { Restore-AzureRmAuthContext }
    }
}