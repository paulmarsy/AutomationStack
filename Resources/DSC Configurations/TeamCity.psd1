@{
    AllNodes = @(
        @{
            NodeName = 'Server'
            PSDscAllowPlainTextPassword = $true
            Octopus = @{
                Role = 'TeamCity Server (Windows)'
                Environment = 'TeamCity Stack'
                Name = 'TeamCity Server'
            }
        }
        @{
            NodeName = 'CloudAgent'
            PSDscAllowPlainTextPassword = $true
            Octopus = @{
                Role = 'TeamCity Cloud Agent'
                Environment = 'TeamCity Stack'
                Name = 'TeamCity Cloud Agent'
            }       
        }
    )
}