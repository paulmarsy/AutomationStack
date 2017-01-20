function Test-ExceptionComplete {
    param($Exception)

    $message = $Exception.ErrorRecord.Exception.Message
    $errorId = $Exception.ErrorRecord.FullyQualifiedErrorId
    $scriptStackTrace = $Exception.ErrorRecord.ScriptStackTrace
    $commandName = $Exception.ErrorRecord.InvocationInfo.MyCommand.Name
    $positionMessage = $Exception.ErrorRecord.InvocationInfo.PositionMessage

    if ($message -and $errorId -and $scriptStackTrace -and $commandName -and $positionMessage) {
        Write-Warning "Exception:" 
        Write-Warning $message
        Write-Warning "ErrorId: $errorId"
        Write-Warning "Stack Trace:`n$scriptStackTrace"
        Write-Warning "Command: $commandName"
        Write-Warning "Position:`n$positionMessage"

        $true
    } else {
        $false
    }
}