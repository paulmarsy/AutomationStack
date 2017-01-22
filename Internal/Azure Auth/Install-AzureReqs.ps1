function Install-AzureReqs {
    param([switch]$Basic)

    $script:firstInstall = $true
     function Assert-AzureModule {
        param($Module)
        if (Get-Module -ListAvailable -Name $Module) {
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
        Write-Host -NoNewLine "Installing $Module Module... "
        Install-Module $Module -Force  -WarningAction Ignore
        Write-Host -ForegroundColor Green 'imported'
     }

    if ($Basic) {
        Assert-AzureModule -Module 'AzureRM.Profile'

        Write-Host -NoNewLine "Importing AzureRM.Profile Module... "
        Import-Module AzureRM.Profile -Force -Global
        Write-Host -ForegroundColor Green 'imported'
    } else {
        @(  @{ Module = 'AzureRM.Resources'; Provider = 'Microsoft.Resources' },
            @{ Module = 'AzureRM.Automation'; Provider = 'Microsoft.Automation' },
            @{ Module = 'AzureRM.Compute'; Provider = 'Microsoft.Compute' },
            @{ Module = 'AzureRM.KeyVault'; Provider = 'Microsoft.KeyVault' },
            @{ Module = 'AzureRM.Network'; Provider = 'Microsoft.Network' },
            @{ Module = 'AzureRM.Sql'; Provider = 'Microsoft.Sql' },
            @{ Module = @('AzureRM.Storage', 'Azure.Storage'); Provider = 'Microsoft.Storage' }) | % {
            Assert-AzureModule -Module $_.Module
            Write-Host -NoNewLine "Importing $($_.Module) Module... "
            Import-Module $_.Module -Force -Global
            Write-Host -ForegroundColor Green 'imported'

            Write-Host -NoNewLine "Registering $($_.Provider) Resource Provider... "
            Register-AzureRmResourceProvider -ProviderNamespace $_.Provider | Out-Null
            Write-Host -ForegroundColor Green 'registered'
        }
        Write-Host
    }
}