param($Context, $octosprache)

$stackresourcesName = 'stackresources{0}' -f $Context.UDP
$stackresourcesKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $Context.InfraRg  -Name $stackresourcesName)[0].Value

$stackresources = New-AzureStorageContext -StorageAccountName $stackresourcesName -StorageAccountKey $stackresourcesKey
New-AzureStorageShare -Name octopusdeployrestore -Context $stackresources

if (Test-Path O:) {
    & net use O: /DELETE
}
& net use O: \\$stackresourcesName.file.core.windows.net\octopusdeployrestore /u:$stackresourcesName $stackresourcesKey
Get-ChildItem -Path O: -Recurse | Remove-Item -Force
Copy-Item -Path (Join-Path -Resolve $PSScriptRoot '..\Resources\OctopusDeploy Export') -Destination O: -Recurse

Get-ChildItem -Path O: -Recurse -File | % { $octosprache.ParseFile($_.FullName) } 
& net use O: /DELETE