class AutoMetrics {
    AutoMetrics() {
        $this.VariableDictionary = New-Object Octostache.VariableDictionary ([AutoMetrics]::GetBackingFile())
    }

    hidden $VariableDictionary

    hidden static [string]GetBackingFile() {
        return (Join-Path $script:DeploymentsPath ('{0}.metrics.json' -f $script:CurrentContext.Get('UDP')))
    }

    static Start([string]$Key, [string]$Description) {
        $currentVariableDictionary = New-Object Octostache.VariableDictionary ([AutoMetrics]::GetBackingFile())
        if ($currentVariableDictionary.Get('DeploymentComplete') -eq 'True') { return }

        if ($Key -eq 1) {
            $currentVariableDictionary.Set('Timing[Deployment].Start', (Get-Date))
        }
        $count = $currentVariableDictionary.GetInt32(('Timing[{0}].Count' -f $Key))
        if ($count) { $count++ }
        else { $count = 1 }
        $currentVariableDictionary.Set(('Timing[{0}].Start' -f $Key), (Get-Date))
        $currentVariableDictionary.Set(('Timing[{0}].Count' -f $Key), $count)
        $currentVariableDictionary.Set(('Timing[{0}].Description' -f $Key), $Description)
        $currentVariableDictionary.Save()
    }
    static Finish([string]$Key) {
        $currentVariableDictionary = New-Object Octostache.VariableDictionary ([AutoMetrics]::GetBackingFile())
        if ($currentVariableDictionary.Get('DeploymentComplete') -eq 'True') { return }

        $currentVariableDictionary.Set(('Timing[{0}].End' -f $Key), (Get-Date))
        if ($Key -eq $script:TotalDeploymentStages) {
            $currentVariableDictionary.Set('Timing[Deployment].End', (Get-Date))
            $currentVariableDictionary.Set('DeploymentComplete', $true)
        }
        $currentVariableDictionary.Save()
    }

    [string] GetDescription([string]$Key) {
         $description = $this.VariableDictionary.Get(('Timing[{0}].Description' -f $Key))
         if (!$description) { return 'Not yet started' }
         else { return  $description }
    }
    [string] Get([string]$Key, [string]$Property) {
         return $this.VariableDictionary.Get(('Timing[{0}].{1}' -f $Key, $Property))
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