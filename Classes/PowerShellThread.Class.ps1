class PowerShellThread {
    [datetime]$BeginTime
    [datetime]$EndTime
    [timespan]$Duration
    [hashtable]$SharedState
    hidden [PowerShell]$PowerShell
    hidden [System.IAsyncResult]$Async
    [System.Collections.ObjectModel.Collection[psobject]]$Output

    PowerShellThread() {
        $this.SharedState = [hashtable]::Synchronized(@{})
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $sessionState.Variables.Add(([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new('SharedState', $this.SharedState, $null)))
        $this.PowerShell = [PowerShell]::Create($sessionState)

        $this | Add-Member ScriptProperty IsCompleted { $this.Async.IsCompleted }
        $this | Add-Member ScriptProperty HadErrors { $this.PowerShell.HadErrors }
    }
    [PowerShellThread] AddStep([ScriptBlock]$ScriptBlock) {
        $this.PowerShell.AddStatement().AddScript($ScriptBlock)
        return $this
    }
    [PowerShellThread] AddStep([ScriptBlock]$ScriptBlock, [Object[]]$ArgumentList) {
        $this.AddStep($ScriptBlock)
        @($ArgumentList) | ? { $null -ne $_ } | % { $this.PowerShell.AddArgument($_) }
        return $this
    }
    hidden [void] AddStreamRecord([string]$Stream, [object]$Record) {
        try {
            [System.Threading.Monitor]::Enter($this.Output)
            $this.Output.Add([pscustomobject]@{
                PSTypeName = 'StreamRecord'
                Stream = $Stream
                Record = $Record
            })
        }
        finally { [System.Threading.Monitor]::Exit($this.Output) } 
    }

    [PowerShellThread] Start() {
        $this.AddStep({
            param($this)
            $this.EndTime = Get-Date
            $this.Duration = $this.EndTime - $this.BeginTime
        }, @($this))

        $this.Output = {@()}.Invoke()

        $streams = @{
            Input = (New-Object System.Management.Automation.PSDataCollection[psobject])
            Output = (New-Object System.Management.Automation.PSDataCollection[psobject])
        }
       $streams.Input.Complete()

        Register-ObjectEvent -InputObject $streams.Output -EventName DataAdded -Action { $Event.MessageData.AddStreamRecord('Output', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Error -EventName DataAdded -Action { $Event.MessageData.AddStreamRecord('Error', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Warning -EventName DataAdded -Action { $Event.MessageData.AddStreamRecord('Warning', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Information -EventName DataAdded -Action { $Event.MessageData.AddStreamRecord('Information', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Verbose -EventName DataAdded -Action { $Event.MessageData.AddStreamRecord('Verbose', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Debug -EventName DataAdded -Action { $Event.MessageData.AddStreamRecord('Debug', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
 
        $this.Async = $this.PowerShell.BeginInvoke($streams.Input, $streams.Output)

        return $this
    }
    [void] Join() {
        $logPosition = 0
        do {
            Start-Sleep -Milliseconds 100
            try {
                [System.Threading.Monitor]::Enter($this.Output)
                $logPosition += [PowerShellThread]::DisplayStream(($this.Output | Select-Object -Skip $logPosition))
            }
            finally { [System.Threading.Monitor]::Exit($this.Output) } 
        } while (!$this.IsCompleted)

        $this.PowerShell.EndInvoke($this.Async)
        $this.PowerShell.Dispose()  
        [PowerShellThread]::DisplayStream(($this.Output | Select-Object -Skip $logPosition))

        if ($this.HadErrors) {
            throw 'Error'
        }
    }
    hidden static [int] DisplayStream($Stream) {
        $recordsRead = 0
        $Stream | ? { $null -ne $_ } | % {
            $record = $_.Record
            switch ($_.Stream) {
                'Output' { Write-Output $record; $record | Out-Default }
                'Error' { Write-Error -ErrorRecord $record -ErrorAction Continue; $record | Out-Default }
                'Warning' { Write-Warning -Message $record.Message -WarningAction Continue }
                'Information' { Write-Information -MessageData $record.MessageData -InformationAction Continue }
                'Verbose' { Write-Verbose -Message $record.Message -Verbose }
                'Debug' { Write-Debug -Message $record.Message -Debug }
            }
            $recordsRead++
        }
        return $recordsRead
    }

    static [PowerShellThread] Create() {
        $thread = [PowerShellThread]::new()
        $thread.AddStep({
            param($this)
            $ErrorActionPreference = 'Stop'
            $this.BeginTime = Get-Date
        }, @($thread))

        return $thread
    }
    static [PowerShellThread] Start([ScriptBlock]$ScriptBlock, [Object[]]$ArgumentList) { return [PowerShellThread]::Create().AddStep($ScriptBlock, $ArgumentList).Start() }
    static [PowerShellThread] Start([ScriptBlock]$ScriptBlock) { return [PowerShellThread]::Create().AddStep($ScriptBlock).Start() }
}