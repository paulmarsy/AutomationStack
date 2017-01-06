function Write-DeploymentUpdate {
    param($SeqNumber, $Stage, $Heading)

    $text = '{0}{1}{0}' -f (' '*3), $Heading
    Write-Progress -Activity 'AutomationStack Deployment' -Status $Stage -PercentComplete ($SeqNumber/9*100) 
    Write-Host 
    Write-Host -ForegroundColor White -BackgroundColor Black ('-'*([System.Console]::BufferWidth))
    Write-Host -NoNewLine (" "*((([System.Console]::BufferWidth) - $text.Length) / 2))
    Write-Host -BackgroundColor DarkCyan -ForegroundColor White $text
    Write-Host
}