function Remove-AutomationStack {
    param(
        [Parameter(Mandatory=$true)]$UDP,
        [switch]$PassThru
    )

    function Remove-ResourceGroup {
        param($Name, $ResourceGroupName)

        Write-Host "Removing $Name..."

        $azureprofile = [System.IO.Path]::GetTempFileName()
        Save-AzureRmProfile -Path $azureprofile -Force
        Start-Job -Name "RG-$ResourceGroupName" -ScriptBlock {
            param($SubscriptionId, $AzureProfile, $RG)
            Select-AzureRmProfile -Profile $AzureProfile | Out-Null
            Select-AzureRmSubscription  -SubscriptionId $SubscriptionId | Out-Null
            if (Get-AzureRmResourceGroup -Name $RG -ErrorAction Ignore) {
                Write-Output "Starting removal of resource group..."
                Remove-AzureRmResourceGroup -Name $RG -Force | Out-Null
                Write-Output "Finished removing $RG"
            } else {
                Write-Output "Resource Group $RG does not exist"
            }
            if (Test-Path $AzureProfile) {
                Remove-Item -Path $AzureProfile -Force | Out-Null
            }
        } -ArgumentList @((Get-AzureRmContext).Subscription.SubscriptionId, $azureprofile, $ResourceGroupName)
    }

    Write-Host 'Removing Service Principal...'
    Get-AzureRmADApplication -DisplayNameStartWith ('AutomationStack{0}' -f $UDP) | Remove-AzureRmADApplication -Force

    $jobs = @(
        (Remove-ResourceGroup 'TeamCity' ('TeamCityStack{0}' -f $UDP))
        (Remove-ResourceGroup 'Octopus Deploy' ('OctopusStack{0}' -f $UDP))
        (Remove-ResourceGroup 'Infrastructure' ('AutomationStack{0}' -f $UDP))
    )

    $configFile = Join-Path $PWD.ProviderPath ('AutomationStack {0} Config.json' -f $UDP)
    if (Test-Path $configFile) {
        Write-Host 'Removing json deployment config file...'
        Remove-Item -Path $configFile -Force
    }

    if ($PassThru) { return $jobs }
    else { $jobs | Wait-Job | Receive-Job }
}