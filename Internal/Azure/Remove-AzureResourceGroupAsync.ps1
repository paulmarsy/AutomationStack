function Remove-AzureResourceGroupAsync {
    param($Name, $ResourceGroupName)

    Write-Host "Removing Resource Group $Name..."

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