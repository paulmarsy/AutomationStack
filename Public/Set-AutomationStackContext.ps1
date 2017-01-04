function Set-AutomationStackContext {
    param(
        [Parameter(Mandatory=$true)]$UDP
    )
    $script:CurrentContext  = Get-OctospracheState -UDP $UDP
}