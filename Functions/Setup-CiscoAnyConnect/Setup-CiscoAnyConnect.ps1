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


[CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'SetupDefaultModules')]
Param(
	[Parameter(ParameterSetName = 'SetupDefaultModules')]
	[Switch]$InstallNosergroupDefaultModules,
	[Parameter(ParameterSetName = 'SetupIndividualModules')]
	[ValidateSet(IgnoreCase, 'VPN', 'SBL', 'DART', 'NAM', 'Umbrella', 'Posture', 'ISEPosture', 'AMPEnabler', 'NVM')]  
	[String[]]$CiscoModules,
	[Switch]$InstallFromWeb,
	# Die Url zum Bin-Verzeichnis mit den Msi Files
	[String]$BinDlUrl = 'https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Bin'
)



## Config

$Version = '1.0, 22.11.22'
$Feedback = 'bitte an: schittli@akros.ch'

$VersionZuInstallieren = '4.10.05111'

$CiscoSetupFileTypes = @('.msi$', '.zip$')

# Die Standardmodule, die in der Nosergruppe installiert werden
$NosergroupDefaultModules = @('VPN', 'AMPEnabler', 'Umbrella', 'ISEPosture', 'DART')

## Konfiguration der MSI Setup Parameter
$MsiFilenamePrefix = 'anyconnect-win-'
$MsiFilenameDelimiter = '-'
$SetupExt = '.msi'

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
            Write-Host "Ungültige Farbe: $($Script:LogColors[$Indent])" -ForegroundColor Red
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
				$Res += $Link.href
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
	If ($Files) {
		$Files = Array-ToObj -Items $Files
		ForEach ($Filename in $Files) {
			$FileVersion = Get-CiscoSetupFilename-VersionInfo $Filename
			$Filename | Add-Member -MemberType NoteProperty -Name oVersion -Value $FileVersion
		}
	}
	Return @( @($Files | select oVersion -Unique), $Files)
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


# Holt eine Msi-Datei vom Web
Function Get-MsiFile-FromWeb() {
	Param(
		[Parameter(Mandatory)]
		[String]$MsiExeFileName,
		[Parameter(Mandatory)]
		[String]$BinDlUrl,
		[Parameter(Mandatory)]
		[String]$TempDir
	)
	
	# Das MSI vom Web holen
	$MsiUrl = Join-URL $BinDlUrl $MsiExeFileName
	$DlFilename = Join-Path $TempDir $MsiExeFileName
	# Download
	$Res = Invoke-WebRequest -URI $MsiUrl -OutFile $DlFilename -PassThru
	If ($Res.StatusCode -eq 200) {
		Return $DlFilename
	} Else {
		Log 4 'Fehler beim Download von:' -ForegroundColor Red
		Log 4 ('{0}' -f $MsiUrl)
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



Function Start-CiscoAnyConnectExe() {
	$CiscoAnyConnectExe = (Get-ChildItem -LiteralPath 'C:\Program Files (x86)\Cisco\' -Filter 'vpnui.exe' -Recurse | Sort LastWriteTime -Descending | select -First 1 -ExpandProperty Fullname)
	If ($CiscoAnyConnectExe) { . $CiscoAnyConnectExe }
}



# Sucht in der Liste der Files der Webseite
# dieses msi, das zum Cisco Modul passt
Function Get-CiscoModule-Filename() {
	Param(
		[Parameter(Mandatory)]
		[eCiscoModule]$eCiscoModule,
		[Parameter(Mandatory)]
		[Object[]]$WebSiteFilenames
	)
	
	$ModuleFiles = @($WebSiteFilenames | ? Item  -like "*$($SetupCfg[ $eCiscoModule ].MsiName)*" | select -ExpandProperty Item)
	
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



## Prepare

$LocalBinDir = Join-Path $ScriptDir 'Bin'
$TempDir = Get-TempDir

Log 0 'Pruefe, ob Cisco AnyConnect aktualisiert werden muss'
Log 1 "Version: $Version" -ForegroundColor DarkGray
Log 1 "Rückmeldungen bitte an: $Feedback" -ForegroundColor DarkGray


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
$CiscoVersions, $CiscoWebSiteFilenames = @(Get-Webfiles-CiscoVersions -Url $BinDlUrl -FileTypes $CiscoSetupFileTypes)

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
	Log 1 'Installation der Standard-Komponenten fuer Geraete der Nosergruppe:' -ForegroundColor Green
} Else {
	Log 1 'Installation von individuellen Komponenten:' -ForegroundColor Green
}
Log 2 "$($eSelectedModules -Join ', ')"


# Die Module installieren

$Anz = $eSelectedModules.Count
$Cnt = 1
ForEach($eSelectedModule in $eSelectedModules) {
	$ThisModuleCfg = $SetupCfg[$eSelectedModule]
	Log 2 ("Installiere {0}/{1}: {2}" -f ($Cnt++), $Anz, $ThisModuleCfg.Name) -ForegroundColor Yellow
	
	If ($InstallFromWeb) {
		# In der Dateiliste das richtige msi suchen
		$SetupFileName = Get-CiscoModule-Filename -eCiscoModule $eSelectedModule -WebSiteFilenames $CiscoWebSiteFilenames 
		
		$ThisMsiFilename = Get-MsiFile-FromWeb -MsiExeFileName $SetupFileName -BinDlUrl $BinDlUrl -TempDir $TempDir

	} Else {
		
		# Den Exe-Namen berechnen
		$MsiExeFileName = ('{0}{1}{2}{3}{4}' -f $MsiFilenamePrefix, $VersionZuInstallieren, $MsiFilenameDelimiter, $ThisModuleCfg.MsiName, $SetupExt)
		# Debug
		# Write-Host $MsiExeFileName
		
		# Das MSI File suchen oder herunterladen
		$ThisMsiFilename = Get-MsiFile -MsiExeFileName $MsiExeFileName `
									-LocalBinDir $LocalBinDir `
									-BinDlUrl $BinDlUrl `
									-TempDir $TempDir
		# Write-Host "Gefunden: $($ThisMsiFilename)"
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
