function Measure-AutomationStack {
    Write-Host @($CurrentContext.GetTimingDescription('Deployment'), ': ', $CurrentContext.GetTiming('Deployment'))
    Write-Host
    1..10 | % {
        New-Object psobject -Property @{
            Number = $_
            Activity = $CurrentContext.GetTimingDescription($_)
            Duration = $CurrentContext.GetTiming($_)
        }
    } | Sort-Object -Property Number | Format-Table -AutoSize -Property @('Number','Activity','Duration')
}