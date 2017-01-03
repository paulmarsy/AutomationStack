param($Context,[switch]$ResetStorage)

$script:ConcurrentTasks = 8

$context.Set('StackResourcesName', 'stackresources#{UDP}')
$context.Set('StackResourcessKey', (Get-AzureRmStorageAccountKey -ResourceGroupName $context.Get('InfraRg')  -Name $context.Get('StackResourcesName'))[0].Value)
$stackresources = New-AzureStorageContext -StorageAccountName $Context.Get('StackResourcesName') -StorageAccountKey $context.Get('StackResourcesKey')

$context.SetSensitive($context.Get('Password'), 'ProtectedImportHello', 'Hello')
$context.SetSensitive($context.Get('Password'), 'ServicePrincipalPassword', $context.Get('Password'))
$context.SetSensitive($context.Get('Password'), 'SSHPassword', $context.Get('Password'))
$context.SetTeamCityHashed('TeamCityPasswordHash', $context.Get('Password'))
$context.SetOctopusHashed('OctopusPasswordHash', $context.Get('Password'))
$context.Set('ApiKey', ('API-AUTOMATION{0}' -f $context.Get('UDP')))
$context.SetApiKeyId('ApiKeyId', $context.Get('ApiKey'))
$context.SetOctopusHashed('ApiKeyHash', $context.Get('ApiKey'))

function Upload-ToBlobContainer {
    param(
        [string]$Source,
        [string]$ContainerName,
        [string[]]$TokeniseFiles
    )

    $storageContainer = Get-AzureStorageContainer -Name $ContainerName -Context $stackresources -ErrorAction SilentlyContinue
    if ($ResetStorage) {
        Write-Host "Removing $ContainerName storage container"
        $storageContainer | Remove-AzureStorageContainer -Force -Context $stackresources
        return
    }
    if(!$storageContainer) {
        $storageContainer = New-AzureStorageContainer -Name $ContainerName -Context $stackresources -Permission Off
    }
    $sourcePath = Get-Item -Path $Source | % FullName
    Get-ChildItem -Path $sourcePath -Recurse -File | % {
        if ($_.Name -in $TokeniseFiles) {
            [Console]::WriteLine("Tokenising $($_.Name)")
            $sourceFile = (New-TemporaryFile).FullName
            $Context.ParseFile($_.FullName, $sourceFile)
        } else {
            $sourceFile = $_.FullName
        }
        [Console]::WriteLine("Uploading $($_.Name)")
        $storageContainer | Set-AzureStorageBlobContent -File $sourceFile -Blob $_.Name -Force -ConcurrentTaskCount $script:ConcurrentTasks | Out-Null
    }
}
function Upload-ToFileShare {
    param(
        [string]$Source,
        [string]$FileShareName,
        [string[]]$TokeniseFiles
    )

    $fileShare = Get-AzureStorageShare -Name $FileShareName -Context $stackresources -ErrorAction SilentlyContinue
    if ($ResetStorage) {
        Write-Host "Removing $FileShareName storage share"
        $fileShare | Remove-AzureStorageShare -Force -Context $stackresources
        return
    }
    if(!$fileShare) {
        $fileShare = New-AzureStorageShare -Name $FileShareName -Context $stackresources
    }
    $sourcePath = Get-Item -Path $Source | % FullName
    $items = Get-ChildItem -Path $sourcePath -Recurse -File
    $batchSize = [System.Math]::Max(([System.Math]::Ceiling(($items.Count / $script:ConcurrentTasks))), $script:ConcurrentTasks)
    $jobs ={@()}.Invoke()
    $runspaceId = 0
    for ($i = 0; $i -lt $items.Count; $i = $i + $batchSize) {
        $runspaceId++
        $batch = @($i..($i+$batchSize) | ? { $null -ne $items[$_] } |  % { $items[$_] })
        $ps = [powershell]::Create().AddScript({
            param($batch, $Context, $TokeniseFiles, $fileShare, $sourcePath, $runspaceId)
            $batch | % {
                if ($_.Name -in $TokeniseFiles) {
                    [Console]::WriteLine("[$runspaceId] Tokenising $($_.Name)")
                    $sourceFile = (New-TemporaryFile).FullName
                    $Context.ParseFile($_.FullName, $sourceFile)
                } else {
                    $sourceFile = $_.FullName
                }
                $destFolder = $_.FullName.Substring($sourcePath.Length)
               $destFile = $Context.Eval($_.FullName.Substring($sourcePath.Length+1).Replace('\','/'))
                [Console]::WriteLine("[$runspaceId] Uploading $destFile")
                New-AzureStorageDirectory -Share $fileShare -Path ([System.IO.Path]::GetDirectoryName($destFile)) -ErrorAction Ignore -ConcurrentTaskCount $script:ConcurrentTasks | Out-Null
               Set-AzureStorageFileContent -Share $fileShare -Source $sourceFile -Path $destFile -Force --ConcurrentTaskCount $script:ConcurrentTasks
            }
        }).AddArgument($batch).AddArgument($Context).AddArgument($TokeniseFiles).AddArgument($fileShare).AddArgument($sourcePath).AddArgument($runspaceId)
        $jobs.Add(@{
            PowerShell = $ps
            Async = ($ps.BeginInvoke())
        })
    }
    do {
        $running = $false
        $jobs.GetEnumerator() | % {
            if ($_.Async.IsCompleted) { $_.Powershell.EndInvoke($_.Async) }
            else { $running = $true }
        }
    } while ($running)
}

Write-Host
Write-Host -ForegroundColor Green "`tARM Custom Scripts..."
Upload-ToBlobContainer -ContainerName scripts -Source (Join-Path -Resolve $PSScriptRoot '..\Resources\ARM Custom Scripts') -TokeniseFiles @()
 
Write-Host
Write-Host -ForegroundColor Green "`tDSC Configurations..."
Upload-ToFileShare -FileShareName dsc -Source (Join-Path -Resolve $PSScriptRoot '..\Resources\DSC Configurations') -TokeniseFiles @()

Write-Host
Write-Host -ForegroundColor Green "`tOctopus Deploy..."
Upload-ToFileShare -FileShareName octopusdeploy -Source (Join-Path -Resolve $PSScriptRoot '..\Resources\OctopusDeploy Export') -TokeniseFiles @('metadata.json','server.json','Automation Stack Parameters-VariableSet.json','Microsoft Azure Service Principal.json','Tentacle Auth.json','#{AzureRegion}.json','#{ApiKeyId}.json','#{Username}.json')

Write-Host
Write-Host -ForegroundColor Green "`tTeamCity..."
Upload-ToFileShare -FileShareName teamcity -Source (Join-Path -Resolve $PSScriptRoot '..\Resources\TeamCity Export') -TokeniseFiles @('vcs_username','users','database.properties')

Write-Host