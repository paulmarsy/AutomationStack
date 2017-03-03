function Publish-AutomationStackResources {
    param(
        [ValidateSet('AzureTemplates','FeatureResources','Runbooks','DataImports','All')]$Upload = 'All',
        [Parameter(DontShow)][switch]$SkipAuth
    )
    if (!$SkipAuth) { Connect-AzureRmServicePrincipal }
    try { 
        $ProgressPreference = 'SilentlyContinue'
        $context = Get-StackResourcesContext

        if ($Upload -in @('All','AzureTemplates')) {
            Write-Host
            Write-Host -ForegroundColor Green "`tUploading Azure Resource Manager Templates..."
            Upload-StackResources -Type BlobStorage -Name arm -Path (Join-Path -Resolve $ResourcesPath 'ARM Templates') -Tokenizer $CurrentContext -Context $context

            Write-Host
            Write-Host -ForegroundColor Green "`tUploading Azure Automation Runbooks..."
            Upload-StackResources -Type BlobStorage -Name runbooks -Path (Join-Path -Resolve $ResourcesPath 'Runbooks') -Tokenizer $CurrentContext -Context $context    
        }
        if ($Upload -in @('All','FeatureResources')) {
            Write-Host
            Write-Host -ForegroundColor Green "`tUploading DSC Configurations..."
            $octopusDscConfiguration = Invoke-DSCComposition -Path (Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.ps1')
            Upload-StackResources -Type BlobStorage -Name dsc -Path 'OctopusDeploy.ps1' -Value $octopusDscConfiguration -Tokenizer $CurrentContext -Context $context
            $octopusDscConfigurationData = Get-Content (Join-Path $ResourcesPath 'DSC Configurations\OctopusDeploy.psd1') -Raw | Invoke-Expression | ConvertTo-Json -Depth 10
            Upload-StackResources -Type BlobStorage -Name dsc -Path 'OctopusDeploy.json' -Value $octopusDscConfigurationData -Tokenizer $CurrentContext -Context $context

            $teamcityDscConfiguration = Invoke-DSCComposition -Path (Join-Path $ResourcesPath 'DSC Configurations\TeamCity.ps1')
            Upload-StackResources -Type BlobStorage -Name dsc -Path 'TeamCity.ps1' -Value $octopusDscConfiguration -Tokenizer $CurrentContext -Context $context
            $teamCityDscConfigurationData = Get-Content (Join-Path $ResourcesPath 'DSC Configurations\TeamCity.psd1') -Raw | Invoke-Expression | ConvertTo-Json -Depth 10
            Upload-StackResources -Type BlobStorage -Name dsc -Path 'TeamCity.json' -Value $teamCityDscConfigurationData -Tokenizer $CurrentContext -Context $context

            Write-Host
            Write-Host -ForegroundColor Green "`tUploading Azure Custom Scripts..."
            Upload-StackResources -Type BlobStorage -Name scripts -Path (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -Tokenizer $CurrentContext -Context $context `
                -FilesToTokenise @('OctopusImport.ps1','TeamCityImport.ps1','TeamCityPrepare.sh')
        }
        if ($Upload -in @('All','Runbooks')) {
            Write-Host
            Write-Host -ForegroundColor Green "`tUploading Azure Automation Runbooks..."
            Upload-StackResources -Type BlobStorage -Name runbooks -Path (Join-Path -Resolve $ResourcesPath 'Runbooks') -Tokenizer $CurrentContext -Context $context    

            Write-Host
            Write-Host -ForegroundColor Green "`Importing Azure Automation Runbooks..."
            Get-ChildItem -Path  (Join-Path $ResourcesPath 'Runbooks') -File | % {
                Import-AzureRmAutomationRunbook -Path $_.FullName -Name $_.BaseName -Type PowerShell -Published -Force -ResourceGroupName $CurrentContext.Get('ResourceGroup') -AutomationAccountName $CurrentContext.Get('AutomationAccountName') | Out-Null
                [void][System.Console]::Out.WriteLineAsync("   `t`t`t`tImporting`t`t$($_.BaseName)")
            }
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
            Write-Host -ForegroundColor Green "`tUploading Script Packages..."
            Write-Host "  Runspace ID`tProgress`tAction`t`t`tFile`n$('-'*120)"
            Upload-ScriptPackage -Path (Join-Path -Resolve $ResourcesPath 'ARM Custom Scripts') -PackageName 'ARMCustomScripts' -Context $context
            Upload-ScriptPackage -Path (Join-Path -Resolve $ResourcesPath 'ARM Templates') -PackageName  'ARMTemplates' -Context $context
            Upload-ScriptPackage -Path $ScriptsPath -PackageName 'AutomationStackScripts' -Context $context

            Write-Host
            Write-Host -ForegroundColor Green "`tUploading Application Data Imports..."
            Upload-StackResources -Type FileShare  -Name dataimports -Path $DataImportPath -Tokenizer $clonedContext -Context $context `
                 -FilesToTokenise @('metadata.json'                                                         # Octopus Deploy
                                    'Microsoft Azure Service Principal.json' # Accounts
                                    'Tentacle Auth.json' # Accounts
                                    '#{Encoding[OctopusApiKeyId].ApiKey}.json' # ApiKeys
                                    'server.json' # Configuration
                                    'Automation Stack Parameters-VariableSet.json' # LibraryVariableSets
                                    '#{StackAdminUsername}.json' # Users
                                    'AutomationStack.json' # Users
                                    'vcs_username'                                                          # TeamCity
                                    'users'
                                    'database.properties'
                                    'agentpush-presets.xml'
                                    'arm-1.xml')
        }
        Write-Host
    }
    finally {
        $ProgressPreference = 'Continue'
        if (!$SkipAuth) { Restore-AzureRmAuthContext }
    }
}