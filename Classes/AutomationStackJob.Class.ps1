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
        $azureProfile = [System.IO.Path]::GetTempFileName()
        Save-AzureRmProfile -Path $azureProfile -Force
        $this.PowerShell.AddStep({
            param($AzureProfile, $SubscriptionId)
            Select-AzureRmProfile -Profile $AzureProfile | Out-Null
            Remove-Item -Path $AzureProfile -Force | Out-Null
            Select-AzureRmSubscription  -SubscriptionId $SubscriptionId | Out-Null
        }, @($azureProfile, (Get-AzureRmContext).Subscription.SubscriptionId))
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
            param($ScriptsPath, $ResourceGroupName, $Template, $TemplateParameters)
           $SharedState.DeploymentAsyncOperationUri = & (Join-Path $ScriptsPath 'Resources\Start-ResourceGroupDeployment.ps1') -ResourceGroupName $ResourceGroupName -Template $Template -TemplateParameters $TemplateParameters
        }, @($script:ScriptsPath, $this.CurrentContext.Get('ResourceGroup'), $Template, $TemplateParameters))

        $this.PowerShell.AddStep({
            param($ScriptsPath)
           & (Join-Path $ScriptsPath 'Resources\Wait-ResourceGroupDeployment.ps1') -DeploymentAsyncOperationUri $SharedState.DeploymentAsyncOperationUri
        }, @($script:ScriptsPath))

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