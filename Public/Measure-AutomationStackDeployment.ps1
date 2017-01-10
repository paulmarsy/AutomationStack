function Measure-AutomationStackDeployment {
    Write-Host "Total deployment time: $($CurrentContext.GetTiming('Deployment'))"
    Write-Host
    $padding = 40
    Write-Host 'Azure Service Principal & KeyVault'.PadRight(40) $CurrentContext.GetTiming('2')
    Write-Host 'Core Infrastructure'.PadRight(40) $CurrentContext.GetTiming('3')
    Write-Host 'Octopus Deploy - DSC Configuration'.PadRight(40) $CurrentContext.GetTiming('4')
    Write-Host 'Octopus Deploy - Infrastructure'.PadRight(40) $CurrentContext.GetTiming('5')
    Write-Host 'AutomationStack Resources'.PadRight(40) $CurrentContext.GetTiming('6')
    Write-Host 'Octopus Deploy - Initial State'.PadRight(40) $CurrentContext.GetTiming('7')
    Write-Host 'Octopus Deploy - Resize VM'.PadRight(40) $CurrentContext.GetTiming('8')
}