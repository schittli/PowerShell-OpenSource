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

# Die Standardmodule, die in der Nosergruppe installiert werden
$NosergroupDefaultModules = @('VPN', 'AMPEnabler', 'Umbrella', 'ISEPosture', 'DART')

## Konfiguration der MSI Setup Parameter
$MsiFilenamePrefix = 'anyconnect-win-'
$Version = '4.10.05111'
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


Function Get-TempDir() {
	New-TemporaryFile | %{ rm $_ -Force -WhatIf:$False; mkdir $_ -WhatIf:$False }
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



# Sucht das passende MSI vom lokalen BinDir
# oder auf Wunsch aus dem Web:
# https://www.akros.ch/it/Cisco/AnyConnect/Windows/PowerShell/Bin/
Function Get-MsiFile() {
	Param(
		[Parameter(Mandatory)]
		[String]$MsiExeFileName,
		[Parameter(Mandatory)]
		[String]$LocalBinDir,
		[Parameter(Mandatory)]
		[String]$BinDlUrl,
		[Parameter(Mandatory)]
		[String]$TempDir,
		[Switch]$InstallFromWeb
	)
	
	
	If ($InstallFromWeb) {
		# Das MSI vom Web holen
		$MsiUrl = Join-URL $BinDlUrl $MsiExeFileName
		$DlFilename = Join-Path $TempDir $MsiExeFileName
		# Download
		$Res = Invoke-WebRequest -URI $MsiUrl -OutFile $DlFilename -PassThru
		If ($Res.StatusCode -eq 200) {
			Return $DlFilename
		} Else {
			Write-Host 'Fehler beim Download von:' -ForegroundColor Red
			Write-Host ('{0}' -f $MsiUrl)
			Return $Null
		}
	} Else {
		
		# Das MSI lokal suchen
		$MatchingMsiFiles = @(Get-ChildItem -LiteralPath $LocalBinDir -Filter $MsiExeFileName)
		
		Switch($MatchingMsiFiles.Count) {
			0 {
				Write-Host 'MSI nicht gefunden:' -ForegroundColor Red
				Write-Host "Verzeichnis: $($LocalBinDir)"
				Write-Host "File       : $($MsiExeFileName)"
				Return $Null
			}
			
			1 {
				$ThisMsiFilename = $MatchingMsiFiles[0].FullName
				Return $ThisMsiFilename
			}
			
			Default {
				Write-Host 'Mehrere MSI gefunden:' -ForegroundColor Red
				Write-Host "Verzeichnis: $($LocalBinDir)"
				Write-Host "Fuer File  : $($MsiExeFileName)"
				Write-Host 'Matching Files:'
				$MatchingMsiFiles | % {
					Write-Host "$($_.FullName)"
				}
				Return $Null
			}
		}
	}
}


Function Start-CiscoAnyConnectExe() {
	$CiscoAnyConnectExe = (Get-ChildItem -LiteralPath 'C:\Program Files (x86)\Cisco\' -Filter 'vpnui.exe' -Recurse | Sort LastWriteTime -Descending | select -First 1 -ExpandProperty Fullname)
	If ($CiscoAnyConnectExe) { . $CiscoAnyConnectExe }
}


## Prepare

$LocalBinDir = Join-Path $ScriptDir 'Bin'
$TempDir = Get-TempDir

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

Write-Host "`n`n`n`n`nCisco-Installation" -ForegroundColor Green
Write-Host "Fehler & Ideen bitte an: schittli@akros.ch" -ForegroundColor DarkGray
If ($InstallNosergroupDefaultModules) {
	Write-Host "Installation der Standard-Komponenten fuer Geraete der Nosergruppe:" -ForegroundColor Green
} Else {
	Write-Host "Installation von individuellen Komponenten:" -ForegroundColor Green
}
Write-Host "$($eSelectedModules -Join ', ')`n"


# Die Module installieren

$Anz = $eSelectedModules.Count
$Cnt = 1
ForEach($eSelectedModule in $eSelectedModules) {
	$ThisModuleCfg = $SetupCfg[$eSelectedModule]
	Write-Host ("Installiere {0}/{1}: {2}" -f ($Cnt++), $Anz, $ThisModuleCfg.Name) -ForegroundColor Yellow
	
	# Den Exe-Namen berechnen
	$MsiExeFileName = ('{0}{1}{2}{3}{4}' -f $MsiFilenamePrefix, $Version, $MsiFilenameDelimiter, $ThisModuleCfg.MsiName, $SetupExt)
	# Debug
	# Write-Host $MsiExeFileName
	
	# Das MSI File suchen oder herunterladen
	$ThisMsiFilename = Get-MsiFile -MsiExeFileName $MsiExeFileName `
								-LocalBinDir $LocalBinDir `
								-BinDlUrl $BinDlUrl `
								-TempDir $TempDir `
								-InstallFromWeb:$InstallFromWeb
	# Write-Host "Gefunden: $($ThisMsiFilename)"
	
	# Wenn wir ein MSI File haben
	If ($ThisMsiFilename) {
		# Die MSI Parameter vorbereiten
		$ThisMsiParams = $ThisModuleCfg.MsiParams -Split ' '
		
		# Setup starten
		If (Is-WhatIf) {
			Write-Host 'WhatIf:'
			Write-Host "Start-Process -Wait -FilePath $ThisMsiFilename -ArgumentList $($ThisMsiParams -Join ',')"
		} Else {
			# Start-Process -Wait -FilePath 'C:\Windows\system32\msiexec.exe' -ArgumentList @('/i', " `"$CiscoSetupMSI`"", '/passive')
			
			Start-Process -Wait -FilePath $ThisMsiFilename -ArgumentList $ThisMsiParams
		}
		
	}
}
	
Write-Host "`nStarte Cisco AnyConnect" -ForegroundColor Yellow
Start-CiscoAnyConnectExe
