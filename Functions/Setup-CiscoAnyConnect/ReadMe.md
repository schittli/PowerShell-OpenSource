
Pfad: https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell


# Cisco AnyConnect
## Automatisierte Installation der Cisco Standard-Komponenten für die Nosergruppe per Kommandozeile

Installation starten:
1. PowerShell als Administrator öffnen
2. Ausführen (mit copy & paste!):

   `[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb"`


#### Variante mit -WhatIf:
1. PowerShell als Administrator öffnen
2. Ausführen (mit copy & paste!):

   `[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -WhatIf"`


### 👉 Manuelle Installation per GUI

Siehe:
[https://github.com/schittli/noser-deploy-CiscoAnyConnectExe
](https://github.com/schittli/noser-deploy-CiscoAnyConnectExe)
