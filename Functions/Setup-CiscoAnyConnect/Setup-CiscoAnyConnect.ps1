# 
# 
# 
# 
# 
# 001, 221109, Tom


[CmdletBinding(DefaultParameterSetName = 'SetupDefaultModules')]
Param(
	[Parameter(ParameterSetName = 'SetupDefaultModules')]
	[Switch]$InstallNosergroupDefaultModules,
	[Parameter(ParameterSetName = 'SetupIndividualModules')]
	[ValidateSet(IgnoreCase, 'VPN', 'SBL', 'DART', 'NAM', 'Umbrella', 'Posture', 'ISEPosture', 'AMPEnabler', 'NVM')]  
	[String[]]$CiscoModules
)



## Config

$ScriptDir = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)


# Die Standardmodule, die in der Nosergruppe installiert werden
$NosergroupDefaultModules = @('VPN', 'AMPEnabler', 'Umbrella', 'ISEPosture', 'DART')

## Konfiguration der MSI Setup Parameter
$MsiFilenamePrefix = 'anyconnect-win-'
$Version = '4.10.05111'
$MsiFilenameDelimiter = '-'
$SetupExt = '.msi'



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



## Prepare

$BinDir = Join-Path $ScriptDir 'Bin'

# Aus den gewählten Modulen die Enum-Liste erstellen
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
			# Die Enum-Liste ergänzen
			$eSelectedModules += $EnumItem
		}
	}
} Else {
	# Die vom Benutzer gewählten Module in die Enum-Liste einfügen
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


# Die Module installieren

ForEach($eSelectedModule in $eSelectedModules) {
	$ThisModuleCfg = $SetupCfg[$eSelectedModule]
	Write-Host "`nInstalliere: $($ThisModuleCfg.Name)" -ForegroundColor Yellow
	
	$MsiFilenamePrefix = 'anyconnect-win-'
$Version = '4.10.05111'
$MsiFilenameDelimiter = '-'
$SetupExt = '.msi'

	$MsiName = 'core-vpn-predeploy-k9'
	
	$MsiExe = ('{0}{1}{2}{3}{4}' -f $MsiFilenamePrefix, $Version, $MsiFilenameDelimiter, $MsiName, $SetupExt)
	
	Write-Host $MsiExe
	
	# Get-ChildItem -LiteralPath 'c:\Temp\Cisco AnyConnect\4.10.05111\-Setup Nosergruppe\PowerShell\' -Filter $vpnmsi
	$MatchingMsiFiles = @(Get-ChildItem -LiteralPath $BinDir -Filter $MsiExe)
	
	# anyconnect-win-4.10.05111-amp-predeploy-k9.msi
	# anyconnect-win-4.10.05111-core-vpn-predeploy-k9.msi
	# anyconnect-win-4.10.05111-iseposture-predeploy-k9.msi
	# anyconnect-win-4.10.05111-umbrella-predeploy-k9.msi	
	
	$MsiParams = '/norestart /passive PRE_DEPLOY_DISABLE_VPN=0'

	# Start-Process -Wait -FilePath 'C:\Windows\system32\msiexec.exe' -ArgumentList @('/i', " `"$CiscoSetupMSI`"", '/passive')
	# Start-Process -Wait -FilePath 'C:\Windows\system32\msiexec.exe' -ArgumentList @('/i', " `"$CiscoSetupMSI`"", '/passive')

	Switch($MatchingMsiFiles.Count) {
		0 {
			Write-Host 'MSI nicht gefunden:' -ForegroundColor Red
			Write-Host "Verzeichnis: $($BinDir)"
			Write-Host "File       : $($MsiExe)"
		}
		
		1 {
			$ThisMsi = $MatchingMsiFiles[0]
			Write-Host "Gefunden: $($ThisMsi.FullName)"
		}
		
		Default {
			Write-Host 'Mehrere MSI gefunden:' -ForegroundColor Red
			Write-Host "Verzeichnis: $($BinDir)"
			Write-Host "Für File   : $($MsiExe)"
			Write-Host "Matching Files:"
			$MatchingMsiFiles | % {
				Write-Host "$($_.FullName)"
			}
			
		}
	}


}


