function Sync-AutomationStackModule {
    param([string]$UDP)

    Remove-Module AutomationStack -Force -ErrorAction Continue
    if ($null -ne $CurrentContext -and [string]::IsNullOrWhiteSpace($UDP)) {
        $UDP  = $CurrentContext.Get('UDP')
    }
    Import-Module (Join-Path $ExecutionContext.SessionState.Module.ModuleBase 'AutomationStack.psd1') -Force -Global -ArgumentList $UDP
}