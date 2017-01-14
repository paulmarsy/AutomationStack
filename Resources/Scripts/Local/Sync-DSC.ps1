Remove-DscConfigurationDocument -Stage Pending -Force
Remove-DscConfigurationDocument -Stage Current -Force
Update-DscConfiguration -Wait -Verbose