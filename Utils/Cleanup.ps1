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
        Select-AzureRmProfile -Profile $AzureProfile
        Select-AzureRmSubscription  -SubscriptionId $SubscriptionId
        Write-Output "Starting removal of resource group..."
        Remove-AzureRmResourceGroup -Name $RG -Force
        Write-Output "Finished removing $RG"
        if (Test-Path $AzureProfile) {
            Remove-Item -Path $AzureProfile -Force
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

if ($PassThru) { return $jobs }
else { $jobs | Wait-Job | Receive-Job }