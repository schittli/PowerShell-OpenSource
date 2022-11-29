@Echo Off
Rem Aktualsiert Cisco AnyConnect
Rem holt die MSI von:
Rem https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Bin/
Rem 221123, Tom

Rem Mit Debug Infos
Rem powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -Command CD 'C:\Temp'; Write-Host "";$CommandLineArgs = [System.Environment]::GetCommandLineArgs();Write-Host "";Write-Host 'GetCommandLineArgs() -join:' -ForegroundColor Yellow;Write-Host ($CommandLineArgs -join ' ') ;Write-Host "";[Net.ServicePointManager]::SecurityProtocol = """Tls12"""; Invoke-Expression """ &{ $(Invoke-RestMethod -DisableKeepAlive -Uri 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -ShowDebugInfos"""

powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -Command CD 'C:\Temp'; Write-Host "";[Net.ServicePointManager]::SecurityProtocol = """Tls12"""; Invoke-Expression """ &{ $(Invoke-RestMethod -DisableKeepAlive -Uri 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -ShowDebugInfos"""

