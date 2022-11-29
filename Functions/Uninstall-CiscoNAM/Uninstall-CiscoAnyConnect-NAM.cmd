@Echo Off
Rem Deinstalliert das Cisco AnyConnect NAM-Modul
Rem 221123, Tom

Rem mit Debug-Infos:
Rem powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -Command CD 'C:\Temp'; Write-Host "";$CommandLineArgs = [System.Environment]::GetCommandLineArgs();Write-Host "";Write-Host 'GetCommandLineArgs() -join:' -ForegroundColor Yellow;Write-Host ($CommandLineArgs -join ' ') ;Write-Host "";[Net.ServicePointManager]::SecurityProtocol = """Tls12"""; Invoke-Expression """ &{ $(Invoke-RestMethod -DisableKeepAlive -Uri 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Uninstall-CiscoNAM/Uninstall-CiscoNAM.ps1') } """

powershell.exe -NoProfile -ExecutionPolicy Bypass -NoExit -Command CD 'C:\Temp'; Write-Host "";[Net.ServicePointManager]::SecurityProtocol = """Tls12"""; Invoke-Expression """ &{ $(Invoke-RestMethod -DisableKeepAlive -Uri 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Uninstall-CiscoNAM/Uninstall-CiscoNAM.ps1') } """




