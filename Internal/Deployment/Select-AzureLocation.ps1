function Select-AzureLocation {
    $azureLocation = Get-AzureRmLocation | % { @{ Name = $_.DisplayName; Value = $_.Location } }
    $i = 64
    $result = $Host.UI.PromptForChoice("Azure Region", "Select the Azure Region where resources should be created", ([System.Management.Automation.Host.ChoiceDescription[]]($azureLocation | % {
        $i++
        $text = '{0} [&{1}]' -f $_.Name.PadRight(20), ([char]$i)
        New-Object System.Management.Automation.Host.ChoiceDescription ('{0}{1}' -f $text, (([string][char]0xFEFF)*($Host.UI.RawUI.BufferSize.Width-$text.Length*2)))
    })), -1)

    $selected = $azureLocation[$result]
    Write-Host
    Write-Host "Selected $($selected.Name) ($($selected.Value))"
    Write-Host

    return $selected
}