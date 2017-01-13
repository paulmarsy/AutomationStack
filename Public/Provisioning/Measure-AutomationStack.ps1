function Measure-AutomationStack {
    $metrics = New-Object AutoMetrics $CurrentContext
    Write-Host @($metrics.GetDescription('Deployment'), ': ', $metrics.GetDuration('Deployment'))
    Write-Host
    1..10 | % {
        New-Object psobject -Property @{
            Number = $_
            Activity = $metrics.GetDescription($_)
            Duration = $metrics.GetDuration($_)
            Percentage = $metrics.GetPercentage($_, 'Deployment')
        }
    } | Sort-Object -Property Number | Format-Table -AutoSize -Property @('Number','Activity','Duration','Percentage')
}