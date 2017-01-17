function Find-AutomationStackDeployment {
    @(
        (Get-AzureRmADApplication -DisplayNameStartWith  'AutomationStack' | % { $_.DisplayName.Substring(15,4) })
        (Find-AzureRmResourceGroup | ? Name -like 'AutomationStack????' | % { $_.name.Substring(15,4) })
    ) | Select-Object -Unique | % {
        $infrastructure = ($null -ne (Get-AzureRmResourceGroup -Name "AutomationStack$_" -ErrorAction Ignore))
        if ($infrastructure) {
            $timestamp = Get-AzureRmResourceGroupDeployment -ResourceGroupName "AutomationStack$_" | % Timestamp | Sort-Object | Select-Object -First 1 | % ToString 'G'
        } else {
            $timestamp = 'Unknown'
        }
        New-Object PSCustomObject -Property @{
            Timestamp = $timestamp
            UDP = $_
            AzureAD = ($null -ne (Get-AzureRmADApplication -DisplayNameStartWith  "AutomationStack$_"))
            Infrastructure = $infrastructure
            OctopusDeploy = ($null -ne (Get-AzureRmResourceGroup -Name "OctopusStack$_" -ErrorAction Ignore))
            TeamCity = ($null -ne (Get-AzureRmResourceGroup -Name "TeamCityStack$_" -ErrorAction Ignore))
        }
    } | Format-Table -AutoSize -Property @('Timestamp','UDP','AzureAD','Infrastructure','OctopusDeploy','TeamCity')
}