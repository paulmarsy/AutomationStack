function Get-AutomationStackConfig {
    [CmdletBinding(DefaultParameterSetName='Key')]
    param(
        [Parameter(Position=1,ParameterSetName='Key',Mandatory)][string]$Key,
        [Parameter(Position=2)][Alias('Clipboard')][switch]$ToClipBoard,
        [Parameter(Position=3,ParameterSetName='Key')][switch]$RawValue,
        [Parameter(Position=1,ParameterSetName='Expression',Mandatory)][string]$Expression,
        [Parameter(Position=3,ParameterSetName='Expression')][switch]$IsExpression
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