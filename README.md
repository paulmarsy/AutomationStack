# Automation Stack
DevOps Automation Sandbox

## Build The Environment

```PowerShell
irm https://git.io/automationstack | iex
```

_If you have downloaded the repository independently the environment can be built with_
```PowerShell
Import-Module .\AutomationStack.psd1
New-AutomationStack
```

### Provisioning TeamCity and enabling additional functionality
Deploy the _Provision TeamCity (Windows)_ or _Provision TeamCity (Linux)_ project from Octopus
Other functionality such as _Create TeamCity Agent Cloud Image_ 
### Removal & Cleanup
The following command will clean up all Azure resources created during the initial provisioning and any created by Octopus Deploy projects
```PowerShell
Remove-AutomationStack
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
  Remove-AutomationStack
  ```
  
3. After this the only remnanents are
  * The `AutomationStack` folder in the current directory 
  * The Azure PowerShell Cmdlets if they weren't previously installed, they can be removed with the command

  ```PowerShell
  Get-InstalledModule -Name Azure* | Uninstall-Module
  ```
