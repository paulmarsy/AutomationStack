$octopusServiceAccount = Get-AutomationPSCredential -Name 'OctopusDeployServiceAccount'
$octopusServiceAccountUsername = $octopusServiceAccount.UserName
User OctopusServiceAccount
{
    UserName                = $octopusServiceAccountUsername
    Password                = $octopusServiceAccount
    PasswordChangeRequired  = $false
    PasswordNeverExpires    = $true
}
Script SetOctopusUserGroups
{
    SetScript = {
        $user = Get-LocalUser -Name $using:octopusServiceAccountUsername
        try { Add-LocalGroupMember -Name Users -Member $user -ErrorAction Stop } catch [Microsoft.PowerShell.Commands.MemberExistsException] {}
        try { Add-LocalGroupMember -Name Administrators -Member $user -ErrorAction Stop } catch [Microsoft.PowerShell.Commands.MemberExistsException] {}
    }
    TestScript = {
        $user = Get-LocalUser -Name $using:octopusServiceAccountUsername
        (($null -ne (Get-LocalGroupMember -Name Users -Member $user -ErrorAction Ignore)) -and ($null -ne (Get-LocalGroupMember -Name Administrators -Member $user -ErrorAction Ignore)))
    }
    GetScript = { @{} }
    DependsOn = '[User]OctopusServiceAccount'
}