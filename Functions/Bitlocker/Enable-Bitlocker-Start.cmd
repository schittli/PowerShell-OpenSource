@Echo off
:: 190301, tom-agplv3@jig.ch
:: 200731, tom-agplv3@jig.ch
:: 	-ExecutionPolicy Bypass
:: 003, 221215

::		- Kopiert bei Bedarf die Files ins C:
::		- Kommt klar, wenn der User das Script als Admin startet
::		  >> Muss das Script stoppen und den User auffordern, es normal zu starten!
::		  >> Wegen Admin Share-Zugriffen, die allenfalls fehlen





:: Konfiguration
:: Verbose: 0 oder 1
SET Verbose=0
SET PowerShellVerbose=0
:: Ex: Call :Verbose "Verbose ist aktiv!"


:: WaitOnEnd: 0 oder 1
SET WaitOnEnd=1
:: Wenn definiert, wird das QuellDir ins ZielDir kopiert 
:: und dann von dort ausgeführt
Rem SET "CopyToCTempDir= "
SET "CopyToCTempDir=C:\Temp\IT-Bitlocker"
Rem Type1…5
SET CopyToCTempDirFileType1=*.cmd
SET CopyToCTempDirFileType2=*.ps1
SET CopyToCTempDirFileType3=
SET CopyToCTempDirFileType4=
SET CopyToCTempDirFileType5=


SET "ScriptDir=%~dp0"
SET "ScriptFilename=%~n0"
:: SET "PSScript_ps1=%ScriptFilename%.ps1"
SET "PSScript_ps1=Enable-Bitlocker.ps1"
:: Echo %PSScript_ps1%

Call :StartCopyToCTempDir %ScriptDir% %CopyToCTempDir%
Echo tomtom
Pause


:: Argumente, die dem PowerShell-Script mitgegeben werden
SET "PSScript_Args="

Call :Verbose "Starte: %PSScript_ps1%"
Call :Verbose "Args: %PSScript_Args%"

If Exist "%PSScript_ps1%" (
	Rem SET "PSScript=%ScriptDir%%PSScript_ps1%"
	Call :Verbose "PS1-Datei: gefunden"
	Call :StartPS "%PSScript_ps1%"
	Exit /b
) Else (
	Call :Verbose "PS1-Datei: nicht gefunden"
)


If (%WaitOnEnd%) == (1) (
	Goto :Pause
) Else (
	Goto :Ende
)


:: =========================================================================

:StartPS
:: Startet eine ps1 - Datei
Rem Umgebende " entfernen
SET ScriptName=%~1
If (%Verbose%) == (1) (
	Echo Starte:
	Echo "%ScriptDir%%ScriptName%"
	Echo Args:
	Echo "%PSScript_Args%"
	Echo.
)

If (%PowerShellVerbose%) == (0) (
	PowerShell -ExecutionPolicy Bypass ". '%ScriptDir%%ScriptName%' %PSScript_Args%"
) Else (
	PowerShell -ExecutionPolicy Bypass ". '%ScriptDir%%ScriptName%' %PSScript_Args% -Verbose"
)
Exit /b




:StartCopyToCTempDir
:: %1: SrcDir
:: %2: ZielDir
:: Abbruch, wenn %2 leer ist
Echo Start
Echo CopyToCTempDirFileType1: %CopyToCTempDirFileType1%
Echo %1
Echo %2
If (%2) == () Exit /b
Echo Nicht Leer

:: Wenn das ZielDir existiert, dann löschen
If Exist %2 (
	Rem Echo lösche %2
	rmdir /s /q %2
	Rem Echo erzeuge %2
	Rem mkdir %2
)

Rem !M https://learn.microsoft.com/de-de/windows-server/administration/windows-commands/xcopy
Rem
Rem /z	Nach einem Verbindung das Kopieren fortsetzen
Rem		zeigt % des Kopiervorgangs für jede Datei an
Rem /i	Ziel ist ein Verzeichnis
Rem /c	Ignoriert Fehler
Rem /v	Verify
Rem /q	Unterdrückt die Anzeige von xcopy Nachrichten
Rem /f	Zeigt Quell- und Zieldateinamen beim Kopieren an
Rem /s	Inkl. Subdirs
Rem /e	Kopiert auch leere Subdirs	
Rem /r	Kopiert schreibgeschützte Dateien
Rem /k	Entfernt das Attribut 'Schreibgeschützt'
Rem /y	Automatisch Files überschreiben
Rem /z	Kopiert über ein Netzwerk im neustartbaren Modus
Rem		Nützlich für grosse Dateien

Echo xcopy.exe %1 %2 /V /C /I /R /Y /Q /K
xcopy.exe %1 %2 /V /C /I /R /Y /Q /K
Echo abc
Pause
Exit /b


:Verbose
:: Wenn die Variable Verbose definiert ist, wird %1 ausgegeben
Rem Umgebende " entfernen
SET Message=%~1
Rem Doppelte " entfernen
SET Message=%Message:"=%
If (%Verbose%) == (1) Echo %Message%
Exit /b


:Pause
Echo.
Pause

:Ende
