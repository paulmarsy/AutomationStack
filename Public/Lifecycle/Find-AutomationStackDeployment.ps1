function Find-AutomationStackDeployment {
    @(
        (Get-AzureRmADApplication -DisplayNameStartWith  'AutomationStack' | % { $_.DisplayName.Substring(15,4) })
        (Find-AzureRmResourceGroup | ? Name -like 'AutomationStack????' | % { $_.name.Substring(15,4) })
    ) | Select-Object -Unique | % {
        $rg = ($null -ne (Get-AzureRmResourceGroup -Name "AutomationStack$_" -ErrorAction Ignore))
        if ($rg) {
            $timestamp = Get-AzureRmResourceGroupDeployment -ResourceGroupName "AutomationStack$_" | % Timestamp | Sort-Object | Select-Object -First 1 | % ToString 'G'
        } else {
            $timestamp = 'Unknown'
        }
        New-Object PSCustomObject -Property @{
            Timestamp = $timestamp
            UDP = $_
            AzureAD = ($null -ne (Get-AzureRmADApplication -DisplayNameStartWith  "AutomationStack$_"))
            ResourceGroup = $rg
        }
    } | Format-Table -AutoSize -Property @('Timestamp','UDP','AzureAD','ResourceGroup')
}