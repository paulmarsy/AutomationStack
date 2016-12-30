param($Context, $octosprache)

$stackresourcesName = 'stackresources{0}' -f $Context.UDP
$stackresourcesKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $Context.InfraRg  -Name $stackresourcesName)[0].Value

$stackresources = New-AzureStorageContext -StorageAccountName $stackresourcesName -StorageAccountKey $stackresourcesKey
New-AzureStorageShare -Name octopusdeployrestore -Context $stackresources

& net use O: \\$stackresourcesName.file.core.windows.net\octopusdeployrestore /u:$stackresourcesName $stackresourcesKey
Copy-Item -Path (Join-Path -Resolve $PSScriptRoot '..\Resources\OctopusDeploy Export') -Destination O: -Recurse

Get-ChildItem -Path O: -Recurse -File | % { $octosprache.ParseFile($_.FullName) } 