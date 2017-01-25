class AutoMetrics {
    AutoMetrics([Octosprache]$Octosprache) {
        $backingFile = Join-Path $script:DeploymentsPath ('{0}.metrics.json' -f $Octosprache.Get('UDP'))        
        $this.VariableDictionary = New-Object Octostache.VariableDictionary $backingFile
    }
    
    hidden $VariableDictionary

    Start([string]$Key, [string]$Description) {
        if ($this.VariableDictionary.Get('DeploymentComplete') -eq 'True') { return }
        $this.VariableDictionary.Set(('Timing[{0}].Start' -f $Key), (Get-Date))
        $this.VariableDictionary.Set(('Timing[{0}].Description' -f $Key), $Description)
        $this.VariableDictionary.Save()
    }
    Finish([string]$Key) {
        if ($this.VariableDictionary.Get('DeploymentComplete') -eq 'True') { return }
        $this.VariableDictionary.Set(('Timing[{0}].End' -f $Key), (Get-Date))
        $this.VariableDictionary.Save()
    }
    [string] GetDescription([string]$Key) {
         $description = $this.VariableDictionary.Get(('Timing[{0}].Description' -f $Key))
         if (!$description) { return 'Not yet started' }
         else { return  $description }
    }
    [timespan] GetRaw([string]$Key) {
        $startdatetime = $this.VariableDictionary.Get(('Timing[{0}].Start' -f $Key))
        if (!$startdatetime) { return [timespan]::Zero }
        $enddatetime = $this.VariableDictionary.Get(('Timing[{0}].End' -f $Key))
        if (!$enddatetime) { return [timespan]::Zero }
        return (([datetime]$enddatetime) - ([datetime]$startdatetime))
    }
    [string] GetDuration([string]$Key) {
        $duration = $this.GetRaw($Key)
        if (!$duration) { return '-' }
        return [Humanizer.TimeSpanHumanizeExtensions]::Humanize($duration, 2)
    }
    [string] GetPercentage([string]$Key, [string]$OfKey) {
        $partial = $this.GetRaw($Key)
        if ($partial -eq [timespan]::Zero) { return $null }
        $total = $this.GetRaw($OfKey)
        if ($total -eq [timespan]::Zero) { return $null }
        return ('{0}%' -f ([System.Math]::Round(($partial.Ticks / $total.Ticks) * 100), 2))
    }
}