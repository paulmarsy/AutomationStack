function Get-AutomationStackConfig {
    [CmdletBinding(DefaultParameterSetName='Key')]
    param(
        [Parameter(Position=1,ParameterSetName='Key',Mandatory)][string]$Key,
        [Parameter(Position=2,ParameterSetName='Key')][switch]$RawValue,
        [Parameter(Position=1,ParameterSetName='Expression',Mandatory)][string]$Expression,
        [Parameter(Position=2,ParameterSetName='Expression')][switch]$IsExpression
    )
    if ($RawValue) { return $CurrentContext.GetRaw($Key) }
    if ($IsExpression) { return $CurrentContext.Eval($Expression) }
    return $CurrentContext.Get($Key)
}