function Write-ResolvedException {
    param($Exception)

    $message = $Exception.Exception.Message
    $errorId = $Exception.FullyQualifiedErrorId
    $scriptStackTrace = $Exception.ScriptStackTrace
    $positionMessage = $Exception.InvocationInfo.PositionMessage

    if ($message -and $errorId -and $scriptStackTrace -and $positionMessage) {
        Write-Host
        Write-Host
        Write-Warning "Exception: $message"
        Write-Warning "ErrorId: $errorId"
        Write-Host
        Write-Warning "Stack Trace:`n$scriptStackTrace"
        Write-Host
        Write-Warning "Position Message:`n$positionMessage"

        $true
    } else {
        $false
    }
}