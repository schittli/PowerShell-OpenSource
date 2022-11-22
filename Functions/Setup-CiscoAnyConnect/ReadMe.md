
Pfad: https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell


# Cisco AnyConnect
## Installation der Cisco Standard-Komponenten für die Nosergruppe

Installation starten:
1. PowerShell als Administrator öffnen
2. Ausführen: (mit copy & paste!)
```PowerShell
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb"
```

## Variante mit -WhatIf:
1. PowerShell als Administrator öffnen
2. Ausführen: (mit copy & paste!)
```PowerShell
[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -WhatIf"
```
