param($Context)

$context.Set('StackResourcesName', 'stackresources#{UDP}')
$context.Set('StackResourcesKey', (Get-AzureRmStorageAccountKey -ResourceGroupName $context.Get('InfraRg')  -Name $context.Get('StackResourcesName'))[0].Value)

$stackresources = New-AzureStorageContext -StorageAccountName $Context.Get('StackResourcesName') -StorageAccountKey $context.Get('StackResourcesKey')

$context.SetSensitive($context.Get('Password'), 'ProtectedImportHello', 'Hello')
$context.SetSensitive($context.Get('Password'), 'ServicePrincipalPassword', $context.Get('Password'))
$context.SetSensitive($context.Get('Password'), 'SSHPassword', $context.Get('Password'))
$context.SetHashed('PasswordHash', $context.Get('Password'))
$context.Set('ApiKey', ('API-AUTOMATION{0}' -f $context.Get('UDP')))
$context.SetApiKeyId('ApiKeyId', $context.Get('ApiKey'))
$context.SetHashed('ApiKeyHash', $context.Get('ApiKey'))

Write-Host -ForegroundColor Green "`tUploading Octopus Deploy..."
$octopusStorageShare = Get-AzureStorageShare -Name octopusdeploy -Context $stackresources -ErrorAction SilentlyContinue
if(!$octopusStorageShare) {
    $octopusStorageShare = New-AzureStorageShare -Name octopusdeploy -Context $stackresources
}
$source = Get-Item -Path (Join-Path -Resolve $PSScriptRoot '..\Resources\OctopusDeploy Export') | % FullName
Get-ChildItem -Path $source -Directory -Recurse | % {
    $destFolder = $_.FullName.Substring($source.Length)
    New-AzureStorageDirectory -Share $octopusStorageShare -Path $destFolder -ErrorAction Ignore | Out-Null
}
Get-ChildItem -Path $source -Recurse -File | % {
    if ($_.Name -in @('metadata.json','server.json','Automation Stack Parameters-VariableSet.json','Microsoft Azure Service Principal.json','Tentacle Auth.json','#{AzureRegion}.json','#{ApiKeyId}.json','#{Username}.json')) {
        Write-Host "Tokenising file $($_.Name)"
        $sourceFile = (New-TemporaryFile).FullName
        $Context.ParseFile($_.FullName, $sourceFile)
    } else {
        $sourceFile = $_.FullName
    }
    $destFile = $Context.Eval($_.FullName.Substring($source.Length+1).Replace('\','/'))
    Write-Host "Uploading $destFile"
    Set-AzureStorageFileContent -Share $octopusStorageShare -Source $sourceFile -Path $destFile -Force
}
Write-Host
Write-Host -ForegroundColor Green "`tUploading ARM Custom Scripts..."
$storageContainer = Get-AzureStorageContainer -Name "scripts" -Context $stackresources -ErrorAction SilentlyContinue
if(!$storageContainer) {
    $storageContainer = New-AzureStorageContainer -Name "scripts" -Context $stackresources -Permission Off
}
$source = Get-Item -Path (Join-Path -Resolve $PSScriptRoot '..\Resources\ARM Custom Scripts') | % FullName
Get-ChildItem -Path $source -Recurse -File | % {
    $sourceFile = (New-TemporaryFile).FullName
    $Context.ParseFile($_.FullName, $sourceFile)

    Write-Host "Uploading $($_.Name)"
    $storageContainer | Set-AzureStorageBlobContent -File $sourceFile -Blob $_.Name -Force | Out-Null
}
Write-Host
Write-Host -ForegroundColor Green "`tUploading DSC Configurations..."
$dscStorageShare = Get-AzureStorageShare -Name dsc -Context $stackresources -ErrorAction SilentlyContinue
if(!$dscStorageShare) {
    $dscStorageShare = New-AzureStorageShare -Name dsc -Context $stackresources
}
$source = Get-Item -Path (Join-Path -Resolve $PSScriptRoot '..\Resources\DSC Configurations') | % FullName
Get-ChildItem -Path $source -Recurse -File | % {
    Write-Host "Uploading $($_.Name)"
    Set-AzureStorageFileContent -Share $dscStorageShare -Source $_.FullName -Path $_.Name -Force
}
Write-Host
