function Write-DeploymentUpdate {
    param($SequenceNumber, $TotalStages, $ProgressText, $Heading)

    $text = '{0}{1}{0}' -f (' '*3), $Heading
    Write-Progress -Activity ('AutomationStack Deployment - Stage #{0} of {1}' -f $SequenceNumber, $TotalStages) -Status $ProgressText -PercentComplete ($SequenceNumber/$TotalStages*100) 
    Write-Host 
    # Box corner, line for top of box, box corner
    Write-Host -ForegroundColor White (@(
        (' ')
        ([string][char]0x2554)
        ([string][char]0x2550)*([System.Console]::BufferWidth-4)
        ([string][char]0x2557)) -join '')
    # Box edge
    Write-Host -ForegroundColor White -NoNewLine (@(' ',([string][char]0x2551)) -join '')
    # Left spacing so the center of the text is the center of the console
    $padding = [System.Math]::Floor((([System.Console]::BufferWidth-4) - $text.Length) / 2)
    Write-Host -NoNewLine (" "*$padding)
    # The heading..
    Write-Host -NoNewLine -BackgroundColor DarkCyan -ForegroundColor White $text
    if ($text.Length % 2 -eq 1) { $padding++ }
    # Right spacing to place the far right box edge
    Write-Host -NoNewLine (" "*$padding)
    # Box edge
    Write-Host -ForegroundColor White ([string][char]0x2551)
    # Box corner, line for bottom of box, box corner
    Write-Host -ForegroundColor White (@(
        (' ')
        ([string][char]0x255A)
        ([string][char]0x2550)*([System.Console]::BufferWidth-4)
        ([string][char]0x255D)) -join '')
    Write-Host
    Write-Host 
}