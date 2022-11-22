

# Uninstall-CiscoNAM.ps1

Prüft, ob das Cisco AnyConnect Modul Network Access Manager (NAM) installiert ist.

Wenn ja:
- Es wird versucht, das Modul automatisch zu deinstallieren. 
  Das klappt nicht immer, weil Cisco oft schlampig arbeitet und häufig keinen ordentlichen Uninstaller mitgibt
- Wenn die automatische Deinstallation nicht klappte, 
  - dann wird das Windows Uninstall-Controlpanel gestartet 
  - und der User gebeten, es von Hand zu deinstallieren


