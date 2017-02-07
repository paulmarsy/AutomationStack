function Show-AutomationStackUsage {
    param(
        [switch]$All,
        $UDP,
        $BillingPeriodDuration = 21
    )

    const AzureOfferNumber = '0063P'
    const Currency = 'GBP'
    const Locale = 'en-GP'
    const RegionInfo = 'GB'

    if ($null -ne $CurrentContext -and $null -eq $UDP) {
        $UDP  = $CurrentContext.Get('UDP')
    }

    Write-Host -NoNewLine -ForegroundColor Yellow 'Getting Azure Billing RateCard... '
    $rateCard = Invoke-AzureRestApi -ResourceId '/providers/Microsoft.Commerce/RateCard' -WithoutSubscriptionId `
                -ODataQuery ("`$filter=OfferDurableId eq 'MS-AZR-{0}' and Currency eq '{1}' and Locale eq '{2}' and RegionInfo eq '{3}'" -f `
                    $AzureOfferNumber,
                    $Currency,
                    $Locale,
                    $RegionInfo)
    Write-Host -ForegroundColor DarkGreen 'done'  

    Write-Host -NoNewLine -ForegroundColor Yellow 'Downloading Azure Usage Aggregates... '
    $now = Get-Date
    $billingPeriodEnd = (Get-Date -Year $now.Year -Month $now.Month -Day $now.Day -Hour $now.Hour -Minute 0 -Second 0 -Millisecond 0).AddHours(-1)
    $billingPeriodStart = $billingPeriodEnd.AddDays($BillingPeriodDuration * -1).AddHours(-1)
    $usage = Invoke-AzureRestApi -ResourceId '/providers/Microsoft.Commerce/UsageAggregates' -WithoutSubscriptionId `
                -ODataQuery ('&reportedStartTime={0}&reportedEndTime={1}&aggregationGranularity=Daily&showDetails=true' -f `
                $billingPeriodStart.ToString('yyyy-MM-ddT00:00:00Z'),
                $billingPeriodEnd.ToString('yyyy-MM-ddT00:00:00Z'))
    Write-Host -ForegroundColor DarkGreen 'done'  

    if ($usage.error) {
        Write-Warning $usage.error
        return
    }

    $total = 0
    $billingData = $usage | 
        % value |
        % properties |
        ? { $null -ne $_.instanceData } |
        ? {
            $data = $_.instanceData | ConvertFrom-Json | % Microsoft.Resources
            $data.tags.application -eq 'AutomationStack' -and ($data.tags.udp -eq $UDP -or $All)
        }  |
        % {
            $rate = $ratecard.Meters | ? meterId -eq $_.meterId | % meterRates
            $price = $_.quantity * $rate.0
            New-Object psobject -Property @{ 
                UDP = $data.tags.udp
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
            $total += $resourcePrice
            if ([string]::IsNullOrWhitespace($_.Group[0].SubCategory) -or $_.Group[0].Category -eq 'Virtual Machines') {
                $category = $_.Group[0].Category
            } else {
                $category = '{0} - {1}' -f $_.Group[0].Category, $_.Group[0].SubCategory
            }
            New-Object psobject -Property @{ 
                UDP = $_.Group[0].Udp
                ResourceName = [Microsoft.Azure.Commands.ResourceManager.Cmdlets.Components.ResourceIdUtility]::GetResourceName($_.Group[0].Uri)
                Price = '{0:C}' -f $resourcePrice
                Quantity = [System.Math]::Round($resourceQuantity, 3)
                Name = $_.Group[0].Name
                Category = $category
            }
        }
    Write-Host -ForegroundColor DarkGreen 'done'  
   
    if ($All) { $propertiesToDisplay = @('UDP','ResourceName','Category','Name','Quantity','Price') }
    else { $propertiesToDisplay = @('ResourceName','Category','Name','Quantity','Price') }

    $billingData |
        Sort-Object -Property Udp,Price,ResourceName,Category,Name -Descending |
        Format-Table -Property $propertiesToDisplay -AutoSize

    Write-Host -ForegroundColor Magenta ('Total: {0:C}' -f $total)
}