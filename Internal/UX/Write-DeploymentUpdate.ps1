function Write-DeploymentUpdate {
    param($StageNumber, $ProgressText, $LineOneText, $LineTwoText)

    $lineTwo = '{0}{1}{0}' -f (' '*3), $LineTwoText
    $lineOne = $LineOneText.PadLeft(($lineTwo.Length / 2) + ($LineOneText.Length / 2)).PadRight($lineTwo.Length)
    $leftPadding = [System.Math]::Floor((($Host.UI.RawUI.BufferSize.Width-4) - $lineTwo.Length) / 2)
    $rightPadding = $leftPadding+($lineOne.Length % 2)
    Write-Progress -Activity ('AutomationStack Deployment - Stage #{0} of {1}' -f $StageNumber, $TotalDeploymentStages) -Status $ProgressText -PercentComplete ($StageNumber/$TotalDeploymentStages*100) 
    Write-Host 
    # Box corner, line for top of box, box corner
    Write-Host -ForegroundColor White (@(
        (' ')
        ([string][char]0x2554)
        ([string][char]0x2550)*($Host.UI.RawUI.BufferSize.Width-4)
        ([string][char]0x2557)) -join '')
    # Line One
    Write-Host -ForegroundColor White -NoNewLine (@(' ',([string][char]0x2551)) -join '')
    Write-Host -NoNewLine (" "*$leftPadding)
    Write-Host -NoNewLine -BackgroundColor DarkCyan -ForegroundColor White $lineOne
    Write-Host -NoNewLine (" "*$rightPadding)
    Write-Host -ForegroundColor White ([string][char]0x2551)
    # Line Two
    Write-Host -ForegroundColor White -NoNewLine (@(' ',([string][char]0x2551)) -join '')
    Write-Host -NoNewLine (" "*$leftPadding)
    Write-Host -NoNewLine -BackgroundColor DarkCyan -ForegroundColor White $lineTwo
    Write-Host -NoNewLine (" "*$rightPadding)
    Write-Host -ForegroundColor White ([string][char]0x2551)
    # Box corner, line for bottom of box, box corner
    Write-Host -ForegroundColor White (@(
        (' ')
        ([string][char]0x255A)
        ([string][char]0x2550)*($Host.UI.RawUI.BufferSize.Width-4)
        ([string][char]0x255D)) -join '')
    Write-Host
    Write-Host 
}