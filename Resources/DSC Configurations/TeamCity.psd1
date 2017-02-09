@{
    AllNodes = @(
        @{
            NodeName = 'Server'
            PSDscAllowPlainTextPassword = $true
            Octopus = @{
                Role = 'TeamCity Server (Windows)'
                Environment = 'Automation Stack'
                Name = 'TeamCity Server'
            }
        }
        @{
            NodeName = 'CloudAgent'
            PSDscAllowPlainTextPassword = $true
            Octopus = @{
                Role = 'TeamCity Cloud Agent'
                Environment = 'Agent Cloud'
                Name = 'TeamCity Cloud Agent'
            }       
        }
    )
}