function Measure-AutomationStack {
    $metrics = New-Object AutoMetrics
    $elapsed = [timespan]::Zero
    (1..$TotalDeploymentStages) | % {
        $elapsed = $elapsed.Add($metrics.GetRaw($_))
        New-Object psobject -Property @{
            Stage = $_
            Activity = $metrics.GetDescription($_)
            Duration = $metrics.GetDuration($_)
            Percentage = $metrics.GetPercentage($_, 'Deployment')
        }
    } | Sort-Object -Property Stage | Format-Table -AutoSize -Property @('Stage','Activity','Duration','Percentage')
    Write-Host @('Total deployment time: ', $metrics.GetDuration('Deployment'))
    Write-Host @('Elapsed time: ', [Humanizer.TimeSpanHumanizeExtensions]::Humanize($elapsed, 2))
    $unaccounted = $metrics.GetRaw('Deployment') - $elapsed
    $unaccountedPercentage = '({0}%)' -f ([System.Math]::Round(($unaccounted.Ticks / $metrics.GetRaw('Deployment').Ticks) * 100), 2)
    Write-Host @('Time unaccounted for: ', [Humanizer.TimeSpanHumanizeExtensions]::Humanize($unaccounted, 2), $unaccountedPercentage)
}