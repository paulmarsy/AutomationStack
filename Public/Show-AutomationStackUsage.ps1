function Show-AutomationStackUsage {
    param(
        $UDP,
        $ForLastDays = 1,
        $AzureOfferNumber = '0063P',
        $Currency = 'GBP',
        $Locale = 'en-GP',
        $RegionInfo = 'GB',
        [switch]$NoFormat
    )

    if ($null -ne $CurrentContext -and $null -eq $UDP) {
        $UDP  = $CurrentContext.Get('UDP')
    }

    $rateCard = Invoke-AzureRestApi -ResourceId '/providers/Microsoft.Commerce/RateCard' -WithoutSubscriptionId `
                    -ODataQuery ("`$filter=OfferDurableId eq 'MS-AZR-{0}' and Currency eq '{1}' and Locale eq '{2}' and RegionInfo eq '{3}'" -f `
                        $AzureOfferNumber,
                        $Currency,
                        $Locale,
                        $RegionInfo)

    $usage = Invoke-AzureRestApi -ResourceId '/providers/Microsoft.Commerce/UsageAggregates' -WithoutSubscriptionId `
                    -ODataQuery ('&reportedStartTime={0}&reportedEndTime={1}&aggregationGranularity=Hourly&showDetails=true' -f `
                    (Get-Date).AddDays($ForLastDays * -1).ToString('yyyy-MM-dd'),
                    (Get-Date).ToString('yyyy-MM-dd'))

    if ($usage.error) {
        Write-Warning $usage.error
        return;
    }
    $total = 0
    $billingData = $usage.value |
        % properties |
        ? { $null -ne $_.instanceData } |
        ? {
            $data = $_.instanceData | ConvertFrom-Json | % Microsoft.Resources
            $data.tags.application -eq 'AutomationStack' -and $data.tags.udp -eq $UDP
        }  |
        % {
            $rate = $ratecard.Meters | ? meterId -eq $_.meterId | % meterRates
            $price = $_.quantity * $rate.0
            $total += $price
            New-Object psobject -Property @{ 
                Uri = $data.resourceUri
                Quantity = $_.quantity
                Price = $price
                Name = $_.meterName
                Category = $_.meterCategory
                SubCategory = $_.meterSubcategory
            }
        } |
        Group-Object -Property Uri,Name | 
        % {
            $resourcePrice = 0
            $resourceQuantity = 0
            $_.Group | % {
                $resourcePrice += $_.Price
                $resourceQuantity += $_.Quantity
            }
            if ([string]::IsNullOrWhitespace($_.Group[0].SubCategory) -or $_.Group[0].Category -eq 'Virtual Machines') {
                $category = $_.Group[0].Category
            } else {
                $category = '{0} - {1}' -f $_.Group[0].Category, $_.Group[0].SubCategory
            }
            New-Object psobject -Property @{ 
                ResourceName = [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Components.ResourceIdUtility]::GetResourceName($_.Group[0].Uri)
                Price = '{0:C}' -f $resourcePrice
                Quantity = [System.Math]::Round($resourceQuantity, 3)
                Name = $_.Group[0].Name
                Category = $category
            }
        }
        
    if ($NoFormat) {
        return @{
            TotalPrice = '{0:C}' -f $total
            Items = $billingData
         }
     } else {
         $billingData |
            Sort-Object -Property Price,ResourceName,Category,Name -Descending |
            Format-Table ResourceName,Category,Name,Quantity,Price

        Write-Host -ForegroundColor Magenta ('Total: {0:C}' -f $total)
     }
}