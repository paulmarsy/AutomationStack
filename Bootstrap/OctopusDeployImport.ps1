param($OctopusStack, $Context)

$stackresourcesName = 'stackresources{0}' -f $Context.UDP
$stackresourcesKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $Context.InfraRg  -Name $stackresourcesName)[0].Value

$stackresources = New-AzureStorageContext -StorageAccountName $stackresourcesName -StorageAccountKey $stackresourcesKey
New-AzureStorageContainer -Name "scripts" -Context $stackresources

$octosprache = [octosprache]::new()
$octosprache.Add('Password', $Context.Password)
$octosprache.Add('StackresourcesName', $stackresourcesName)
$octosprache.Add('StackresourcesKey', $stackresourcesKey)

$tempFile = [System.IO.Path]::ChangeExtension((New-TemporaryFile).FullName, 'ps1')
$octosprache.ParseFile((Join-Path $PSScriptRoot '..\Resources\OctopusImport.ps1'), $tempFile)

Set-AzureStorageBlobContent -Container "scripts" -File $tempFile -Blob "OctopusImport.ps1" -Context $stackresources


Set-AzureRmVMCustomScriptExtension -ResourceGroupName $OctopusStack.VMResourceGroup -Location $Context.Region -VMName $OctopusStack.VMName -Name "OctopusImport" -StorageAccountName $stackresourcesName -StorageAccountKey $stackresourcesKey  -FileName "OctopusImport.ps1" -ContainerName "scripts"

