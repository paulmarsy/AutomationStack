function Start-DeploymentStage {
    param($SequenceNumber, $TotalStages, $ProgressText, $Heading, $ScriptBlock)
    
    $RetryAttemptsAllowed = 2

    $attempt = 1
    $currentHeading = $Heading
    while ($attempt -le $RetryAttemptsAllowed) {
        Write-DeploymentUpdate -SequenceNumber $SequenceNumber -TotalStages $TotalStages -ProgressText $ProgressText -Heading $currentHeading

        try {
            if ($null -ne $CurrentContext) { $CurrentContext.TimingStart($SequenceNumber) }
            $ScriptBlock.Invoke()
            break
        }
        catch {
            $baseException = $_.Exception.GetBaseException()
            if ($null -eq $baseException.ErrorRecord) {
                $errorRecord = $_.Exception.ErrorRecord
            } else {
                $errorRecord = $baseException.ErrorRecord
            }
            Write-Warning "Deployment stage failed"
            Write-Warning "$($errorRecord.Exception.GetType().FullName): $($errorRecord.Exception.Message)"
            Write-Warning "`t$($errorRecord.Exception.GetType().FullName): $($errorRecord.Exception.InnerException.Message)"
            Write-Warning "Failing command: $($errorRecord.InvocationInfo.MyCommand.Name)"
            Write-Warning "Position of failing command:`n$($errorRecord.InvocationInfo.PositionMessage)"
            Write-Warning "Category: $($errorRecord.CategoryInfo.ToString())"
            Write-Warning "Script Stack Trace:`n$($errorRecord.ScriptStackTrace)"
            
            
            if ($attempt -eq $RetryAttemptsAllowed) {
                throw $errorRecord
            }
            Write-Warning 'Retrying stage in 30 seconds...'
            Start-Sleep -Seconds 30
            $attempt++
            $currentHeading = ('{0} (Attempt #{1} of {2}' -f $Heading, $attempt, $RetryAttemptsAllowed)
        }
                
    }
    $CurrentContext.TimingEnd($SequenceNumber)
}