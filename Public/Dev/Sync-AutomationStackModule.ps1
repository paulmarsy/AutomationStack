function Sync-AutomationStackModule {
    Remove-Module AutomationStack -Force
    if ($null -ne $CurrentContext) {
        Import-Module (Join-Path $ExecutionContext.SessionState.Module.ModuleBase 'AutomationStack.psd1') -Force -Global -ArgumentList $CurrentContext.Get('UDP')
    } else {
        Import-Module (Join-Path $ExecutionContext.SessionState.Module.ModuleBase 'AutomationStack.psd1') -Force -Global
    }
}