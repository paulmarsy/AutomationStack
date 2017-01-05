# Automation Stack
DevOps Automation Sandbox

## Build The Environment

```PowerShell
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/paulmarsy/AutomationStack/master/bootstrap.ps1') | iex
```

_If you have downloaded the repository independently the process can be started with_
```PowerShell
Import-Module .\AutomationStack.psd1
New-AutomationStack [-AzureRegion 'North Europe']
```

### Creating a TeamCity Deployment
Deploy the _Provision TeamCity (Windows)_ project in Octopus, or after the environment has been provisioned use the followup command
```PowerShell
New-TeamCityStack
```
### Cleanup an unwanted deployment
```PowerShell
Remove-AutomationStack <UDP>
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
  Remove-AutomationStack 7d18
  ```
  
3. After this the only remnanents are
  * The `AutomationStack` folder in the current directory 
  * The Azure PowerShell Cmdlets if they weren't previously installed, they can be removed with the command

  ```PowerShell
  Get-InstalledModule -Name Azure* | Uninstall-Module
  ```