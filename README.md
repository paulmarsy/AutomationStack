# Automation Stack
A DevOps Automation Sandbox

## Build The Environment
Open *PowerShell* and run the following command
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

Other functionality such as _Create TeamCity Agent Cloud Image_ are made available by Octopus Deploy projects that are imported during it's provisioning process.

### Removal & Cleanup
The following command will clean up all Azure resources created during the initial provisioning and any created by Octopus Deploy projects
```PowerShell
Remove-AutomationStack
```
After this the only remnanents are
  * The `AutomationStack` folder in the current directory 
  * The Azure PowerShell Cmdlets if they weren't previously installed, they can be removed with the command

  ```PowerShell
  Get-InstalledModule -Name Azure* | Uninstall-Module
  ```
