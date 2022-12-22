@Echo off
:: 190301, tom-agplv3@jig.ch
:: 200731, tom-agplv3@jig.ch
::  -ExecutionPolicy Bypass
:: 003, 221215
::	 - Kopiert bei Bedarf die Files ins C:
::	   Damit elevated Scripts nicht plötzlich 
::	   den Zugriff auf die Quelle im Netzwerk verlieren
:: 004, 221222
::  - Weil das Script im Kontext des Users allenfalls Files kopieren muss,
::  	deshalb darf der User es nicht selber elevated starten
::  	> Bei Elevated einen entsprechenden Hinweis anzeigen
:: 005, 221222
::  - Bug fixes
:: 006, 221222
::  - Für CMD und PS je ein separates Temp-Dir



:: Konfiguration
:: Verbose: 0 oder 1
SET Verbose=0
SET PowerShellVerbose=0
:: Ex: Call :Verbose "Verbose ist aktiv!"

Set Header1=Noser SSF IT, Bitlocker-Verschluesselung
Set Header2=Hinweise bitte an: Thomas.Schittli@akros.ch

:: SET "PSScript_ps1=%ScriptFilename%.ps1"
SET "PSScript_ps1=Enable-Bitlocker.ps1"
:: Echo %PSScript_ps1%

:: WaitOnEnd: 0 oder 1
SET WaitOnEnd=1
:: Wenn definiert, wird das QuellDir ins ZielDir kopiert 
:: und dann von dort ausgeführt
Rem SET CopyToCTempDir=
SET CopyToCTempDir=C:\Temp\IT-Bitlocker-cmd


Rem Optional nur diese Fieltypen kopieren
Rem …Type1…5
Rem OK, kopiert alle:
Rem SET CopyToCTempDirFileType1=
Rem OK, kopiert alle:
Rem SET CopyToCTempDirFileType1=*.*
SET CopyToCTempDirFileType1=*.cmd
SET CopyToCTempDirFileType2=*.ps1
SET CopyToCTempDirFileType3=
SET CopyToCTempDirFileType4=
SET CopyToCTempDirFileType5=

Rem Berechnete Variablen
SET "ScriptDir=%~dp0"
SET "ScriptFilename=%~n0"


Rem Farben
SET ClrReset=[0m

Rem Foreground normal
SET ClrBlackFG=[30m
SET ClrRedFG=[31m
SET ClrGreenFG=[32m
SET ClrYellowFG=[33m
SET ClrBlueFG=[34m
SET ClrMagentaFG=[35m
SET ClrCyanFG=[36m
SET ClrWhiteFG=[37m
Rem Foreground light
SET ClrBlackLghtFG=[90m
SET ClrRedLghtFG=[91m
SET ClrGreenLghtFG=[92m
SET ClrYellowLghtFG=[93m
SET ClrBlueLghtFG=[94m
SET ClrMagentaLghtFG=[95m
SET ClrCyanLghtFG=[96m
SET ClrWhiteLghtFG=[97m

Rem Background normal
SET ClrBlackBG=[40m
SET ClrRedBG=[41m
SET ClrGreenBG=[42m
SET ClrYellowBG=[43m
SET ClrBlueBG=[44m
SET ClrMagentaBG=[45m
SET ClrCyanBG=[46m
SET ClrWhiteBG=[47m
Rem Background light
SET ClrBlackLghtBG=[100m
SET ClrRedLghtBG=[101m
SET ClrGreenLghtBG=[102m
SET ClrYellowLghtBG=[103m
SET ClrBlueLghtBG=[104m
SET ClrMagentaLghtBG=[105m
SET ClrCyanLghtBG=[106m
SET ClrWhiteLghtBG=[107m

Rem Call :DisplayColors


Rem Sind wir bereits elevated?
If Defined SESSIONNAME (
	Call :ShowHeader "%Header1%" "%Header2%"
) Else (
	Echo %ClrReset%
	Echo %Header1%
	Echo %Header2%
	Echo.
	Echo.
	Echo.
	Echo %ClrYellowFG% ****************
	Echo %ClrRedFG%     Wichitg
	Echo %ClrYellowFG% ****************
	Echo.
	Echo %ClrYellowLghtFG% Bitte das Script *nicht* 
	Echo %ClrYellowLghtFG% selber als Administrator / Elevated starten
	Echo %ClrReset%
	Echo.
	Echo  Bitte das Script %ClrCyanFG%nochmals%ClrReset% ganz normal mit einem Doppelklick
	Echo  oder mit 'Ausfuehren' starten
	Echo %ClrReset%
	Echo.
	Echo.
	Echo Weiter mit einer beliebigen Taste
	Pause >nul
	Exit
)



Rem Allenfalls die Quelldateien ins gewünschte lokale Dir kopieren
Rem und dann %ScriptDir% neu setzen
If Not (%CopyToCTempDir%) == () (
	Rem In einem If () Block kann Windows cmd keine Variablen setzen,
	Rem also muss es in einer Funktion gemacht werden
	Rem !M https://stackoverflow.com/questions/42283939/set-variable-inside-if-statement-windows-batch-file
	Call :InitCopy
)


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

Rem Die Begrüssung anzeigen
:ShowHeader
Set Hdr1=%1
Set Hdr2=%2
Rem Remove "
Set Hdr1=%Hdr1:"=%
Set Hdr2=%Hdr2:"=%

	Echo %ClrReset%
	Echo.
	Echo %ClrYellowLghtFG%%Hdr1%
	Echo %ClrYellowLghtFG%%Hdr2%
	Echo %ClrReset%
	Echo.
Exit /b


Rem In einem If () Block kann Windows cmd keine Variablen setzen,
Rem also muss es in einer Funktion gemacht werden
Rem !M https://stackoverflow.com/questions/42283939/set-variable-inside-if-statement-windows-batch-file
:InitCopy
	Rem Trailing Backslash entfernen
	Rem If "%CopyToCTempDir:~-1%" == "\" set "CopyToCTempDir=%CopyToCTempDir:~0,-1%"

	Rem Trailing Backslash zufügen
	Rem !Ex prüfen, ob die Variable überhaupt existiert
	Rem If Defined CopyToCTempDir If Not "%CopyToCTempDir:~-1%"=="\" Set CopyToCTempDir=%CopyToCTempDir%\
	If Not "%CopyToCTempDir:~-1%"=="\" Set CopyToCTempDir=%CopyToCTempDir%\

	Rem Kopieren starten
	Call :StartCopyToCTempDir %ScriptDir% %CopyToCTempDir%
	
	Rem Das ScriptDir ist nun das Arbeitsverzeichnis
	CD %CopyToCTempDir%
	Rem Das ScriptDir ist nun das ZielDir
	Set ScriptDir=%CopyToCTempDir%
	Rem Trailing Backslash zufügen
	If Not "%ScriptDir:~-1%"=="\" Set ScriptDir=%ScriptDir%\
Exit /b


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


:DisplayColors
	Echo %ClrRedFG% Red
	Echo %ClrGreenFG% Green
	Echo %ClrYellowFG% Yellow
	Echo %ClrBlueFG% Blue
	Echo %ClrMagentaFG% Magenta
	Echo %ClrCyanFG% Cyan
	Echo %ClrWhiteFG% White
	Echo.
	Echo %ClrRedLghtFG% Red Light
	Echo %ClrGreenLghtFG% Green Light
	Echo %ClrYellowLghtFG% Yellow Light
	Echo %ClrBlueLghtFG% Blue Light
	Echo %ClrMagentaLghtFG% Magenta Light
	Echo %ClrCyanLghtFG% Cyan Light
	Echo %ClrWhiteLghtFG% White Light
Exit /b



:StartCopyToCTempDir
:: %1: SrcDir
:: %2: ZielDir
Rem Nützt:
Rem %CopyToCTempDirFileType1%
Rem %CopyToCTempDirFileType2%
Rem %CopyToCTempDirFileType3%
Rem %CopyToCTempDirFileType4%
Rem %CopyToCTempDirFileType5%

Rem Ohne Zielverzeichnis sind wir fertig
If (%2) == () Exit /b

Echo Kopiere Files

:: Wenn das ZielDir existiert, dann löschen
If Exist %2 (
	Rem Echo lösche %2
	rmdir /s /q %2
	Rem Zielverzeichnis wird durch xcopy erzeugt
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

Rem Alle Files kopieren?
If (%CopyToCTempDirFileType1%) == () (
	Rem Echo xcopy.exe "%1" "%2" /V /C /I /R /Y /Q /K
	Echo  *.*
	xcopy.exe "%1" "%2" /V /C /I /R /Y /Q /K
	Exit /b
) Else (
	Rem Echo xcopy.exe "%1%CopyToCTempDirFileType1%" "%2" /V /C /I /R /Y /Q /K
	Echo  %CopyToCTempDirFileType1%
	xcopy.exe "%1%CopyToCTempDirFileType1%" "%2" /V /C /I /R /Y /Q /K
)

Rem Sind wir fertig?
If (%CopyToCTempDirFileType2%) == () Exit /b
Echo  %CopyToCTempDirFileType2%
xcopy.exe "%1%CopyToCTempDirFileType2%" "%2" /V /C /I /R /Y /Q /K

Rem Sind wir fertig?
If (%CopyToCTempDirFileType3%) == () Exit /b
Echo  %CopyToCTempDirFileType3%
xcopy.exe "%1%CopyToCTempDirFileType3%" "%2" /V /C /I /R /Y /Q /K

Rem Sind wir fertig?
If (%CopyToCTempDirFileType4%) == () Exit /b
Echo  %CopyToCTempDirFileType4%
xcopy.exe "%1%CopyToCTempDirFileType4%" "%2" /V /C /I /R /Y /Q /K

Rem Sind wir fertig?
If (%CopyToCTempDirFileType5%) == () Exit /b
Echo  %CopyToCTempDirFileType5%
xcopy.exe "%1%CopyToCTempDirFileType5%" "%2" /V /C /I /R /Y /Q /K

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
