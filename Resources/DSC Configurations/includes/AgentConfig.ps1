        PSModule MyPSModule
        {
            Ensure            = "present" 
            Name              = $Name
            RequiredVersion   = "0.2.16.3"  
            Repository        = "PSGallery"
            InstallationPolicy="trusted"     
        }                               