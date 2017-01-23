@{
    AllNodes = @(
        @{
            NodeName = 'Server'
            Octopus = @{
                Role = 'TeamCity Server (Windows)'
                Environment = 'TeamCity Stack'
                Name = 'TeamCity Server'
            }
        }
        @{
            NodeName = 'CloudAgent'
            Octopus = @{
                Role = 'TeamCity Agent Image'
                Environment = 'TeamCity Stack'
                Name = 'TeamCity Server'
            }       
        }
    )
}