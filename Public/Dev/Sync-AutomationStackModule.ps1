function Sync-AutomationStackModule {
    param($UDP)

    Remove-Module AutomationStack -Force
    if ($null -ne $CurrentContext -and $null -eq $UDP) {
        $UDP  = $CurrentContext.Get('UDP')
    }
    Import-Module (Join-Path $ExecutionContext.SessionState.Module.ModuleBase 'AutomationStack.psd1') -Force -Global -ArgumentList $UDP
}