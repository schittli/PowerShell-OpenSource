@Echo off
:: 190301, tom-agplv3@jig.ch
:: 200731, tom-agplv3@jig.ch
:: 	-ExecutionPolicy Bypass


:: Konfiguration
:: Verbose: 0 oder 1
SET Verbose=0
SET PowerShellVerbose=0
:: Ex: Call :Verbose "Verbose ist aktiv!"

:: WaitOnEnd: 0 oder 1
SET WaitOnEnd=1

SET "ScriptDir=%~dp0"
SET "ScriptFilename=%~n0"
:: SET "PSScript_ps1=%ScriptFilename%.ps1"
SET "PSScript_ps1=Enable-Bitlocker.ps1"
:: Echo %PSScript_ps1%


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
