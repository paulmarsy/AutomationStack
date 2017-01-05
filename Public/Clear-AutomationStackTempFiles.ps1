function Clear-AutomationStackTempFiles {
    Write-Host "Cleaning up $DeploymentsPath"
    Remove-Item -Path $DeploymentsPath -Recurse -Force
    New-Item -ItemType Directory -Path $DeploymentsPath | Out-Null
    
    Write-Host "Cleaning up $TempPath"
    Remove-Item -Path $TempPath -Recurse -Force -ErrorAction Ignore
    New-Item -ItemType Directory -Path $TempPath | Out-Null
}