function Send-ToOctopusPackageFeed {
    param(
        $Path,
        $PackageName
    )

    $version = Get-InternalSemVer
    Write-Host "Publishing package $PackageName (v$version) to feed... " -NoNewline
    $packageFile = Join-Path $TempPath ('{0}.{1}.zip' -f $PackageName, $version)

    try {
        Compress-Archive -Path "$Path\*" -DestinationPath $packageFile -CompressionLevel Optimal
        
        [System.Net.WebClient]::new().UploadFile(('{0}api/packages/raw?apiKey={1}' -f $CurrentContext.Get('OctopusHostHeader'), $CurrentContext.Get('ApiKey')), $packageFile) | Out-Null

        Write-Host 'done'
    }
    finally {
        Remove-Item -Path $packageFile -Force
    }
}