function Import-OctopusDeployInitialState {
    Write-Host "Importing initial state into Octopus Deploy"
    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $CurrentContext.Get('OctopusRg') -Location $CurrentContext.Get('AzureRegion') -VMName $CurrentContext.Get('OctopusVMName') -Name "OctopusImport" -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')  -FileName "OctopusImport.ps1" -ContainerName "scripts"
    Get-AzureRmVMExtension -ResourceGroupName $CurrentContext.Get('OctopusRg') -VMName $CurrentContext.Get('OctopusVMName') -Name "OctopusImport"  -Status | % SubStatuses | % Message | % Replace '\n' "`n" | Write-Host

    $logFilePath =Join-Path $TempPath 'CustomScript.log'
    $stackresources = New-AzureStorageContext -StorageAccountName $CurrentContext.Get('StackResourcesName') -StorageAccountKey $CurrentContext.Get('StackResourcesKey')
  
    Get-AzureStorageFileContent -ShareName octopusdeploy -Path 'CustomScript.log' -Destination $logFilePath -Force -Context $stackresources
    Get-Content -Path $logFilePath | % { Write-Host "[Custom Script Log] $_" }
    Remove-AzureStorageFile  -ShareName octopusdeploy -Path 'CustomScript.log'  -Context $stackresources
}