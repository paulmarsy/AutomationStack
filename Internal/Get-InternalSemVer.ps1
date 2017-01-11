function Get-InternalSemVer {
    $deployStart = [datetime]$CurrentContext.Get('Timing[Deployment].Start')
    $elapsed = (Get-Date) - $deployStart
    '{0}.{1}.{2}' -f ($elapsed.Days*24+$elapsed.Hours+1), $elapsed.Minutes, $elapsed.Seconds
}