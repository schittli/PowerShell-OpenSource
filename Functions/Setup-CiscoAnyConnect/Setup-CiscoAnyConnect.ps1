# Installiert von Cisco AnyConnect die Standards-Komponenten
# für Geräte der Nosergruppe (Siehe: $NosergroupDefaultModules)
#
# Bei Bedarf ist das Script vorbereitet, um gezielt einzelne Module zu installieren
# (nicht getestet)
#
# Getting started:
# https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/ReadMe.html
#
#
# Siehe auch:
#	\\akros.ch\SysVol\akros.ch\Policies\{EDD17C50-96F6-49C3-A8AC-A499448DFD51}\User\Scripts\Logon\Update-CiscoAnyConnect.cmd
#
#
# !Ex
# 	# 1. PowerShell öffnen (wechselt selber in den elevated Mode)
# 	# 2. Ausführen: (mit copy & paste!)
#		[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm -DisableKeepAlive 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb"
#
# 	# Variante mit -ShowDebugInfos:
#		[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm -DisableKeepAlive 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -ShowDebugInfos"
#
# 	# Variante mit -WhatIf:
#		[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm -DisableKeepAlive 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -WhatIf"
#
#
# 001, 221109, Tom
# 002, 221109
# 003, 221122
#	Neu: -BinDlUrl
# 004, 221123
#	Neu: Das Script sucht automatisch die Cisco Setup Files, ohne Angabe der Versionsnummer
# 005, 221123
#	Autostart Shell elevated
# 006, 221123
# 	Es wird nur aktualisiert, wenn die installierte Version veraltet ist oder fehlt

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'SetupDefaultModules')]
Param(
	[Parameter(ParameterSetName = 'SetupDefaultModules')]
	[Switch]$InstallNosergroupDefaultModules,
	[Parameter(ParameterSetName = 'SetupIndividualModules')]
	[ValidateSet(IgnoreCase, 'VPN', 'SBL', 'DART', 'NAM', 'Umbrella', 'Posture', 'ISEPosture', 'AMPEnabler', 'NVM')]
	[String[]]$CiscoModules,
	# Wenn -InstallFromWeb nicht angegeben wird:
	# Setup der msi vom <ScriptDir>\Bin
	[Switch]$InstallFromWeb,
	# Die Url zum Bin-Verzeichnis mit den Msi Files
	[String]$BinDlUrl = 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Bin',
	# Die elevated Shell nicht schliessen & Debug-Infos anzeigen
	[Switch]$ShowDebugInfos
)


## Pre-Conditions
# !Sj Autostart Shell elevated
If ($PSVersionTable.PSVersion.Major -gt 5) {
	Write-Host "`nDieses Script muss in PowerShell 5 gestartet werden" -ForegroundColor Red
	Start-Sleep -Milliseconds 2500
	Write-Host -NoNewLine "`nPress any key to continue…" -ForegroundColor Green
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	Return
}



## Config

# Perma Link zum eigenen Script
# !Sj Autostart Shell elevated
$ThisScriptPermaLink = 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1'


$Version = '1.0, 22.11.22'
$Feedback = 'bitte an: schittli@akros.ch'

$CiscoSetupFileTypes = @('.msi$')

# Die Standardmodule, die in der Nosergruppe installiert werden
$NosergroupDefaultModules = @('VPN', 'AMPEnabler', 'Umbrella', 'ISEPosture', 'DART')

If ($MyInvocation.MyCommand.Path -eq $null) {
	$ScriptDir = Get-Location
} Else {
	$ScriptDir = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}


# Liste der Cisco-Module
Enum eCiscoModule {
	VPN 			# AnyConnect VPN
	SBL			# Start Before Login
	DART			# Diagnostic And Reporting Tool
	NAM			# Network Access Manager
	Umbrella		# Umbrella Roaming Security
	Posture		# AnyConnect Posture
	ISEPosture	# AnyConnect ISE Posture
	AMPEnabler	# AMP Enabler Module
	NVM			# Network Visibility Module
}


# !KH9 MSI Kommandozeilen-Parameter
# 		Siehe im setup.hta » Sub InstallXXX Methoden
# Nicht übernommen wurden:
# - LogFile
# - LockDown

# Common Msi Args
# !M9 https://www.exemsi.com/documentation/msiexec-parameters/
# /lvx*
# /l is log
# /v is verbose
# /x is extra debugging info
# * is everything else

$SetupCfg = @{
	[eCiscoModule]::VPN = @{
		Name = 'AnyConnect VPN'
		MsiName = 'core-vpn-predeploy-k9'
		MsiParams = '/norestart /passive PRE_DEPLOY_DISABLE_VPN=0'
	}
	[eCiscoModule]::SBL = @{
		Name = 'Start Before Login'
		MsiName = 'gina-predeploy-k9'
		MsiParams = '/norestart /passive'
	}
	[eCiscoModule]::DART = @{
		Name = 'Diagnostic And Reporting Tool'
		MsiName = 'dart-predeploy-k9'
		MsiParams = '/norestart /passive'
	}
	[eCiscoModule]::NAM = @{
		Name = 'Network Access Manager'
		MsiName = 'nam-predeploy-k9'
		MsiParams = '/norestart /passive'
	}
	[eCiscoModule]::Umbrella = @{
		Name = 'Umbrella Roaming Security'
		MsiName = 'umbrella-predeploy-k9'
		MsiParams = '/norestart /passive'
	}
	[eCiscoModule]::Posture = @{
		Name = 'AnyConnect Posture'
		MsiName = 'posture-predeploy-k9'
		MsiParams = '/norestart /passive'
	}
	[eCiscoModule]::ISEPosture = @{
		Name = 'AnyConnect ISE Posture'
		MsiName = 'iseposture-predeploy-k9'
		MsiParams = '/norestart /passive'
	}
	[eCiscoModule]::AMPEnabler = @{
		Name = 'AMP Enabler Module'
		MsiName = 'amp-predeploy-k9'
		MsiParams = '/norestart /passive'
	}
	[eCiscoModule]::NVM = @{
		Name = 'Network Visibility Module'
		MsiName = 'nvm-predeploy-k9'
		MsiParams = '/norestart /passive'
	}
}


#Region Toms Tools: Log

# Log
# Prüft, ob $Script:LogColors definiert ist und nützt dann dieses zur Farbgebung
# $Script:LogColors =@('Cyan', 'Yellow')
#
# 0: Thema - 1: Kapitel - 2: OK - 3: Error
# 200604 175016
# 200805 103305
#  Neu: Optional BackgroundColor
# 211129 110213
#  Fix -ClrToEol zusammen mit -ReplaceLine
# 220926 152200
#  Neu: [Switch]IfVerbose
#	Wir dur ausgegeben, wenn Verbose aktiv ist
#  Fix bei NewLineBefore
# 221116 191858
#  Wenn Get-Host keine echte Console hat (und z.B. BackgroundColor $null ist)
#  dann arbeiten wir mit default Werten
$Script:LogColors = @('Green', 'Yellow', 'Cyan', 'Red')
Function Log() {
   [CmdletBinding(SupportsShouldProcess)]
   Param (
      [Parameter(Position = 0)]
      [Int]$Indent,

      [Parameter(Position = 1)]
      [String]$Message = '',

      [Parameter(Position = 2)]
      [ConsoleColor]$ForegroundColor,

      # Vor der Nachricht eine Leerzeile
      [Parameter(Position = 3)]
      [Switch]$NewLineBefore,

      # True: Die aktuelle Zeile wird gelöscht und neu geschrieben
      [Parameter(Position = 4)]
      [Switch]$ReplaceLine = $false,

      # True: Am eine keinen Zeilenumbruch
      [Parameter(Position = 5)]
      [Switch]$NoNewline = $false,

      # Append, also kein Präfix mit Ident
      [Parameter(Position = 6)]
      [Switch]$Append = $false,

      # Löscht die Zeile bis zum Zeilenende
      [Parameter(Position = 7)]
      [Switch]$ClrToEol = $false,

      # Ausgabe erfolgt nur, wenn Verbose aktiv ist
      [Switch]$IfVerbose,

      [Parameter(Position = 8)]
      [ConsoleColor]$BackgroundColor
   )

   # Irgend ein fix / workaround
   $PSBoundParametersCopy = $PSBoundParameters

   If ($Script:LogDisabled -eq $true) { Return }

   # Wenn Verbose gewünscht aber nicht aktiv, dann sind wir fertig
   If ($IfVerbose -and (Is-Verbose) -eq $False) {
      Return
   }

   ## Init der Get-Host Config Daten
   # $Script:LogDefaultBackgroundColor
   If ($null -eq $Script:LogDefaultBackgroundColor) {
      If ($null -eq (Get-Host).UI.RawUI.BackgroundColor) {
         $Script:LogDefaultBackgroundColor = [ConsoleColor]::Black
      } Else {
         $Script:LogDefaultBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor
      }
   }
   # $Script:LogMaxWindowSizeWidth
   If ($null -eq $Script:LogMaxWindowSizeWidth) {
      If ($null -eq (Get-Host).UI.RawUI.MaxWindowSize) {
         $Script:LogMaxWindowSizeWidth = 132
      } Else {
         $Script:LogMaxWindowSizeWidth = (Get-Host).UI.RawUI.BackgroundColor
      }
   }

   If ($NewLineBefore) { Write-Host '' }
   If ([String]::IsNullOrEmpty($Message)) { $Message = '' }

   If ($Indent -eq $null) { $Indent = 0 }
   If ($null -eq $BackgroundColor) { $BackgroundColor = $Script:LogDefaultBackgroundColor }

   If ($ReplaceLine) { $Message = "`r$Message" }

   $WriteHostArgs = @{ }
   If ($null -eq $ForegroundColor) {
      If ($null -ne $Script:LogColors -and $Indent -le $Script:LogColors.Count -and $Script:LogColors[$Indent] -ne $null) {
         Try {
            $ForegroundColor = $Script:LogColors[$Indent]
         }
         Catch {
            Write-Host "Ungueltige Farbe: $($Script:LogColors[$Indent])" -ForegroundColor Red
         }
      }
      If ($null -eq $ForegroundColor) {
         $ForegroundColor = [ConsoleColor]::White
      }
   }
   If ($ForegroundColor) {
      $WriteHostArgs += @{ ForegroundColor = $ForegroundColor }
   }
   $WriteHostArgs += @{ BackgroundColor = $BackgroundColor }

   If ($NoNewline) {
      $WriteHostArgs += @{ NoNewline = $true }
   }

   If ($Append) {
      $Msg = $Message
      If ($ClrToEol) {
         $Width = $Script:LogMaxWindowSizeWidth
         If ($Msg.Length -lt $Width) {
            $Spaces = $Width - $Msg.Length
            $Msg = "$Msg$(' ' * $Spaces)"
         }
      }
   }
   Else {
      Switch ($Indent) {
         0 {
            $Msg = "* $Message"
            If ($NoNewline -and $ClrToEol) {
               $Width = $Script:LogMaxWindowSizeWidth
               If ($Msg.Length -lt $Width) {
                  $Spaces = $Width - $Msg.Length
                  $Msg = "$Msg$(' ' * $Spaces)"
               }
            }
            If (!($ReplaceLine)) {
               $Msg = "`n$Msg"
            }
         }
         Default {
            $Msg = $(' ' * ($Indent * 2) + $Message)
            If ($NoNewline -and $ClrToEol) {
               # Rest der Zeile mit Leerzeichen überschreiben
               $Width = $Script:LogMaxWindowSizeWidth
               If ($Msg.Length -lt $Width) {
                  $Spaces = $Width - $Msg.Length
                  $Msg = "$Msg$(' ' * $Spaces)"
               }
            }
         }
      }
   }

   Write-Host $Msg @WriteHostArgs

   # if (!([String]::IsNullOrEmpty($LogFile))) {
   # 	"$([DateTime]::Now.ToShortDateString()) $([DateTime]::Now.ToLongTimeString())   $Message" | Out-File $LogFile -Append
   # }
}

#Endregion Toms Tools: Log



Function Get-TempDir() {
	New-TemporaryFile | %{ rm $_ -Force -WhatIf:$False; mkdir $_ -WhatIf:$False }
}

# Erzeugt aus einem String[] eine Liste von PSCustomObject
# Debugged: OK
Function Array-ToObj() {
   [CmdletBinding()]
   Param(
      [String[]]$Items
   )
   Begin {}
   Process {
      ForEach ($Item in $Items) {
         [PSCustomObject][Ordered]@{
            Item = $Item
         }
      }
   }

   End {}
}


# Verbinded zwei URLs
#
# Wenn $Append = $True, dann wird $Realtive dem ganzen Root-Pfad zugefügt
# Sonst wird Relative nur dem Host zugefügt
Function Join-URL ($Root, $Relative, [Switch]$Append = $True) {
	# Sicherstellen, dass am Ende kein Slash existiert
	$Root = $Root.TrimEnd('/').TrimEnd('\')
	# Wenn $Relative zum ganzen Root-Pfad zugefügt werden muss, benoetigt Root ein Slash
	If ($Append) { $Root = $Root + '/' }
	# https://msdn.microsoft.com/en-us/library/system.uri(v=vs.110).aspx
	$RootUri = New-Object System.Uri($Root)
	(New-Object System.Uri($RootUri, $Relative)).AbsoluteUri
}


Function Is-WhatIf() {
	$WhatIfPreference
}


# Extrahiert aus dem Cisco zip / exe Dateinamen die Versions-Information
#
# !Ex
# 	Get-CiscoSetupFilename-VersionInfo 'anyconnect-win-4.10.05111-predeploy-k9 - Noser Setup.exe'
# 	Get-CiscoSetupFilename-VersionInfo 'anyconnect-win-4.10.05111-predeploy-k9 - Original Cisco.zip'
Function Get-CiscoSetupFilename-VersionInfo($CiscoSetupFilename) {
	If ($CiscoSetupFilename -match '(?<Version>(\d+\.){0,3}(\d+))') {
		Return [Version]$Matches.Version
	}
}


# Liest von einer Webseite die Liste der Files,
# die zu einem Filetyp passen
Function Get-Web-Filelisting() {
	Param(
		[Parameter(Mandatory)][String]$Url,
		# e.g. @('.msi$', '.zip$')
		[Parameter(Mandatory)][String[]]$FileTypes
	)

	$Files = Invoke-WebRequest $Url -UseBasicParsing
	If ($Files) {
		$Res = @()
		ForEach ($Link in $Files.Links) {
			If ($Link.href -Match ($FileTypes -join '|')) {
				$Res += [PSCustomObject][Ordered] @{
					FullName = (Join-URL $Url $Link.href)
					Filename = $Link.href
					# Versuchen, die Versionsinfo zu bestimmen
					oCiscoVersion = (Get-CiscoSetupFilename-VersionInfo $Link.href)
				}
			}
		}
		Return $Res
	}
}


# Liest von der lokalen Dir die Liste der Files,
# die zu einem Filetyp passen
Function Get-Filelisting() {
	Param(
		[Parameter(Mandatory)][String]$LocalDir,
		# e.g. @('.msi$', '.zip$')
		[Parameter(Mandatory)][String[]]$FileTypes
	)

	$Files = Get-ChildItem -LiteralPath $LocalDir
	If ($Files) {
		$Res = @()
		ForEach ($File in $Files) {
			If ($File.Name -Match ($FileTypes -join '|')) {
				$Res += [PSCustomObject][Ordered] @{
					FullName = $File.FullName
					Filename = $File.Name
					# Versuchen, die Versionsinfo zu bestimmen
					oCiscoVersion = (Get-CiscoSetupFilename-VersionInfo $File.Name)
				}
			}
		}
		Return $Res
	}
}


# Liest von einem Webverzeichnis wie
# 	https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Bin/
# alle Files und extrahiert die Cisco-Version
#
# !Ex
# 	$CiscoVersions, $Files = Get-Webfiles-CiscoVersions -Url $BinDlUrl -FileTypes $CiscoSetupFileTypes
Function Get-Webfiles-CiscoVersions() {
	Param(
		[Parameter(Mandatory)][String]$Url,
		# e.g. @('.msi$', '.zip$')
		[Parameter(Mandatory)][String[]]$FileTypes
	)

	$Files = Get-Web-Filelisting -Url $Url -FileTypes $FileTypes
	Return @( @($Files | select oCiscoVersion -Unique), $Files)
}


# Liest von einem lokalen Verzeichnis wie
# alle Files und extrahiert die Cisco-Version
#
# !Ex
# 	$CiscoVersions, $Files = Get-Files-CiscoVersions -LocalDir ...
Function Get-Files-CiscoVersions() {
	Param(
		[Parameter(Mandatory)][String]$LocalDir,
		# e.g. @('.msi$', '.zip$')
		[Parameter(Mandatory)][String[]]$FileTypes
	)

	$Files = Get-Filelisting -LocalDir $LocalDir -FileTypes $FileTypes
	Return @( @($Files | select oCiscoVersion -Unique), $Files)
}



# Holt eine Msi-Datei vom Web
Function Get-File-FromWeb() {
	Param(
		[Parameter(Mandatory)]
		[String]$FileUrl,
		[Parameter(Mandatory)]
		[String]$TempDir
	)

	# Das MSI vom Web holen
	$DlFilename = Join-Path $TempDir ([IO.Path]::GetFileName( $FileUrl ))
	# Download
	$Res = Invoke-WebRequest -URI $FileUrl -OutFile $DlFilename -PassThru
	If ($Res.StatusCode -eq 200) {
		Return $DlFilename
	} Else {
		Log 4 'Fehler beim Download von:' -ForegroundColor Red
		Log 4 ('{0}' -f $FileUrl)
		Return $Null
	}
}


# Sucht das passende MSI vom lokalen BinDir
# oder auf Wunsch aus dem Web:
# https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Bin/
Function Get-MsiFile() {
	Param(
		[Parameter(Mandatory)]
		[String]$MsiExeFileName,
		[Parameter(Mandatory)]
		[String]$LocalBinDir
	)

	# Das MSI lokal suchen
	$MatchingMsiFiles = @(Get-ChildItem -LiteralPath $LocalBinDir -Filter $MsiExeFileName)

	Switch($MatchingMsiFiles.Count) {
		0 {
			Log 4 'MSI nicht gefunden:' -ForegroundColor Red
			Log 5 "Verzeichnis: $($LocalBinDir)" -ForegroundColor White
			Log 5 "File       : $($MsiExeFileName)" -ForegroundColor White
			Return $Null
		}

		1 {
			$ThisMsiFilename = $MatchingMsiFiles[0].FullName
			Return $ThisMsiFilename
		}

		Default {
			Log 4 'Mehrere MSI gefunden:' -ForegroundColor Red
			Log 5 "Verzeichnis: $($LocalBinDir)" -ForegroundColor White
			Log 5 "Fuer File  : $($MsiExeFileName)" -ForegroundColor White
			Log 5 'Matching Files:' -ForegroundColor White
			$MatchingMsiFiles | % {
				Log 6 "$($_.FullName)" -ForegroundColor White
			}
			Return $Null
		}
	}
}


# Startet Cisco AnyConnect
Function Start-CiscoAnyConnectExe() {
	$CiscoAnyConnectExe = (Get-ChildItem -LiteralPath 'C:\Program Files (x86)\Cisco\' -Filter 'vpnui.exe' -Recurse | Sort LastWriteTime -Descending | select -First 1 -ExpandProperty Fullname)
	If ($CiscoAnyConnectExe) { . $CiscoAnyConnectExe }
}


# Sucht in der Liste der Files der Webseite
# dieses msi, das zum Cisco Modul passt
Function Get-CiscoModule-FullFilename() {
	Param(
		[Parameter(Mandatory)]
		[eCiscoModule]$eCiscoModule,
		[Parameter(Mandatory)]
		[Object[]]$WebSiteFilenames
	)

	$ModuleFiles = @($WebSiteFilenames | ? Filename  -like "*$($SetupCfg[ $eCiscoModule ].MsiName)*" | select -ExpandProperty FullName)

	Switch ($ModuleFiles.Count) {
		0 {
			Log 4 "Kein Cisco Setup File gefunden fuer: $eCiscoModule" -ForegroundColor Red
			Log 4 'Abbruch' -ForegroundColor Red
			Break Script
		}
		1 {
			Return $ModuleFiles[0]
		}
		Default {
			Log 4 "Mehrere Cisco Setup File gefunden fuer: $eCiscoModule" -ForegroundColor Red
			$ModuleFiles | % {
				Log 5 $_ -ForegroundColor White
			}
			Log 4 'Abbruch' -ForegroundColor Red
			Break Script
		}
	}
}



## Prepare: Start Elevated
# !Sj Autostart Shell elevated

# True, wenn Elevated
# 220813
Function Is-Elevated() {
	([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}


# !Sj Autostart Shell elevated
if (!(Is-Elevated)) {
	Write-Host ">> starte PowerShell als Administrator (Elevated)`n`n" -ForegroundColor Red
	# Beim Testen kein Sleep
	If ($ShowDebugInfos -eq $False) { Start-Sleep -Seconds 4 }

	## Script-Parameter der elevated session weitergeben
	[String[]]$InvocationBoundParameters = $MyInvocation.BoundParameters.GetEnumerator() | ForEach-Object {
		if ($_.Value -is [Switch]) { "-$($_.Key)" } else { "-$($_.Key)", "$($_.Value)" }
	}
	$InvocationUnboundArguments = $MyInvocation.UnboundArguments
	$InvocationAllArgs = $InvocationBoundParameters + $InvocationUnboundArguments

	$InvokeScriptCmd = ''
	If ($ShowDebugInfos) {
		$InvokeScriptCmd = 'Write-Host "";'
		$InvokeScriptCmd += '$CommandLineArgs = [System.Environment]::GetCommandLineArgs();'
		$InvokeScriptCmd += 'Write-Host "";'

		$InvokeScriptCmd += 'Write-Host ''GetCommandLineArgs() -join:'' -ForegroundColor Yellow;'
		$InvokeScriptCmd += 'Write-Host ($CommandLineArgs -join '' '') ;'
		$InvokeScriptCmd += 'Write-Host "";'
	}

	## !KH9^9 TomTom:
	## Start-Process muss ein '"' als dreifaches '"""' Übergeben werden!, sonst wird es rausgefiltert!

	# TLS 1.2 aktivieren
	$InvokeScriptCmd += '[Net.ServicePointManager]::SecurityProtocol = """Tls12"""; '

	# Invoke-Expression vorbereiten
	$InvokeScriptCmd += 'Invoke-Expression """ &{ $(Invoke-RestMethod -DisableKeepAlive -Uri ''' + $ThisScriptPermaLink + ''') } '
	# Dem heruntergeladenen Script die Parameter mitgeben
	$InvokeScriptCmd += ($InvocationAllArgs -join ' ')
	$InvokeScriptCmd += '"""'

	## Die Config der neuen PS Session
	$BasicPSSetting = '-NoProfile -ExecutionPolicy Bypass '
	If ($ShowDebugInfos) {
		# Elevated Shell schliessen
		$BasicPSSetting += '-NoExit '
	}

	$MainCmd = "-Command CD 'C:\Temp'; $InvokeScriptCmd"

	$AllCmds = $BasicPSSetting + $MainCmd

	If ($ShowDebugInfos) {
		Write-Host $AllCmds -ForegroundColor Magenta
	}

	Start-Process PowerShell.exe -Verb RunAs $AllCmds

	If ($ShowDebugInfos) {
		# Aktuelle Shell nicht schliessen
		Break Script
	} Else {
		# Aktuelle Shell schliessen
		Start-Sleep -Milliseconds 2500
		Exit
	}

} Else {
	# Wir sind elevated
	$Host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Definition + ' (Elevated)'
	$Host.UI.RawUI.BackgroundColor = 'DarkBlue'
	Clear-Host
}


# Assert is elevated
If ( (Is-Elevated) -eq $False) {
	Write-Host "`nDas Script muss als Administrator / Elevated ausgefuehrt werden" -ForegroundColor Red
	Start-Sleep -Milliseconds 3500
	Write-Host -NoNewLine "`nPress any key to continue…" -ForegroundColor Green
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	Return
}



### Prepare

$LocalBinDir = Join-Path $ScriptDir 'Bin'
$TempDir = Get-TempDir

Log 0 'Pruefe, ob Cisco AnyConnect aktualisiert werden muss'
Log 1 "Version: $Version" -ForegroundColor DarkGray
Log 1 "Rueckmeldungen bitte an: $Feedback" -ForegroundColor DarkGray

# Aus den gewaehlten Modulen die Enum-Liste erstellen
$eSelectedModules = @()

# Die Standardmodule der Nosergruppe installieren?
If ($InstallNosergroupDefaultModules) {
	# Alle default-Module in die Enum-Liste einfügen
	$NosergroupDefaultModules | % {
		# Cast des aktuellen Moduls in die enum
		$EnumItem = [eCiscoModule]$_
		If ($EnumItem -eq $null) {
			Write-Error ('Unbekannter Modulname: {0}' -f $_)
		} Else {
			# Die Enum-Liste ergaenzen
			$eSelectedModules += $EnumItem
		}
	}
} Else {
	# Die vom Benutzer gewaehlten Module in die Enum-Liste einfügen
	$CiscoModules | % {
		# Cast des aktuellen Moduls in die enum
		$EnumItem = [eCiscoModule]$_
		If ($EnumItem -eq $null) {
			Write-Error ('Unbekannter Modulname: {0}' -f $_)
		} Else {
			$eSelectedModules += $EnumItem
		}
	}
}



Function Has-Value($Data) {
	If ($Data -eq $null) { Return $False }
	Switch ($Data.GetType().Name) {
		'String' {
			If ([String]::IsNullOrEmpty($Data)) { Return $False }
			Else { Return $True }
		}
		Default {
			Return $True
		}
	}
}


# Erzeugt aus
# C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\Uninstall.exe -remove
# Den richtigen Befehl:
# "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\Uninstall.exe" -remove
#
Function Split-Command-AndArgs($Command) {
	$Items = $Command -split ' '
	for ($i = 0; $i -lt $Items.Count; $i++) {
		$TestPath = $items[0 .. $i] -join ' '
		# Get-Command erkennt auch Befehle, ohne dass die Dateierweiterung angegeben wird :-)
		$Cmd = Get-Command $TestPath -ErrorAction SilentlyContinue
		If ($Cmd -ne $null) {
			Return ("`"{0}`" {1}" -f $TestPath, ($items[($i + 1) .. ($Items.Count - 1)] -join ' '))
		}
	}
}


# Liefert die Liste der installierten SW
Function Get-Installed-Software {
	<#
.Synopsis
	This function generates a list by querying the registry and returning the installed programs of a local or remote computer.
	200807, tom-agplv3@jig.ch

.PARAMETER ComputerName
	The computer to which connectivity will be checked

.PARAMETER Property
	Additional values to be loaded from the registry.
	A String or array of String hat will be attempted to retrieve from the registry for each program entry

.PARAMETER IncludeProgram
	This will include the Programs matching that are specified as argument in this parameter.
	Wildcards allowed.

.PARAMETER ExcludeProgram
	This will exclude the Programs matching that are specified as argument in this parameter.
	Wildcards allowed.

.PARAMETER ProgramRegExMatch
	Change IncludeProgram / ExcludeProgram
	from -like operator
	to -match operator.

.PARAMETER LastAccessTime
	Estimates the last time the program was executed by looking in the installation folder,
	if it exists, and retrieves the most recent LastAccessTime attribute of any .exe in that folder.
	This increases execution time of this script as it requires (remotely) querying the file system to retrieve this information.

.PARAMETER ExcludeSimilar
	This will filter out similar programnames,
	the default value is to filter on the first 3 words in a program name.
	If a program only consists of less words it is excluded and it will not be filtered.
	For example if you Visual Studio 2015 installed it will list all the components individually,
	using -ExcludeSimilar will only display the first entry.

.PARAMETER SimilarWord
	This parameter only works when ExcludeSimilar is specified,
	it changes the default of first 3 words to any desired value.

.PARAMETER DisplayRegPath
	Displays the registry path as well as the program name

.PARAMETER MicrosoftStore
	Also queries the package list reg key, allows for listing Microsoft Store products for current user


.EXAMPLE
	Get-Installed-Software
	Get list of installed programs on local machine

.EXAMPLE
	Get-Installed-Software -Property DisplayVersion,VersionMajor,Installdate | ft

.EXAMPLE
	Get-Installed-Software -Property DisplayVersion,VersionMajor,Installdate,UninstallString

.EXAMPLE
	Get-Installed-Software -ComputerName server01,server02
	Get list of installed programs on server01 and server02

.EXAMPLE
	'server01','server02' | Get-Installed-Software -Property UninstallString
	Get the installed programs on server01/02 that are passed on to the function
	through the pipeline
	and also retrieves the uninstall String for each program

.EXAMPLE
	'server01','server02' | Get-Installed-Software -Property UninstallString -ExcludeSimilar -SimilarWord 4
	Get retrieve the installed programs on server01/02
	that are passed on to the function through the pipeline
	and also retrieves the uninstall String for each program.
	Will only display a single entry of a program of which the first four words are identical.

.EXAMPLE
	Get-Installed-Software -Property installdate,UninstallString,installlocation -LastAccessTime | Where-Object {$_.installlocation}
	Get the list of programs from Server01
	and retrieves the InstallDate,UninstallString and InstallLocation properties.
	Then filters out all products that do not have a installlocation set
	and displays the LastAccessTime when it can be resolved.

.EXAMPLE
	Get-Installed-Software -Property installdate -IncludeProgram *office*
	Get the InstallDate of all components that match the wildcard pattern of *office*

.EXAMPLE
	Get-Installed-Software -Property installdate -IncludeProgram 'Microsoft Office Access','Microsoft SQL Server 2014'

	Get the InstallDate of all components
	that exactly match Microsoft Office Access & Microsoft SQL Server 2014

.EXAMPLE
	Get-Installed-Software -Property installdate -IncludeProgram '*[10*]*' | Format-Table -Autosize > MyInstalledPrograms.txt

	Get the ComputerName, ProgramName and installdate
	of the programs matching the *[10*]* wildcard
	and using Format-Table
	and redirection to write this output to text file

.EXAMPLE
	Get-Installed-Software -IncludeProgram ^Office -ProgramRegExMatch

	Get the InstallDate of all components
	that match the regex pattern of ^Office.*,
	which means any ProgramName starting with the word Office

.EXAMPLE
	Get-Installed-Software -DisplayRegPath

	Get the list of programs from the local system and displays the registry path

.EXAMPLE
	Get-Installed-Software -DisplayRegPath -MicrosoftStore

.NOTES
	Q
	https://gallery.technet.microsoft.com/scriptcenter/Get-Installed-Software-Get-list-de9fd2b4
	001 O
	002	Bereinigung des Uninstall-Strings
#>
	[CmdletBinding(SupportsShouldProcess = $true)]
	Param(
		[Parameter(ValueFromPipeline = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 0
		)]
		[String[]]$ComputerName = $env:COMPUTERNAME,
		[Parameter(Position = 0)]
		[String[]]$Property,
		[String[]]$IncludeProgram,
		[String[]]$ExcludeProgram,
		[switch]$ProgramRegExMatch,
		[switch]$LastAccessTime,
		[switch]$ExcludeSimilar,
		[switch]$DisplayRegPath,
		[switch]$MicrosoftStore,
		[Int]$SimilarWord
	)

	Begin {
		$RegistryLocation = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
		'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'

		if ($psversiontable.psversion.major -gt 2) {
			$HashProperty = [ordered]@{}
		}
		else {
			$HashProperty = @{}
			$SelectProperty = @('ComputerName', 'ProgramName')
			if ($Property) {
				$SelectProperty += $Property
			}
			if ($LastAccessTime) {
				$SelectProperty += 'LastAccessTime'
			}
		}
	}

	Process {
		foreach ($Computer in $ComputerName) {
			try {
				$socket = New-Object Net.Sockets.TcpClient($Computer, 445)
				if ($socket.Connected) {
					'LocalMachine', 'CurrentUser' | ForEach-Object {
						$RegName = if ('LocalMachine' -eq $_) {
							'HKLM:\'
						}
						else {
							'HKCU:\'
						}

						if ($MicrosoftStore) {
							$MSStoreRegPath = 'Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages\'
							if ('HKCU:\' -eq $RegName) {
								if ($RegistryLocation -notcontains $MSStoreRegPath) {
									$RegistryLocation = $MSStoreRegPath
								}
							}
						}

						$RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::$_, $Computer)
						$RegistryLocation | ForEach-Object {
							$CurrentReg = $_
							if ($RegBase) {
								$CurrentRegKey = $RegBase.OpenSubKey($CurrentReg)
								if ($CurrentRegKey) {
									$CurrentRegKey.GetSubKeyNames() | ForEach-Object {
										Write-Verbose -Message ('{0}{1}{2}' -f $RegName, $CurrentReg, $_)

										$DisplayName = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayName')
										if (($DisplayName -match '^@{.*?}$') -and ($CurrentReg -eq $MSStoreRegPath)) {
											$DisplayName = $DisplayName -replace '.*?\/\/(.*?)\/.*', '$1'
										}

										$HashProperty.ComputerName = $Computer
										$HashProperty.ProgramName = $DisplayName

										if ($DisplayRegPath) {
											$HashProperty.RegPath = '{0}{1}{2}' -f $RegName, $CurrentReg, $_
										}

										if ($IncludeProgram) {
											if ($ProgramRegExMatch) {
												$IncludeProgram | ForEach-Object {
													if ($DisplayName -notmatch $_) {
														$DisplayName = $null
													}
												}
											}
											else {
												$IncludeProgram | Where-Object {
													$DisplayName -notlike ($_ -replace '\[', '`[')
												} | ForEach-Object {
													$DisplayName = $null
												}
											}
										}

										if ($ExcludeProgram) {
											if ($ProgramRegExMatch) {
												$ExcludeProgram | ForEach-Object {
													if ($DisplayName -match $_) {
														$DisplayName = $null
													}
												}
											}
											else {
												$ExcludeProgram | Where-Object {
													$DisplayName -like ($_ -replace '\[', '`[')
												} | ForEach-Object {
													$DisplayName = $null
												}
											}
										}

										if ($DisplayName) {
											if ($Property) {
												foreach ($CurrentProperty in $Property) {
													# tomtom: den UninstallString bereiigen
													If ($CurrentProperty -eq 'UninstallString') {
														$UninstallString = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
														$UninstallStringCln = $UninstallString
														If ([String]::IsNullOrEmpty($UninstallStringCln)) {
															$HashProperty.$CurrentProperty = ''
															$HashProperty.UninstallStringCln = ''
														}
														Else {
															$UninstallStringCln = $UninstallStringCln.Trim()
															# Äussere " entfernen
															If ($UninstallStringCln[0] -eq '"' -and $UninstallStringCln[-1] -eq '"') {
																$UninstallStringCln = $UninstallStringCln[1..($UninstallStringCln.Length - 2)] -Join ''
															}
															# Äussere ' entfernen
															If ($UninstallStringCln[0] -eq "'" -and $UninstallStringCln[-1] -eq "'") {
																$UninstallStringCln = $UninstallStringCln[1..($UninstallStringCln.Length - 2)] -Join ''
															}
															# Erzeugt:
															# "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\Uninstall.exe" -remove
															$UninstallStringCln = Split-Command-AndArgs $UninstallStringCln
															$HashProperty.$CurrentProperty = $UninstallString
															$HashProperty.UninstallStringCln = $UninstallStringCln
														}
													}
													Else {
														$HashProperty.$CurrentProperty = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
													}
												}
											}
											if ($LastAccessTime) {
												$InstallPath = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('InstallLocation') -replace '\\$', ''
												if ($InstallPath) {
													$WmiSplat = @{
														ComputerName = $Computer
														Query        = $("ASSOCIATORS OF {Win32_Directory.Name='$InstallPath'} Where ResultClass = CIM_DataFile")
														ErrorAction  = 'SilentlyContinue'
													}
													$HashProperty.LastAccessTime = Get-WmiObject @WmiSplat |
													Where-Object { $_.Extension -eq 'exe' -and $_.LastAccessed } |
													Sort-Object -Property LastAccessed |
													Select-Object -Last 1 | ForEach-Object {
														$_.ConvertToDateTime($_.LastAccessed)
													}
												}
												else {
													$HashProperty.LastAccessTime = $null
												}
											}

											if ($psversiontable.psversion.major -gt 2) {
												[PSCustomObject]$HashProperty
											}
											else {
												New-Object -TypeName PSCustomObject -Property $HashProperty |
												Select-Object -Property $SelectProperty
											}
										}
										$socket.Close()
									}

								}

							}

						}
					}
				}
			}
			catch {
				Write-Error $_
			}
		}
	}

	End {
	}

}


# Sucht die installierte Cisco Software
# !Ex
# 	Get-CiscoSW-ToUninstall -Property DisplayVersion, VersionMajor, Installdate, Uninstallstring
Function Get-CiscoSW-ToUninstall([String[]]$Property, [String[]]$IncludeProgram = '*Cisco *') {
	$Splat = @{ }
	If ($Property) { $Splat += @{ Property = $Property } }
	If ($IncludeProgram) { $Splat += @{ IncludeProgram = $IncludeProgram } }
	Get-Installed-Software @Splat
}



# Sucht das Modul ISE Posture und liefert die installierte Version zurück
Function Get-Installed-CiscoVersion() {

	Log 1 'Lese die Liste der installierten SW'
	# Alle installierte Cisco SW bestimmen
	$CiscoSW = Get-CiscoSW-ToUninstall -Property DisplayVersion, VersionMajor, Installdate, UninstallString

	## Herausfinden, welche Cisco Version insalliert ist
	# dafür nützen wir ISE Posture
	$CiscoIsePosture = $CiscoSW | ? ProgramName -like '*ISE Posture*'
	If ($CiscoIsePosture) {
		$InstalledCiscoIsePostureVersion = [Version]$CiscoIsePosture.DisplayVersion
		Return $InstalledCiscoIsePostureVersion
	}
}


## Main

Log 1 'Lese die verfügbare Cisco-Version'
If ($InstallFromWeb) {
	$CiscoVersions, $CiscoSetupFiles = Get-Webfiles-CiscoVersions -Url $BinDlUrl -FileTypes $CiscoSetupFileTypes
} Else {
	$CiscoVersions, $CiscoSetupFiles = Get-Files-CiscoVersions -LocalDir $LocalBinDir -FileTypes $CiscoSetupFileTypes
}


## Haben wir nur 1 Cisco Version?
Switch ($CiscoVersions.Count) {
	0 {
		Log 0 'Keine Cisco Setup-Files gefunden auf:' -ForegroundColor Red
		Log 1 "$BinDlUrl" -ForegroundColor White
		Log 0 'Abbruch' -ForegroundColor Red
		Break Script
	}
	1 {
		# OK!
		Log 2 "Gefunden: $($CiscoVersions | Select -ExpandProperty oCiscoVersion)"
	}
	Default {
		Log 0 'Mehrere Cisco Setup-File Versionen gefunden auf:' -ForegroundColor Red
		Log 1 "$BinDlUrl" -ForegroundColor White

		$CiscoVersions | % {
			Log 2 $_.oVersion
		}

		Log 0 'Abbruch' -ForegroundColor Red
		Break Script
	}
}


# Die installierte Cisco Version bestimmen
$InstalledCiscoIsePostureVersion = Get-Installed-CiscoVersion


# Ist die verfügbare Version älter oder gleich alt wie die installierte Version?
If ($CiscoVersions[0].oCiscoVersion -le $InstalledCiscoIsePostureVersion) {
	Log 0 'Cisco ist bereits aktuell' -ForegroundColor Green
	Start-Sleep -Milliseconds 3500
	Break Script
}



## Installation starten

If ($InstallNosergroupDefaultModules) {
	Log 0 'Installation der Standard-Komponenten fuer Geraete der Nosergruppe:' -ForegroundColor Green -NewLineBefore
} Else {
	Log 0 'Installation von individuellen Komponenten:' -ForegroundColor Green -NewLineBefore
}
Log 1 "$($eSelectedModules -Join ', ')"


# Die Module installieren

$Anz = $eSelectedModules.Count
$Cnt = 1
ForEach($eSelectedModule in $eSelectedModules) {
	$ThisModuleCfg = $SetupCfg[$eSelectedModule]
	Log 2 ("Installiere {0}/{1}: {2}" -f ($Cnt++), $Anz, $ThisModuleCfg.Name) -ForegroundColor Yellow

	# In der Dateiliste das richtige msi suchen
	$SetupFullFileName = Get-CiscoModule-FullFilename -eCiscoModule $eSelectedModule -WebSiteFilenames $CiscoSetupFiles

	# Allenfalls das Setup herunterladen
	If ($InstallFromWeb) {
		$ThisMsiFilename = Get-File-FromWeb -FileUrl $SetupFullFileName -TempDir $TempDir
	} Else {
		$ThisMsiFilename = $SetupFullFileName
	}

	# Wenn wir ein MSI File haben
	If ($ThisMsiFilename) {
		# Die MSI Parameter vorbereiten
		$ThisMsiParams = $ThisModuleCfg.MsiParams -Split ' '

		# Setup starten
		If (Is-WhatIf) {
			Log 2 'WhatIf:'
			Log 3 "Start-Process -Wait -FilePath $ThisMsiFilename -ArgumentList $($ThisMsiParams -Join ',')"
		} Else {
			# Start-Process -Wait -FilePath 'C:\Windows\system32\msiexec.exe' -ArgumentList @('/i', " `"$CiscoSetupMSI`"", '/passive')
			Start-Process -Wait -FilePath $ThisMsiFilename -ArgumentList $ThisMsiParams
		}

	}
}

Log 0 'Starte Cisco AnyConnect' -ForegroundColor Yellow -NewLineBefore
Start-CiscoAnyConnectExe
