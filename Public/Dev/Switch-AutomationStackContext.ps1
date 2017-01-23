function Switch-AutomationStackContext {
    param($UDP)

    Write-Host "Loading deployment context: $UDP"
    $script:CurrentContext = New-Object Octosprache $UDP
}