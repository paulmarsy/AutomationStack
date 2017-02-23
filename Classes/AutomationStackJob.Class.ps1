class AutomationStackJob {
    AutomationStackJob([string]$Name, [ScriptBlock]$ScriptBlock, $Arguments) {
        $this.Name = $Name

        $azureProfile = [System.IO.Path]::GetTempFileName()
        Save-AzureRmProfile -Path $azureProfile -Force
        $this.PowerShell = [PowerShell]::Create().AddScript({
            param($AzureProfile, $SubscriptionId, $this)
            Select-AzureRmProfile -Profile $AzureProfile | Out-Null
            Remove-Item -Path $AzureProfile -Force | Out-Null
            Select-AzureRmSubscription  -SubscriptionId $SubscriptionId | Out-Null
            Write-Output "Starting AutomationJob $($this.Name).."
        }).AddArgument($azureProfile).AddArgument((Get-AzureRmContext).Subscription.SubscriptionId).AddArgument($this).AddStatement().AddScript($ScriptBlock)
        $Arguments | % { $this.PowerShell.AddArgument($_) }
        $this.PowerShell.AddStatement().AddScript({
            param($this)
            $this.EndTime = Get-Date
            $this.Duration = $this.EndTime - $this.BeginTime
            Write-Output "AutomationJob $($this.Name) finished in $($this.Duration)"
        }).AddArgument($this)
        
        $this | Add-Member ScriptProperty IsCompleted { $this.Async.IsCompleted }
    }

    [string]$Name
    hidden [PowerShell]$PowerShell
    hidden [System.IAsyncResult]$Async
    [datetime]$BeginTime
    [datetime]$EndTime
    [timespan]$Duration
    
    static [AutomationStackJob] Runbook([string]$RunbookName, $Parameters) {
        return ([AutomationStackJob]::new($RunbookName, {
            param($ScriptsPath, $RunbookName, $ResourceGroupName, $AutomationAccountName, $Parameters)
           & (Join-Path $ScriptsPath 'Automation\Start-AutomationRunbook.ps1') -Name $RunbookName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName -Parameters $Parameters
        }, @($script:ScriptsPath, $RunbookName, $script:CurrentContext.Get('ResourceGroup'), $script:CurrentContext.Get('AutomationAccountName'), $Parameters)))
    }
    static [AutomationStackJob] ResourceGroupDeployment([string]$TemplateName, $Parameters) {
        Restore-AzureRmAuthContext -Silent
        return [AutomationStackJob]::new($TemplateName, {
            param($TemplateName)
            Start-ARMDeployment -Mode Uri -ResourceGroupName $CurrentContext.Get('ResourceGroup') -Template $TemplateName -TemplateParameters @{}
        }, @($TemplateName))
    }

    Start() {
         $this.Async = $this.PowerShell.BeginInvoke()
         $this.BeginTime = Get-Date
    }
    Join() {
        while (!$this.IsCompleted) {
            Write-Host "Waiting for AutomationJob $($this.Name) to finish..."
            Start-Sleep -Seconds 5
        }
        $this.PowerShell.EndInvoke($this.Async) | Out-Host
        $this.PowerShell.Streams.Error | % { Write-Error -ErrorRecord $_ }
        if ($this.PowerShell.HadErrors) {
            throw "Job $($this.Name) completed with errors"
        }

        $this.PowerShell.Dispose()
        
    }
}