class StreamRecord {
    [long]$Id
    [string]$Stream
    [object]$Record

    StreamRecord([string]$Stream, [object]$Record) {
        $this.Id = [System.Diagnostics.Stopwatch]::GetTimestamp()
        $this.Stream = $Stream
        $this.Record = $Record
    }

    [string] ToString() {
        return ($this.Record | Out-String)
    }
}
class PowerShellThread {
    [datetime]$BeginTime
    [datetime]$EndTime
    [timespan]$Duration
    [hashtable]$SharedState
    hidden [PowerShell]$PowerShell
    hidden [System.IAsyncResult]$Async
    [System.Collections.Concurrent.ConcurrentBag[psobject]]$Output

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
    hidden [void] AddOutputRecord([string]$Stream, [object]$Record) {
        $this.Output.Add([StreamRecord]::new($Stream, $Record))
    }
    [PowerShellThread] Start() {
        $this.AddStep({
            param($this)
            $this.EndTime = Get-Date
            $this.Duration = $this.EndTime - $this.BeginTime
        }, @($this))

        $this.Output = [System.Collections.Concurrent.ConcurrentBag[psobject]]::new()

        $streams = @{
            Input = (New-Object System.Management.Automation.PSDataCollection[psobject])
            Output = (New-Object System.Management.Automation.PSDataCollection[psobject])
        }
       $streams.Input.Complete()

        Register-ObjectEvent -InputObject $streams.Output -EventName DataAdded -Action { $Event.MessageData.AddOutputRecord('Output', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Error -EventName DataAdded -Action { $Event.MessageData.AddOutputRecord('Error', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Warning -EventName DataAdded -Action { $Event.MessageData.AddOutputRecord('Warning', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Information -EventName DataAdded -Action { $Event.MessageData.AddOutputRecord('Information', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Verbose -EventName DataAdded -Action { $Event.MessageData.AddOutputRecord('Verbose', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
        Register-ObjectEvent -InputObject $this.PowerShell.Streams.Debug -EventName DataAdded -Action { $Event.MessageData.AddOutputRecord('Debug', $Sender[$EventArgs.Index]) } -MessageData $this -SupportEvent
 
        $this.Async = $this.PowerShell.BeginInvoke($streams.Input, $streams.Output)

        return $this
    }
    [void] Join() {
        $logPosition = 0
        do {
            Start-Sleep -Milliseconds 100
            $logPosition += [PowerShellThread]::DisplayStream(($this.Output | Sort-Object -Property Id | Select-Object -Skip $logPosition))
        } while (!$this.IsCompleted)
        try {
            $this.PowerShell.EndInvoke($this.Async)

        }
        catch {
            Write-Host -Foregroundcolor Red ($_ | Out-String)    
        }
        finally {
            $this.PowerShell.Dispose()
        }
        $logPosition += [PowerShellThread]::DisplayStream(($this.Output | Sort-Object -Property Id | Select-Object -Skip $logPosition))

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
        if (!$Global:PowerShellThreadPool) {
            $Global:PowerShellThreadPool = {@()}.Invoke()
        }
        $Global:PowerShellThreadPool.Add($thread)
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