param($Context)

$stackresources = New-AzureStorageContext -StorageAccountName $Context.Get('StackResourcesName') -StorageAccountKey $context.Get('StackResourcesKey')

Write-Host 'Uploading Octopus Deploy Configuration...'
New-AzureStorageShare -Name octopusdeployrestore -Context $stackresources
& net use O: \\$Context.Get('StackResourcesName').file.core.windows.net\octopusdeployrestore /u:$Context.Get('StackResourcesName') $context.Get('StackResourcesKey')
Get-ChildItem -Path O: -Recurse | Remove-Item -Force
Copy-Item -Path (Join-Path -Resolve $PSScriptRoot '..\Resources\OctopusDeploy Export') -Destination O: -Recurse
Get-ChildItem -Path O: -Recurse -File | % { $Context.ParseFile($_.FullName) } 
& net use O: /DELETE



Write-Host 'Importing Automation Stack functionality into Octopus Deploy...'
New-AzureStorageContainer -Name "scripts" -Context $stackresources
$tempFile = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, 'ps1')
$Context.ParseFile((Join-Path $PSScriptRoot '..\Resources\OctopusImport.ps1'), $tempFile)
Set-AzureStorageBlobContent -Container "scripts" -File $tempFile -Blob "OctopusImport.ps1" -Context $stackresources

Set-AzureRmVMCustomScriptExtension -ResourceGroupName $Context.Get('OctopusRg') -Location $Context.Get('AzureRegion') -VMName $Context.Get('OctopusVMName') -Name "OctopusImport" -StorageAccountName $Context.Get('StackResourcesName') -StorageAccountKey $Context.Get('StackResourcesKey')  -FileName "OctopusImport.ps1" -ContainerName "scripts"

