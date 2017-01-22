function Measure-AutomationStack {
    $metrics = New-Object AutoMetrics $CurrentContext
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
    Write-Host @($metrics.GetDescription('Deployment'), ': ', $metrics.GetDuration('Deployment'))
    Write-Host @('Elapsed time: ', [Humanizer.TimeSpanHumanizeExtensions]::Humanize($elapsed, 2))
}