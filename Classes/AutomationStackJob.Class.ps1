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
    hidden $Output
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
    static [AutomationStackJob] ScriptBlock([ScriptBlock]$ScriptBlock) {
        return [AutomationStackJob]::new('ScriptBlock', $ScriptBlock, @())
    }
    Start() {
        $in = New-Object System.Management.Automation.PSDataCollection[psobject]
        $in.Complete()
        $out = New-Object System.Management.Automation.PSDataCollection[psobject]
        Register-ObjectEvent -InputObject $out -EventName DataAdded -Action { $Event.MessageData.AddStreamMessage('Output', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Error -EventName DataAdded -Action { $Event.MessageData.AddStreamMessage('Error', $Sender[$EventArgs.Index].Exception.Message + "`n" + $Sender[$EventArgs.Index].sScriptStackTrace) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Warning -EventName DataAdded -Action { $Event.MessageData.AddStreamMessage('Warning', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Verbose -EventName DataAdded -Action { $Event.MessageData.AddStreamMessage('Verbose', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Progress -EventName DataAdded -Action { $Event.MessageData.AddStreamMessage('Progress', $Sender[$EventArgs.Index].Activity) } -MessageData $this -SupportEvent

        $this.Output = {@()}.Invoke()
        $this.Async = $this.PowerShell.BeginInvoke($in, $out)
        $this.BeginTime = Get-Date
    }
    Join() {
        $logPosition = 0
        do {
            Start-Sleep -Milliseconds 250
            try {
                [System.Threading.Monitor]::Enter($this.Output)
                $logPosition += [AutomationStackJob]::DisplayStream(($this.Output | Select-Object -Skip $logPosition))
            }
            finally { [System.Threading.Monitor]::Exit($this.Output) } 
        } while (!$this.IsCompleted)

        $this.PowerShell.EndInvoke($this.Async)
        $this.PowerShell.Dispose()  
        if ($this.PowerShell.HadErrors) {
            throw "Job $($this.Name) completed with errors"
        }
    }
    hidden [void] AddStreamMessage([string]$Stream, [string]$Message) {
        try {
            [System.Threading.Monitor]::Enter($this.Output)
            $this.Output.Add([pscustomobject]@{
                Stream = $Stream
                DateTime = (Get-Date)
                Message = $Message
            })
        }
        finally { [System.Threading.Monitor]::Exit($this.Output) } 
    }
    [void] DisplayStream() { [AutomationStackJob]::DisplayStream($this.Output) }
    hidden static [int] DisplayStream($Stream) {
        $recordsRead = 0
        $Stream | ? { -not [string]::IsNullOrWhitespace($_) } | % {
            $color = switch ($_.Stream) {
                'Error' {[System.ConsoleColor]::Red}
                'Warning' {[System.ConsoleColor]::Yellow}
                'Progress' {[System.ConsoleColor]::Blue}
                default {[Console]::ForegroundColor}
            }
            Write-Host -ForegroundColor $color ('[{0}] {1}: {2}' -f $_.Stream, $_.DateTime.ToShortTimeString(), $_.Message)
            $recordsRead++
        }
        return $recordsRead
    }
}