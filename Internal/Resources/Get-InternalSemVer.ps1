function Get-InternalSemVer {
    $metrics = New-Object AutoMetrics $CurrentContext
    $elapsed = (Get-Date) - ([datetime]$metrics.Get('Deployment','Start'))
    '{0}.{1}.{2}' -f ($elapsed.Days*24+$elapsed.Hours+1), $elapsed.Minutes, $elapsed.Seconds
}