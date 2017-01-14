param($ResourceGroupName, $PassThru)

$azureprofile = [System.IO.Path]::GetTempFileName()
Save-AzureRmProfile -Path $azureprofile -Force

$job = Start-Job -Name "RG-Remove-$ResourceGroupName" -ScriptBlock {
    param($SubscriptionId, $AzureProfile, $RG)
    Select-AzureRmProfile -Profile $AzureProfile | Out-Null
    Select-AzureRmSubscription  -SubscriptionId $SubscriptionId | Out-Null
    if (Get-AzureRmResourceGroup -Name $RG -ErrorAction Ignore) {
        Write-Output "Removing Resource Group '$RG'..."
        Remove-AzureRmResourceGroup -Name $RG -Force | Out-Null
        Write-Output "Resource Group '$RG' has been removed"
    } else {
        Write-Output "Resource Group '$RG' does not exist"
    }
    if (Test-Path $AzureProfile) {
        Remove-Item -Path $AzureProfile -Force | Out-Null
    }
} -ArgumentList @((Get-AzureRmContext).Subscription.SubscriptionId, $azureprofile, $ResourceGroupName)

if ($PassThru) { return $job }
else {
    $job | Receive-Job -AutoRemoveJob -Wait
}