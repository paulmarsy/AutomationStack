function Set-AzureSubscriptionSelection {
    $currentAzureRmSub = Get-AzureRmContext | % Subscription | % SubscriptionId 

    $subscriptions = Get-AzureRmSubscription
    $defaultChoice = -1
    $i = 0
    $result = $Host.UI.PromptForChoice("Azure Subscripton", "Select Azure Subscription for AutomationStack", ([System.Management.Automation.Host.ChoiceDescription[]]($subscriptions | % {
        $additionalText = ''
        if ($_.SubscriptionId -eq $currentAzureRmSub) {
            $additionalText = '- Current subscription'
            $defaultChoice = $i
        }
        $i = $i + 1
        if ($i -eq $subscriptions.Count) { $lastLineSpacing = "`nSelect where to deploy AutomationStack"}
        New-Object System.Management.Automation.Host.ChoiceDescription ("$($_.SubscriptionName.PadRight(40)) ($($_.SubscriptionId)) [&$i] $($additionalText)`n$($lastLineSpacing)")
    })), $defaultChoice)

    Set-AzureRmContext -SubscriptionId  $subscriptions[$result].SubscriptionId
}