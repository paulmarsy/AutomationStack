class AutomationStackJob {
    [String]$Name
    [Octosprache]$CurrentContext
    [PowerShellThread]$PowerShell

    AutomationStackJob([string]$Name, [Octosprache]$CurrentContext) {
        $this.Name = $Name
        $this.CurrentContext = $CurrentContext
        $this.PowerShell = [PowerShellThread]::Create().AddStep({
            param($Name)
            Write-Host -ForegroundColor Cyan "Starting AutomationJob $Name.."
        }, $Name)
    }
    static [AutomationStackJob] Create([string]$Name, [Octosprache]$CurrentContext) {
        return [AutomationStackJob]::new($Name, $CurrentContext)
    }
    [PowerShellThread] Start() {
        $this.PowerShell.Start()
        return $this.PowerShell
    }

    [AutomationStackJob] AzureAuth() {
        $this.PowerShell.AddStep({
            param($ServicePrincipalClientSecret, $ServicePrincipalClientId, $AzureSubscriptionId, $AzureTenantId)
            
            $securePassword = ConvertTo-SecureString $ServicePrincipalClientSecret -AsPlainText -Force
            $credential = New-Object System.Management.Automation.PSCredential ($ServicePrincipalClientId, $securePassword)

            Add-AzureRmAccount -Credential $credential -SubscriptionId $AzureSubscriptionId -TenantId $AzureTenantId -ServicePrincipal
        }, @($this.CurrentContext.Get('ServicePrincipalClientSecret'), $this.CurrentContext.Get('ServicePrincipalClientId'), $this.CurrentContext.Get('AzureSubscriptionId'), $this.CurrentContext.Get('AzureTenantId')))
    
        return $this
    }
    [AutomationStackJob] StorageContext() {
        $this.PowerShell.AddStep({
            param($ResourceGroupName, $StorageAccountName)
            
            Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccountName | Out-Null
        }, @($this.CurrentContext.Get('ResourceGroup'), $this.CurrentContext.Get('StorageAccountName')))
    
        return $this
    }
    [AutomationStackJob] ResourceGroupDeployment($Template) {
        return $this.ResourceGroupDeployment($Template, @{})
    }
    [AutomationStackJob] ResourceGroupDeployment($Template, $TemplateParameters) {
        $this.PowerShell.AddStep({
            param($ScriptsPath, $ServicePrincipalCertificate, $ServicePrincipalClientId, $ResourceGroupName, $Template, $TemplateParameters)
            
            $SharedState.DeploymentAsyncOperationUri = & (Join-Path $ScriptsPath 'Resources\Start-ResourceGroupDeployment.ps1') -ServicePrincipalCertificate $ServicePrincipalCertificate -ServicePrincipalClientId $ServicePrincipalClientId -ResourceGroupName $ResourceGroupName -Template $Template -TemplateParameters $TemplateParameters
        }, @($script:ScriptsPath, $this.CurrentContext.Get('ServicePrincipalCertificate'), $this.CurrentContext.Get('ServicePrincipalClientId'), $this.CurrentContext.Get('ResourceGroup'), $Template, $TemplateParameters))

        $this.PowerShell.AddStep({
            param($ScriptsPath, $ServicePrincipalCertificate, $ServicePrincipalClientId)
            
            & (Join-Path $ScriptsPath 'Resources\Wait-ResourceGroupDeployment.ps1') -ServicePrincipalCertificate $ServicePrincipalCertificate -ServicePrincipalClientId $ServicePrincipalClientId -DeploymentAsyncOperationUri $SharedState.DeploymentAsyncOperationUri
        }, @($script:ScriptsPath, $this.CurrentContext.Get('ServicePrincipalCertificate'), $this.CurrentContext.Get('ServicePrincipalClientId')))

        return $this
    }
    [AutomationStackJob] Runbook($RunbookName, $RunbookParameters) {
        $this.PowerShell.AddStep({
            param($ScriptsPath, $ResourceGroupName, $AutomationAccountName, $RunbookName, $Parameters)
            
            $SharedState.AutomationJobID = & (Join-Path $ScriptsPath 'Automation\Start-AutomationRunbook.ps1') -Name $RunbookName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Parameters $Parameters
        }, @($script:ScriptsPath, $this.CurrentContext.Get('ResourceGroup'), $this.CurrentContext.Get('AutomationAccountName'), $RunbookName, $RunbookParameters))
        
        $this.PowerShell.AddStep({
            param($ScriptsPath, $ResourceGroupName, $AutomationAccountName)
            
            $SharedState.AutomationJobID = & (Join-Path $ScriptsPath 'Automation\Wait-AutomationRunbook.ps1') -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -JobID $SharedState.AutomationJobID
        }, @($script:ScriptsPath, $this.CurrentContext.Get('ResourceGroup'), $this.CurrentContext.Get('AutomationAccountName')))

        return $this
    }
    [AutomationStackJob] GetCustomScriptOutput($LogFileName) {
        $this.PowerShell.AddStep({
            param($ScriptsPath, $LogFileName)
            
            & (Join-Path $ScriptsPath 'Compute\Receive-CustomScriptOutput.ps1') -LogFileName $LogFileName
        }, @($script:ScriptsPath, $LogFileName))

        return $this
    }
}