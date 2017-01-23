function Start-DeploymentStage {
    param($StageNumber, $Heading, $ScriptBlock)
    
    $RetryAttemptsAllowed = 2

    $attempt = 0
    $currentLineOneText = 'Stage #{0} of {1}' -f $StageNumber, $TotalDeploymentStages
    while ($attempt -lt $RetryAttemptsAllowed) {
        $attempt++
        Write-DeploymentUpdate -StageNumber $StageNumber -ProgressText $Heading -LineOneText $currentLineOneText -LineTwoText $Heading

        try {
            if ($null -ne $CurrentContext) { 
                $metrics = New-Object AutoMetrics $CurrentContext
                $metrics.Start($StageNumber, $Heading)
            }

            $ScriptBlock.Invoke()
            break
        }
        catch {
            if (!(Write-ResolvedException $_.Exception.InnerException -and !(Write-ResolvedException $_.Exception))) {
                $global:AutomationException = $_
                Write-Warning 'Unable to resolve exception, check variable $AutomationException'
            }

            Write-Host
            if ($attempt -eq $RetryAttemptsAllowed) {
                Write-Host -ForegroundColor Red 'FATAL: Retry attempts exceeded'
                break execution
            }
            Write-Host 'Retrying stage in 30 seconds...'
            Start-Sleep -Seconds 30
            $currentLineOneText = 'Stage #{0} of {1} (Attempt #{2} of {3})' -f $StageNumber, $TotalDeploymentStages, ($attempt + 1), $RetryAttemptsAllowed
        }
                
    }
    if ($null -eq $metrics) { $metrics = New-Object AutoMetrics $CurrentContext }
    $metrics.Finish($StageNumber)
}