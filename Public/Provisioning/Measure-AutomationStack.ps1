function Measure-AutomationStack {
    $metrics = New-Object AutoMetrics $CurrentContext
    Write-Host @($metrics.GetDescription('Deployment'), ': ', $metrics.GetDuration('Deployment'))
    Write-Host
    1..9 | % {
        New-Object psobject -Property @{
            Stage = $_
            Activity = $metrics.GetDescription($_)
            Duration = $metrics.GetDuration($_)
            Percentage = $metrics.GetPercentage($_, 'Deployment')
        }
    } | Sort-Object -Property Stage | Format-Table -AutoSize -Property @('Stage','Activity','Duration','Percentage')
}