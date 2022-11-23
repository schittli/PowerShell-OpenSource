# Installiert von Cisco AnyConnect die Standards-Komponenten
# für Geräte der Nosergruppe (Siehe: $NosergroupDefaultModules)
#
# Bei Bedarf ist das Script vorbereitet, um gezielt einzelne Module zu installieren
# (nicht getestet)
#
# Getting started:
# https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/ReadMe.html
#
# !Ex
# 	# 1. PowerShell als Administrator öffnen
# 	# 2. Ausführen: (mit copy & paste!)
#		[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb"
#
# 	# Variante mit -WhatIf:
#		[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -WhatIf"
#
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

[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'SetupDefaultModules')]
Param(
	[Parameter(ParameterSetName = 'SetupDefaultModules')]
	[Switch]$InstallNosergroupDefaultModules,
	[Parameter(ParameterSetName = 'SetupIndividualModules')]
	[ValidateSet(IgnoreCase, 'VPN', 'SBL', 'DART', 'NAM', 'Umbrella', 'Posture', 'ISEPosture', 'AMPEnabler', 'NVM')]
	[String[]]$CiscoModules,
	[Switch]$InstallFromWeb,
	# Die Url zum Bin-Verzeichnis mit den Msi Files
	[String]$BinDlUrl = 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Bin',
	# Die elevated Shell nicht schliessen
	[Switch]$NoExit
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
$ThisScriptPermaLink = 'https://github.com/schittli/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1'
$ThisScriptPermaLink = 'https://www.akros.ch/it/Cisco/Test/Setup-CiscoAnyConnect.ps1'


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
	If ($NoExit -eq $False) { Start-Sleep -Seconds 4 }

	## Script-Parameter der elevated session weitergeben
	[String[]]$InvocationBoundParameters = $MyInvocation.BoundParameters.GetEnumerator() | ForEach-Object {
		if ($_.Value -is [Switch]) { "-$($_.Key)" } else { "-$($_.Key)", "$($_.Value)" }
	}
	$InvocationUnboundArguments = $MyInvocation.UnboundArguments
	$InvocationAllArgs = $InvocationBoundParameters + $InvocationUnboundArguments

	$CommandOri = "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-Expression -Command (Invoke-RestMethod -Uri `"$ThisScriptPermaLink`") $InvocationAllArgs"

	# [Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://github.com/schittli/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -NoExit"
	# [Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://github.com/...//Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -NoExit"
	# [Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-Expression -Command (Invoke-RestMethod -Uri "https://github.com/schittli/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1") -InstallNosergroupDefaultModules

	# $Command = "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-Expression (Invoke-RestMethod -Uri `"$ThisScriptPermaLink`") $InvocationAllArgs"
	# $Command = ('[Net.ServicePointManager]::SecurityProtocol = ''Tls12''; Invoke-Expression " &{{ $(Invoke-RestMethod -Uri "{0}") }} {1}"' -f $ThisScriptPermaLink, ($InvocationAllArgs -join ' '))

	# $Command = ('[Net.ServicePointManager]::SecurityProtocol = ''Tls12''; Invoke-Expression ""&{{ $(Invoke-RestMethod -Uri ''{0}'') }} {1}""' -f $ThisScriptPermaLink, ($InvocationAllArgs -join ' '))

	# 221123 181416

# [Net.ServicePointManager]::SecurityProtocol = 'Tls12';
# iex "& { $(irm 'https://github.com/schittli/PowerShell-OpenSource/raw/main/Functions/Setup-CiscoAnyConnect/Setup-CiscoAnyConnect.ps1') } -InstallNosergroupDefaultModules -InstallFromWeb -NoExit"


	## Den Scriptaufruf vorbereiten
	# TLS 1.2 aktivieren
	$InvokeScriptCmd = 'Write-Host "";'
	$InvokeScriptCmd += '$CommandLineArgs = [System.Environment]::GetCommandLineArgs();'
	$InvokeScriptCmd += 'Write-Host "";'

	# Die $CommandLineArgs als einzelne Elemente ausgeben
	# $InvokeScriptCmd += 'Write-Host ''GetCommandLineArgs():'' -ForegroundColor Yellow;'
	# $InvokeScriptCmd += '$CommandLineArgs | % { Write-Host $_ };'
	$InvokeScriptCmd += 'Write-Host ''GetCommandLineArgs() -join:'' -ForegroundColor Yellow;'
	$InvokeScriptCmd += 'Write-Host ($CommandLineArgs -join '' '') ;'
	$InvokeScriptCmd += 'Write-Host "";'

	# Start-Process: `" erzeugt: •`•
	# $InvokeScriptCmd += '[Net.ServicePointManager]::SecurityProtocol = `"Tls12`"; '

	# Start-Process: " erzeugt: ••
	# $InvokeScriptCmd += '[Net.ServicePointManager]::SecurityProtocol = "Tls12"; '

	# Start-Process: "" erzeugt: ••
	# $InvokeScriptCmd += '[Net.ServicePointManager]::SecurityProtocol = ""Tls12""; '

	# !KH9^9 TomTom: Start-Process muss ein '"' als dreifaches '"""' Übergeben werden!, sonst wird es rausgefiltert!
	# Start-Process: """ erzeugt: •"•
	$InvokeScriptCmd += '[Net.ServicePointManager]::SecurityProtocol = """Tls12"""; '

	# Invoke-Expression vorbereiten
	$InvokeScriptCmd += 'Invoke-Expression """ &{ $(Invoke-RestMethod -DisableKeepAlive -Uri ''' + $ThisScriptPermaLink + ''') } '
	# Dem heruntergeladenen Script die Parameter mitgeben
	$InvokeScriptCmd += ($InvocationAllArgs -join ' ')
	$InvokeScriptCmd += '"""'

	## Die Config der neuen PS Session
	$BasicPSSetting = '-ExecutionPolicy Bypass '
	If ($NoExit) {
		$BasicPSSetting += '-NoExit '
	}

	$MainCmd = "-Command CD 'C:\Temp'; $InvokeScriptCmd"

	$AllCmds = $BasicPSSetting + $MainCmd

	Write-Host $AllCmds -ForegroundColor Magenta

	Start-Process PowerShell.exe -Verb RunAs $AllCmds

	# If ($NoExit) {
		# Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -Command $Command"
	# } Else {
		# Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command $Command"
	# }


	If ($NoExit) {
		Break Script
	} Else {
		# Exit from the current, unelevated, process
		Start-Sleep -Milliseconds 2500
		Exit
	}

} Else {
	$Host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Definition + ' (Elevated)'
	$Host.UI.RawUI.BackgroundColor = 'DarkBlue'
	Clear-Host
	Log 0 'Pruefe, ob das Cisco Modul Network Access Manager (NAM) installiert ist'
	Log 1 "Version: $Version" -ForegroundColor DarkGray
	Log 1 "Rueckmeldungen bitte an: $Feedback" -ForegroundColor DarkGray
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



## Main

Log 1 'Lese die Cisco-Version'
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


## Installation starten

If ($InstallNosergroupDefaultModules) {
	Log 0 'Installation der Standard-Komponenten fuer Geraete der Nosergruppe:' -ForegroundColor Green
} Else {
	Log 0 'Installation von individuellen Komponenten:' -ForegroundColor Green
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
