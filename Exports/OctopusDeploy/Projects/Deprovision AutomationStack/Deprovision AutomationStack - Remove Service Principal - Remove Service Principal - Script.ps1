Start-Sleep 3
Get-AzureRmADApplication -DisplayNameStartWith ('AutomationStack{0}' -f $UDP) | Remove-AzureRmADApplication -Force
