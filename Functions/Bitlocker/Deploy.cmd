@Echo Off
Rem Kopiert die Files zu den Zielen, wo sie benötigt werden:
Rem - \\akros.ch\Ablage\IT-Scripts\AD-Bitlocker
Rem - \\basdc002.akros.ch\FirmaBiel\Infrastruktur\Scripts\BitLocker

SET "ScriptDir=%~dp0"


Rem Die Scripts für die IT
RoboCopy.exe %ScriptDir% "\\akros.ch\Ablage\IT-Scripts\AD-Bitlocker\\" *.cmd *.ps1 *.lnk /COPY:DT /DCOPY:T /XC /XO /R:3

Rem Die Scripts für die User
RoboCopy.exe %ScriptDir% "\\basdc002.akros.ch\FirmaBiel\Infrastruktur\Scripts\BitLocker\\" *.cmd *.ps1 *.lnk /COPY:DT /DCOPY:T /XC /XO /R:3


Pause

