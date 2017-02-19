function Install-AzureModules {
    param([switch]$All)

    filter Import-AzureModule {
        Write-Host -NoNewLine "Importing $_ Module... "
        Import-Module $_ -Force
        Write-Host -ForegroundColor Green 'imported'
    }
    $script:firstInstall = $true
    filter Assert-AzureModule {
        if (Get-Module -ListAvailable -Name $_) {
            $_ | Import-AzureModule
            return
        }
        if ($script:firstInstall) {
             Write-Host -NoNewLine 'Checking for Admin priviledges... '
             $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
             if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                 Write-Host -ForegroundColor Green 'Passed!'
             } else {
                Write-Host -ForegroundColor Red 'Failed!'
                Write-Host
                Write-Warning 'You do not have required Azure PowerShell Modules present to continue, and Administrator / UAC elevation is needed to install them'
                Write-Warning 'An elevated PowerShell prompt is being opened, where this process will continue...'
                Start-Process -WorkingDirectory $PWD.ProviderPath -FilePath 'powershell.exe' -Verb 'RunAs' -ArgumentList @('-NoExit','-Command','& { irm https://git.io/automationstack | iex }')
                break execution
             }

            Write-Host 'Configuring PowerShell 5 Package Management...'
            Install-PackageProvider -Name NuGet -Force | Out-Null
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted | Out-Null
            $script:firstInstall = $false
         }
        Write-Host -NoNewLine "Installing $_ Module... "
        Install-Module $_ -Force -WarningAction Ignore
        Write-Host -ForegroundColor Green 'installed'
        $_ | Import-AzureModule
     }

    if (!$All) {
        @('AzureRM.Profile'
          'AzureRM.Resources') | Assert-AzureModule
    } else {
        @('AzureRM.Automation'
          'AzureRM.KeyVault'
          'AzureRM.Storage'
          'AzureRM.Tags'
          'Azure.Storage') | Assert-AzureModule
    }
    Write-Host
}