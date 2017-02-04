function Get-AutomationStackConfig {
    [CmdletBinding(DefaultParameterSetName='Key')]
    param(
        [Parameter(Position=1,ParameterSetName='Key',Mandatory)][string]$Key,
        [Parameter(Position=2,ParameterSetName='Key')][switch]$RawValue,
        [Parameter(Position=1,ParameterSetName='Expression',Mandatory)][string]$Expression,
        [Parameter(Position=2,ParameterSetName='Expression')][switch]$IsExpression,
        [Alias('Clipboard')][switch]$ToClipBoard
    )
    if ($RawValue) { $value = $CurrentContext.GetRaw($Key) }
    elseif ($IsExpression) { $value = $CurrentContext.Eval($Expression) }
    else { $value = $CurrentContext.Get($Key) }

    if ($ToClipBoard) {
        Write-Host -NoNewLine 'Setting clipboard... '
        Microsoft.PowerShell.Management\Set-Clipboard -Value $value
        Write-Host 'done'
    } else {
        return $value
    }
}