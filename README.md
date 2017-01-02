# Automation Stack
DevOps Automation Sandbox

## Build The Environment

```PowerShell
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/paulmarsy/AutomationStack/master/bootstrap.ps1') | iex
```

### Cleanup an unwanted deployment

```PowerShell
.\AutomationStack\Utils\Cleanup.ps1 <UDP>
```

#### Example

1. One of the first messages is as follows, if you don't see this then the only thing to cleanup is the `AutomationStack` folder in the current directory.
  <pre>
  ****************************************
  AutomationStack Deployment Details
  Unique Deployment Prefix:  7d18
  Admin Username:  Stack
  Admin Password:  a65d6673DCCF
  ****************************************
  </pre>

2. In this example to cleanup any Azure resources created you would issue
  ```PowerShell
  & .\AutomationStack\Utils\Cleanup.ps1 7d18
  ```
  
3. After this the only remnanents are
  * The `AutomationStack` folder in the current directory 
  * A few files in the `$Env:TEMP` directory which can be cleaned up in the normal way
  * The Azure PowerShell Cmdlets if they weren't previously installed, they can be removed with the command

  ```PowerShell
  Get-InstalledModule -Name Azure* | Uninstall-Module
  ```