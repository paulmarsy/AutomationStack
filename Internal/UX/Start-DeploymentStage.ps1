function Start-DeploymentStage {
    param($SequenceNumber, $TotalStages, $ProgressText, $Heading, $ScriptBlock, [switch]$WhatIf)
    
    $RetryAttemptsAllowed = 2

    $attempt = 0
    $currentHeading = $Heading
    while ($attempt -lt $RetryAttemptsAllowed) {
        $attempt++
        Write-DeploymentUpdate -SequenceNumber $SequenceNumber -TotalStages $TotalStages -ProgressText $ProgressText -Heading $currentHeading

        try {
            if ($null -ne $CurrentContext -and -not $WhatIf) { 
                $metrics = New-Object AutoMetrics $CurrentContext
                $metrics.Start($SequenceNumber, $Heading) }
            if ($WhatIf -and $SequenceNumber -notin @(1, 10)) {
                Write-Host 'Skipping in WhatIf mode'
                Start-Sleep -Seconds 1
            } else {
                $ScriptBlock.Invoke()
            }
            $attempt = $RetryAttemptsAllowed
        }
        catch {
           if (Test-ExceptionComplete $_.Exception.InnerException) { Write-Verbose "Inner Exception" }
           elseif (Test-ExceptionComplete $_.Exception.GetBaseException()) { Write-Verbose "Base Exception" }
           elseif (Test-ExceptionComplete $_.Exception) { Write-Verbose "Exception" }
           else {
               $_ | Format-List -Force | Out-Host
           }
            
            if ($attempt -eq $RetryAttemptsAllowed) {
                throw $baseException
            }
            Write-Warning 'Retrying stage in 30 seconds...'
            Start-Sleep -Seconds 30
            $currentHeading = ('{0} (Attempt #{1} of {2})' -f $Heading, ($attempt + 1), $RetryAttemptsAllowed)
        }
                
    }
    if ($null -eq $metrics) { $metrics = New-Object AutoMetrics $CurrentContext }
    $metrics.Finish($SequenceNumber)
}