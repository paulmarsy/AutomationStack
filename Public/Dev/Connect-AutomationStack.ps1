function Connect-AutomationStack {
    param(
        [ValidateSet('Octopus','TeamCity')]$VM
    )

    switch ($VM) {
        'Octopus' { $rg = $CurrentContext.Get('OctopusRg'); $ipName = 'OctopusPublicIP'; $nsg = 'OctopusNSG' }
        'TeamCity' { $rg = ('TeamCityStack{0}' -f $CurrentContext.Get('UDP')); $ipName = 'TeamCityPublicIP'; $nsg = 'TeamCityNSG' }
        default { throw 'You must specify the service to RDP to' }
    }
    Write-Host -NoNewLine "Updating $nsg network security group... "
    Invoke-SharedScript Network 'Enable-RDPNSGRule' -InfraRg $CurrentContext.Get('InfraRg') -NSGName $nsg | Out-Null
    Write-Host 'RDP rule enabled, it may take a few seconds to propogate'

    Write-Host -NoNewLine "Finding $ipName address... "
    $ip = (Get-AzureRmPublicIpAddress -Name $ipName -ResourceGroupName $rg).IpAddress
    Write-Host "got $ip"

    Write-Host "Setting credentials & connecting..."
    Start-Process -FilePath "cmdkey.exe" -ArgumentList @("/generic:`"TERMSRV/$ip`"", "/user:`"$($CurrentContext.Get('StackAdminUsername'))`"", "/pass:`"$($CurrentContext.Get('StackAdminPassword'))`"") -WindowStyle Hidden -Wait

    $arguments = @(
        "/v:`"$($ip)`""
        "/w:1440"
        "/h:900"
    )
    Start-Job -ScriptBlock {
        param($arguments, $ip)
        Start-Process -FilePath "mstsc.exe" -ArgumentList $arguments -Wait
        Start-Process -FilePath "cmdkey.exe" -ArgumentList @("/delete:`"TERMSRV/$ip`"") -WindowStyle Hidden -Wait
    } -ArgumentList @($arguments, $ip) | Out-Null
}