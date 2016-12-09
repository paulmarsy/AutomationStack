# Automation Stack
Showcasing the power of DevOps automation.

```
(new-object Net.WebClient).DownloadString('https://raw.githubusercontent.com/paulmarsy/AutomationStack/master/bootstrap.ps1') | iex
```

## What
* One PowerShell command that anyone can copy & paste.
* Fully automates the provisioning, deployment and configuration of an idealised DevOps build & deploy infrastructure
* Leaves you with a usable sandbox environment, and the ability to automate the tearing down and clean up of any resources used.

## How
* All scripts, code or config must come from this repository
* It should be clear what is happening, and for the process to be as transparent and easy to follow as is possible
* The only user interaction that is permitted is the first command that is run, after that everything is automated the only exception is for passwords or other senstivie config and this must be collected within the first few seconds.

## Using
* Windows PowerShell 5 (bootstrap script)
* Infrastructure
  * Microsoft Azure - ARM Templates
  * Windows Server 2016
* Build
  * TeamCity
* Package Repository
  * ProGet
* Deploy
  * Octopus Deploy
