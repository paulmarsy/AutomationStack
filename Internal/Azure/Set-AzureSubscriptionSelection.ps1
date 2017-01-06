function Set-AzureSubscriptionSelection {
    $azureRm = Get-AzureRmContext | % Subscription | % SubscriptionId 
    $azureSm = Get-AzureSubscription -Current | % SubscriptionID

    $subscriptions = Get-AzureRmSubscription
    $i = 0
    $result = $Host.UI.PromptForChoice("Azure Subscripton", "Select Azure Subscription where AutomationStack should be deployed", ([System.Management.Automation.Host.ChoiceDescription[]]($subscriptions | % {
        $additionalText = ''
        if ($_.SubscriptionId -eq $azureRm -and $_.SubscriptionId -eq $azureSm) { $additionalText = '- Current RM & SM Context' }
        elseif ($_.SubscriptionId -eq $azureRm) { $additionalText = '- Current RM Context' }
        elseif ($_.SubscriptionId -eq $azureSm) { $additionalText = '- Current SM Context' }
        $i = $i + 1
        New-Object System.Management.Automation.Host.ChoiceDescription " [&$i] $($_.SubscriptionName.PadRight(40)) $($_.SubscriptionId) $($additionalText.PadRight(400))"
    })), -1)

    Select-AzureSubscription -SubscriptionId  $subscriptions[$result].SubscriptionId
    Set-AzureRmContext -SubscriptionId  $subscriptions[$result].SubscriptionId
}