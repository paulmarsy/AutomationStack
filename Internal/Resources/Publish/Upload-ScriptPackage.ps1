function Upload-ScriptPackage {
    param(
        $Path,
        $PackageName,
        $Context
    )

    [Console]::WriteLine("   `t`t`t`tPackaging`t`t$PackageName")
    $packageFile = Join-Path $TempPath ('{0}.zip' -f $PackageName)

    try {
        Compress-Archive -Path "$Path\*" -DestinationPath $packageFile -CompressionLevel Optimal
        
        Upload-StackResources -Type FileShare -Name dataimports -Path $packageFile -Tokenizer $CurrentContext -Context $Context
    }
    finally {
        Remove-Item -Path $packageFile -Force
    }
}