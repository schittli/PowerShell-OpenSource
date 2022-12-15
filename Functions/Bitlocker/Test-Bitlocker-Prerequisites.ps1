# Muss elevated ausgeführt werden!

# Testet:
# - UEFI BIOS vorhanden
# - UEFI BIOS aktiv
# - Nur als Info: ist SecureBoot aktiviert
#		 SecureBoot ist für BitLocker nicht zwingend
# 			- Ohne SecureBoot kann BitLocker normal konfiguriert und aktiviert / deaktiviert werden
# 			- W10 startet mit BitLocker immer wie erwartet,
# 				- egal, ob SecureBoot aktiviert / deaktiviert ist
# 				- egal, ob man beim Neustart SecureBoot aktiviert / deaktiviert
#


# Ex
#	# Ruft die Infos ab und zeigt sie an
#	.\Test-Bitlocker-Prerequisites.ps1
#
#	# Ruft die Infos ab, zeigt sie an und speichert das Resultat in eine Textdatei
#	.\Test-Bitlocker-Prerequisites.ps1 -WriteLogToDir '\\akros.ch\NETLOGON\Inventar\'
#
#
#

# 001, 221207
#	Autostart Shell elevated


[CmdLetBinding()]
Param(
	# Wenn True, dann wird der BitLocker Key im AD gesichert,
	# wenn der Computer das AD erreichen kann
	[String]$WriteLogToDir,
	[Switch]$OpenBitlockerControlPanel,
	# Im UI keien Infos anzeigen
	[Switch]$Silent,
	# Die elevated Shell nicht schliessen
	[Switch]$NoExit
)


## Pre-Conditions: PowerShell Version 5
# !Sj Autostart Shell elevated
If ($PSVersionTable.PSVersion.Major -gt 5) {
	Write-Host "`nDieses Script muss in PowerShell 5 gestartet werden" -ForegroundColor Red
	Start-Sleep -MilliS 2500
	Write-Host -NoNewLine "`nPress any key to continue…" -ForegroundColor Green
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	Return
}



## Config

$LogDir = '\\akros.ch\sysvol\akros.ch\scripts\Inventar\Inventarfiles\'


Enum eBitlockerCheckState {
	AllDrivesEncrypted; SystemDriveEncrypted
}


## Auto-Config
$ScriptName = $MyInvocation.MyCommand.Source

# elevated
$Version = '001, 221207'
$Feedback = 'bitte an: schittli@akros.ch'

# Perma Link zum eigenen Script
# !Sj Autostart Shell elevated
$ThisScriptPermaLink = $ScriptName

# Allenfalls das Log deaktivieren
$Script:LogDisabled = $Silent


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


# Testet den Status des BitLocker HW Tests
#
# SkipHardwareTest
#	Indicates that BitLocker does not perform a hardware test
#	before it begins encryption. BitLocker uses a hardware test
#	as a dry run to make sure that all the key protectors are
#	correctly set up and that the computer can start without issues.
#
#
# !M https://wutils.com/wmi/root/cimv2/security/microsoftvolumeencryption/win32_encryptablevolume/
# !Ex https://gist.github.com/mchubby/43309ac879db58563c63e4856f3a3a11
# !Q https://blog.csdn.net/chengly0129/article/details/5694101
#
Enum eBitlockerHWTestPendingState {
	NoTestFailedAndNoTestPending; TestFailed; TestPending; UnknownTestState
}
Function Get-Bitlocker-HWTestPending-State($DriveLetter) {
	# Sicherstellen des :
	$DriveLetter = '{0}:' -f ($DriveLetter.Trim(':'))
	$oRes = gwmi('Win32_EncryptableVolume') -namespace 'root\CIMV2\Security\MicrosoftVolumeEncryption' -Filter "DriveLetter = '$DriveLetter'"
	# $oRes

	# uint32 TestStatus, uint32 TestError
	$HwTestStatusMethodParams = @(0, 0)

	$ResHardwareTestStatus = $oRes.InvokeMethod('GetHardwareTestStatus', $HwTestStatusMethodParams)
	If ($ResHardwareTestStatus -ne 0) {
		Write-Host ('Fehler beim Aufruf von GetHardwareTestStatus(): {0}' -f $ResHardwareTestStatus) -ForegroundColor Red
	} Else {
		Switch ($HwTestStatusMethodParams[0]) {
			0 { [eBitlockerHWTestPendingState]::NoTestFailedAndNoTestPending }
			1 { [eBitlockerHWTestPendingState]::TestFailed }
			2 { [eBitlockerHWTestPendingState]::TestPending }
			Default { [eBitlockerHWTestPendingState]::UnknownTestState }
		}
	}
}



# Liefert die Anzal Objekte, $null == 0
Function Count($Obj) {
   ($Obj | measure).Count
}


## Bitlocker Control Panel öffnen
Function Open-BitlockerControlPanel() {
	# !To https://renenyffenegger.ch/notes/Windows/control-panel/index
	control /name Microsoft.BitLockerDriveEncryption
}


# Liefert True, wenn der TPM Chip ready ist
# 	Ohne TPM wird ein zusätzlicher Systemschlüssel benötigt
#	um BitLocker zu verwenden.
#
#	Um den Status des TPM zu erhalten, müssen Sie das Get-Tpm Cmdlet verwenden.
#	Falls das TPM nicht bereit ist,
#	müssen Sie es initialisieren. Das ist mittels Initialize-Tpm möglich.
Function Is-TPM-Ready() {
	# Get-TPM
	# TpmPresent                : True
	# TpmReady                  : True
	# ManufacturerId            : 1398033696
	# ManufacturerIdTxt         : STM
	# ManufacturerVersion       : 1.258.0.0
	# ManufacturerVersionFull20 : 1.258.0.0

	# ManagedAuthLevel          : Full
	# OwnerAuth                 : C+nYOpx3v4yt17P8DAw5J7mi9dA=
	# OwnerClearDisabled        : False
	# AutoProvisioning          : Enabled
	# LockedOut                 : False
	# LockoutHealTime           : 10 minutes
	# LockoutCount              : 0
	# LockoutMax                : 31
	# SelfTest                  : {}

	Get-Tpm | select -ExpandProperty TpmReady
}



# Liefert von allen festen Laufwerken den DriveLetter
Function Get-LocalFixedDrive-Letters() {
	Get-WmiObject Win32_LogicalDisk | `
		? { $_.driveType -eq 3 } | `
		Select -ExpandProperty DeviceID
}



# Liefert alle Laufwerke des Computers mit:
# Laufwerkbuchstabe, Leufwerkbezeichnung, Typ, Dateisystem, Grösse
Enum eDriveType {
	UnknownByWmi; UnknownByOS; NoRootDirectory; RemovableDisk; LocalDisk; NetworkDrive; CD; RAMDisk
}
Function Get-AllDrives-Info() {
	# !M https://powershell.one/wmi/root/cimv2/win32_logicaldisk
	# Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -Property DeviceID, Caption

	$DriveType = @{
		Name = 'DriveType'
		Expression = {
			# property is an array, so process all values
			$value = $_.DriveType
			Switch([int]$value) {
				0          { [eDriveType]::UnknownByWmi}
				1          { [eDriveType]::NoRootDirectory }
				2          { [eDriveType]::RemovableDisk }
				3          { [eDriveType]::LocalDisk }
				4          { [eDriveType]::NetworkDrive }
				5          { [eDriveType]::CompactDisc }
				6          { [eDriveType]::RAMDisk }
				default    { [eDriveType]::UnknownByOS}
			}
		}
	}

	$IsSystemDrive = @{
		Name = 'SystemDrive'
		Expression = {
			($_.Caption.Trim() -eq $Env:SystemDrive.Trim())
		}
	}

	# Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -Property Caption, $DriveType, FileSystem, VolumeName, @{ N='SizeGB'; Ex={ '{0,6:N0}' -f ($_.Size / 1GB) } }
	Get-CimInstance -ClassName Win32_LogicalDisk | Select-Object -Property @{ N = 'DriveLetter'; Ex = { $_.Caption.Trim() } }, $IsSystemDrive, $DriveType, FileSystem, VolumeName, @{ N = 'SizeTB'; Ex = { '{0,6:N3}' -f ($_.Size / 1TB) } }
}


# Liefert alle Lauferke von Computer und ergänzt die Bitlocker-Infos
Function Get-Bitlocker-DriveStatus() {
	$AllDrivesInfo = Get-AllDrives-Info

	# Bitlocker-Infos ergänzen
	$AllDrivesInfo | % {
		# Die BitLocker Infos lesen
		$VolumeInfoBitLocker = Get-BitLockerVolume -MountPoint $_.DriveLetter -EA SilentlyContinue

		# Ist das Laufwerk mit BitLocker verschlüsselt?
		$VolumeIsEncrypted = $False
		If ($VolumeInfoBitLocker.ProtectionStatus -ne 'Off') {
			$VolumeIsEncrypted = $True
		} Else {
			$IsEncryptedVolumeStatus = @('FullyEncrypted', 'EncryptionInProgress')
			$VolumeIsEncrypted = $IsEncryptedVolumeStatus -contains $VolumeInfoBitLocker.VolumeStatus
		}

		# Ist AutoUnlock aktiv?
		$BitlockerAutoUnlockEnabled = -not (([String]::IsNullOrEmpty($VolumeInfoBitLocker.AutoUnlockEnabled)) `
												-or ($VolumeInfoBitLocker.AutoUnlockEnabled -eq $false))

		# Die Props ergänzen
		$_ | Add-Member -MemberType NoteProperty -Name 'BL_VolumeIsEncrypted' -Value $VolumeIsEncrypted
		$_ | Add-Member -MemberType NoteProperty -Name 'BL_EncryptionMethod' -Value $VolumeInfoBitLocker.EncryptionMethod
		$_ | Add-Member -MemberType NoteProperty -Name 'BL_AutoUnlockEnabled' -Value $BitlockerAutoUnlockEnabled
		$_ | Add-Member -MemberType NoteProperty -Name 'BL_VolumeStatus' -Value $VolumeInfoBitLocker.VolumeStatus
		$_ | Add-Member -MemberType NoteProperty -Name 'BL_ProtectionStatus' -Value $VolumeInfoBitLocker.ProtectionStatus
		$_ | Add-Member -MemberType NoteProperty -Name 'BL_LockStatus' -Value $VolumeInfoBitLocker.LockStatus
		$_ | Add-Member -MemberType NoteProperty -Name 'BL_EncryptionPercentage' -Value $VolumeInfoBitLocker.EncryptionPercentage
		$_ | Add-Member -MemberType NoteProperty -Name 'BL_KeyProtector' -Value $VolumeInfoBitLocker.KeyProtector
	}
	$AllDrivesInfo
}


# Liefert true, wenn irgend ein lokales Laufwerk Bitlocker aktiv hat
Function Has-AnyFixedDisk-BitlockerActive() {
	# Alle festen, lokalen Lauferke
	$LocalVolumesBitlockerStatus = Get-Bitlocker-DriveStatus | ? DriveType -eq 'LocalDisk'
	(Count ($LocalVolumesBitlockerStatus | ? BL_VolumeIsEncrypted -eq $True)) -gt 0
}

# Liefert true, wenn das Systendrive Bitlocker aktiv hat
Function Has-SystemDrive-BitlockerActive() {
	# Das feste, lokale System-Lauferk
	$SystemDriveBitlockerStatus = Get-Bitlocker-DriveStatus | ? { $_.DriveType -eq 'LocalDisk' -and $_.SystemDrive -eq $True }
	(Count ($SystemDriveBitlockerStatus | ? BL_VolumeIsEncrypted -eq $True)) -gt 0
}

# Liefert die Anz. Datenlaufwerke
Function Get-NoOf-DataDrives() {
	# Die festen, lokalen Datenlauferke
	$DataDriveBitlockerStatus = Get-Bitlocker-DriveStatus | ? { $_.DriveType -eq 'LocalDisk' -and $_.SystemDrive -eq $False }
	(Count $DataDriveBitlockerStatus)
}

# Liefert true, wenn alle Datenlaufwerke Bitlocker aktiv haben
Function Has-AllDataDrive-BitlockerActive() {
	# Die festen, lokalen Datenlauferke
	$DataDriveBitlockerStatus = Get-Bitlocker-DriveStatus | ? { $_.DriveType -eq 'LocalDisk' -and $_.SystemDrive -eq $False }
	# Haben wir Datenlaufwerke, die nicht verschlüsselt sind?
	(Count ($DataDriveBitlockerStatus | ? BL_VolumeIsEncrypted -eq $False)) -eq 0
}


# Liefert den BIOS-Typ
Enum eBiosType { Legacy; UEFI }
Function Get-Bios-Type() {
	If ($Env:firmware_type.Trim() -eq 'UEFI') {
		Return [eBiosType]::UEFI
	} Else {
		Return [eBiosType]::Legacy
	}
}


# Liefert True, wenn SecureBoot aktiv ist
Function Is-UefiSecureboot-Enabled() {
	Try {
		# !M https://learn.microsoft.com/en-us/powershell/module/secureboot/confirm-securebootuefi?view=windowsserver2022-ps
		$SecureBootEnabled = Confirm-SecureBootUEFI
	}
	 Catch [System.PlatformNotSupportedException] {
		# the computer does not support Secure Boot
		# or is a BIOS (non-UEFI) computer
		$SecureBootEnabled = $False
	}
 	Catch {
		$Ex = $_
		$SecureBootEnabled = $False
		$MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
		$ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not

		Write-Host $MessageId -ForegroundColor Red
		Write-Host $ErrorMessage -ForegroundColor Red
	}
	Return $SecureBootEnabled
}


#Region Add-Border-Text


## Funktion von jdhitsolutions
#
# !M 		https://github.com/jdhitsolutions/PSScriptTools/blob/master/docs/Write-Detail.md
# !Src	https://github.com/jdhitsolutions/PSScriptTools/blob/master/functions/Write-Detail.ps1
Function Write-Detail {
	[cmdletbinding(DefaultParameterSetName = "Default")]
	Param(
		[Parameter(Position = 0, Mandatory)]
		[Parameter(ParameterSetName = "Default")]
		[Parameter(ParameterSetName = "Date")]
		[Parameter(ParameterSetName = "Time")]
		[ValidateNotNullorEmpty()]
		[string]$Message,

		[Parameter(ParameterSetName = "Default")]
		[Parameter(ParameterSetName = "Date")]
		[Parameter(ParameterSetName = "Time")]
		[string]$Prefix = "PROCESS",

		[Parameter(ParameterSetName = "Date")]
		[switch]$Date,
		[Parameter(ParameterSetName = "Time")]
		[Switch]$Time
	)

	#$pfx = $($Prefix.ToUpper()).PadRight("process".length)
	if ($time) {
		$dt = (Get-Date -Format "hh:mm:ss:ffff")
	}
	elseif ($Date) {
		$dt = "{0} {1}" -f (Get-Date).ToShortDateString(), (Get-Date -Format "hh:mm:ss")
	}

	if ($PSCmdlet.ParameterSetName -eq 'Default') {
		$Text = "[$($prefix.ToUpper())] $Message"
	}
	else {
		$Text = "$dt [$($prefix.toUpper())] $Message"
	}
	$Text

}


## Funktion von jdhitsolutions
#
Function Out-VerboseTee {
	[CmdletBinding()]
	[alias("tv", "Tee-Verbose")]
	Param(
		[Parameter(Mandatory, ValueFromPipeline)]
		[object]$Value,
		[Parameter(Position = 0, Mandatory)]
		[string]$Path,
		[System.Text.Encoding]$Encoding,
		[switch]$Append
	)
	Begin {
		#turn on verbose pipeline since if you are running this command you intend for it to be on
		$VerbosePreference = "continue"
	}
	Process {
		#only run if Verbose is turned on
		if ($VerbosePreference -eq "continue") {
			$Value | Out-String | Write-Verbose
			[void]$PSBoundParameters.Remove("Append")
			if ($Append) {
				Add-Content @PSBoundParameters
			}
			else {
				Set-Content @PSBoundParameters
			}
		}
	}
	End {
		$VerbosePreference = "silentlycontinue"
	}
}


## Funktion von jdhitsolutions
#
# Add a border around a string of text
#
# !M		https://github.com/jdhitsolutions/PSScriptTools/blob/master/docs/Add-Border.md
# !Src	https://github.com/jdhitsolutions/PSScriptTools/blob/master/functions/Add-Border.ps1
#
# Ansi Color Codes
# #https://ss64.com/nt/syntax-ansi.html
Function Add-Border {
	[CmdletBinding(DefaultParameterSetName = "single")]
	[alias('ab')]
	[OutputType([System.String])]

	Param(
		# The string of text to process
		[Parameter(Position = 0, Mandatory, ValueFromPipeline, ParameterSetName = 'single')]
		[ValidateNotNullOrEmpty()]
		[string]$Text,

		[Parameter(Position = 0, Mandatory, ParameterSetName = 'block')]
		[ValidateNotNullOrEmpty()]
		[Alias("tb")]
		[string[]]$TextBlock,

		# The character to use for the border. It must be a single character.
		[ValidateNotNullOrEmpty()]
		[alias("border")]
		[string]$Character = "*",

		# add blank lines before and after text
		[Switch]$InsertBlanks,

		# insert X number of tabs
		[int]$Tab = 0,

		[Parameter(HelpMessage = "Enter an ANSI escape sequence to color the border characters." )]
		[string]$ANSIBorder,

		[Parameter(HelpMessage = "Enter an ANSI escape sequence to color the text." )]
		[string]$ANSIText
	)

	Begin {
		Write-Detail "Starting $($myinvocation.mycommand)" -Prefix begin | Write-Verbose
		$tabs = "`t" * $tab
		Write-Detail "Using a tab of $tab" -Prefix BEGIN | Write-Verbose

		Write-Detail "Using border character $Character" -Prefix begin | Write-Verbose
		$ansiClear = "$([char]0x1b)[0m"
		if ($PSBoundParameters.ContainsKey("ANSIBorder")) {
			Write-Detail "Using an ANSI border Color" -Prefix Begin | Write-Verbose
			$Character = "{0}{1}{2}" -f $PSBoundParameters.ANSIBorder, $Character, $ansiClear
		}

		#define regex expressions to detect ANSI escapes. Need to subtract their
		#length from the string if used. Issue #79
		[regex]$ansiopen = "$([char]0x1b)\[\d+[\d;]+m"
		[regex]$ansiend = "$([char]0x1b)\[0m"

	} #begin

	Process {

		if ($pscmdlet.ParameterSetName -eq 'single') {
			Write-Detail "Processing '$text'" -Prefix PROCESS | Write-Verbose
			#get length of text
			$adjust = 0
			if ($ansiopen.IsMatch($text)) {
				$adjust += ($ansiopen.matches($text) | Measure-Object length -sum).sum
				$adjust += ($ansiend.matches($text) | Measure-Object length -sum).sum
				Write-Detail "Adjusting text length by $adjust." -Prefix PROCESS | Write-Verbose
			}

			$len = $text.Length - $adjust
			if ($PSBoundParameters.ContainsKey("ANSIText")) {
				Write-Detail "Using an ANSIText color" -Prefix PROCESS | Write-Verbose
				$text = "{0}{1}{2}" -f $PSBoundParameters.ANSIText, $text, $AnsiClear
			}
		}
		else {
			Write-Detail "Processing text block" -Prefix PROCESS | Write-Verbose
			#test if text block is already using ANSI
			if ($ansiopen.IsMatch($TextBlock)) {
				Write-Detail "Text block contains ANSI sequences" -Prefix PROCESS | Write-Verbose
				$txtarray | ForEach-Object -begin { $tempLen = @() } -process {
					$adjust = 0
					$adjust += ($ansiopen.matches($_) | Measure-Object length -sum).sum
					$adjust += ($ansiend.matches($_) | Measure-Object length -sum).sum
					Write-Detail "Length detected as $($_.length)" -Prefix PROCESS | Write-Verbose
					Write-Detail "Adding adjustment $adjust" -Prefix PROCESS | Write-Verbose
					$tempLen += $_.length - $adjust
				}
				$len = $tempLen | Sort-Object -Descending | Select-Object -first 1

			}
			elseif ($PSBoundparameters.ContainsKey("ANSIText")) {
				Write-Detail "Using ANSIText for the block" -prefix PROCESS | Write-Verbose
				$txtarray = $textblock.split("`n").Trim() | ForEach-Object { "{0}{1}{2}" -f $PSBoundParameters.ANSIText, $_, $AnsiClear }
				$len = ($txtarray | Sort-Object -property length -Descending | Select-Object -first 1 -expandProperty length) - ($psboundparameters.ANSIText.length + 4)
			}
			else {
				Write-Detail "Processing simple text block" -prefix PROCESS | Write-Verbose
				$txtarray = $textblock.split("`n").Trim()
				$len = $txtarray | Sort-Object -property length -Descending | Select-Object -first 1 -expandProperty length
			}
			Write-Detail "Added $($txtarray.count) text block elements" -Prefix PROCESS | Write-Verbose
		}

		Write-Detail "Using a length of $len" -Prefix PROCESS | Write-Verbose
		#define a horizontal line
		$hzline = $Character * ($len + 4)

		if ($pscmdlet.ParameterSetName -eq 'single') {
			Write-Detail "Defining Single body" -prefix PROCESS | Write-Verbose
			$body = "$tabs$Character $text $Character"
		}
		else {
			Write-Detail "Defining Textblock body" -prefix PROCESS | Write-Verbose
			[string[]]$body = $null
			foreach ($item in $txtarray) {
				if ($item) {
					Write-Detail "$item [$($item.length)]" -Prefix PROCESS | Write-Verbose
				}
				else {
					Write-Detail "detected blank line" -Prefix PROCESS | Write-Verbose
				}
				if ($ansiopen.IsMatch($item)) {
					$adjust = $len
					$adjust += ($ansiopen.matches($item) | Measure-Object length -sum).sum
					$adjust += ($ansiend.matches($item) | Measure-Object length -sum).sum
					Write-Detail "Adjusting length to $adjust" -prefix PROCESS | Write-Verbose
					$body += "$tabs$Character $(($item).PadRight($adjust)) $Character`r"

				}
				elseif ($PSBoundparameters.ContainsKey("ANSIText")) {
					#adjust the padding length to take the ANSI value into account
					$adjust = $len + ($psboundparameters.ANSIText.length + 4)
					Write-Detail "Adjusting length to $adjust" -prefix PROCESS | Write-Verbose

					$body += "$tabs$Character $(($item).PadRight($adjust)) $Character`r"
				}
				else {
					$body += "$tabs$Character $(($item).PadRight($len)) $Character`r"
				}
			} #foreach item in txtarray
		}
		Write-Detail "Defining top border" -Prefix PROCESS | Write-Verbose
		[string[]]$out = "`n$tabs$hzline"
		$lines = $body.split("`n")
		Write-Detail "Adding $($lines.count) lines" | Write-Verbose
		if ($InsertBlanks) {
			Write-Detail "Prepending blank line" -Prefix PROCESS | Write-Verbose
			$out += "$tabs$character $((" ")*$len) $character"
		}
		foreach ($item in $lines ) {
			$out += $item
		}
		if ($InsertBlanks) {
			Write-Detail "Appending blank line" -Prefix PROCESS | Write-Verbose
			$out += "$tabs$character $((" ")*$len) $character"
		}
		Write-Detail "Defining bottom border" -Prefix PROCESS | Write-Verbose
		$out += "$tabs$hzline"
		#write the result to the pipeline
		$out
	} #process

	End {
		Write-Detail "Ending $($myinvocation.mycommand)" -prefix END | Write-Verbose
	} #end

}

## Funktion von jdhitsolutions
#
# Erzeugt eine Textbox
Function Add-Border-Text([String[]]$TextZeilen, [Int]$Tab) {
	$AnsiEsc =  "$([char] 27)" + "["
	Add-Border -TextBlock $TextZeilen -Character '*' -ANSIText ($AnsiEsc + '91m') -Tab $Tab -ANSIBorder ($AnsiEsc + '93m')
}


#EndRegion Add-Border-Text


## Prepare: Start Elevated
# 221205

# True, wenn Elevated
# !Sj Autostart Shell elevated
# 220813
Function Is-Elevated() {
	([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}


# !Sj Autostart Shell elevated
# 221205
If (!(Is-Elevated)) {

	Write-Host "`n`n"
	Add-Border-Text -Tab 2 -TextZeilen @(	'Starte das Script als Administrator (elevated)'
														'Bitte den folgenden Dialog mit ''JA'' bestätigen')
	Write-Host "`n`n"

	# Wait-For-UserInput 'Alle Daten gespeichert?' 'Kann BitLocker gestartet werden?' @('&Yes', '&Ja', '&No', '&Nein') 'Ja'
	# Write-Host ">> starte PowerShell als Administrator (Elevated)`n`n" -ForegroundColor Red

	Start-Sleep -Seconds 5

	$UriHttp = @('http', 'https')
	## Das Script ist per http(s) abrufbar
	If ($UriHttp -contains ([URI]$ThisScriptPermaLink).Scheme) {

		$Command = "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-Expression -Command (Invoke-RestMethod -Uri `"$ThisScriptPermaLink`")"

		If ($NoExit) {
			Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -Command $Command"
		} Else {
			Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command $Command"
		}
	}
	Else {
		## Das Script ist lokal / auf einem Netzwerkshare
		If ($NoExit) {
			Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -File $ThisScriptPermaLink"
		} Else {
			Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File $ThisScriptPermaLink"
		}
	}

	# Exit from the current, unelevated, process
	Start-Sleep -MilliS 2500
	Exit

} Else {
	$Host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Definition + ' (Elevated)'
	$Host.UI.RawUI.BackgroundColor = 'DarkBlue'

	If ($Silent -eq $false) { Clear-Host }
	Log 0 'Analysiere das System für BitLocker'
	Log 1 "Version: $Version" -ForegroundColor DarkGray
	Log 1 "Rückmeldungen bitte an: $Feedback" -ForegroundColor DarkGray
}


# Assert is elevated
If ( (Is-Elevated) -eq $False) {
	Write-Host "`nDas Script muss als Administrator / Elevated ausgeführt werden" -ForegroundColor Red
	Start-Sleep -MilliS 3500
	Write-Host -NoNewLine "`nPress any key to continue…" -ForegroundColor Green
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	Return
}



### Prepare


## Die Daten sammeln
Log 1 'Start der Analyse' -ForegroundColor DarkGray

$Timestamp = Get-Date -f 'yyMMdd-HHmm'

$BiosType = Get-Bios-Type
$IsUefiSecurebootEnabled = Is-UefiSecureboot-Enabled

# Testen, ob das TPM Modul bereit ist
#	!M https://learn.microsoft.com/de-de/powershell/module/trustedplatformmodule/get-tpm?view=windowsserver2022-ps
$IsTPMReady = Is-TPM-Ready
$TpmData = Get-Tpm

$AllDrivesBitlockerStatus = Get-Bitlocker-DriveStatus
$HasAnyFixedDiskBitlockerActive = Has-AnyFixedDisk-BitlockerActive
# Systemlaufwerk
$HasSystemDriveBitlockerActive = Has-SystemDrive-BitlockerActive
$HasSystemDriveBitlockerHWTestPending = ((Get-Bitlocker-HWTestPending-State ($Env:SystemDrive.Trim())) -eq ([eBitlockerHWTestPendingState]::TestPending))

$NoOfDataDrives = Get-NoOf-DataDrives
$HasDataDrives = $NoOfDataDrives -gt 0
$HasAllDataDriveBitlockerActive = Has-AllDataDrive-BitlockerActive



#### Main

# Das Resultat zusammenstellen
$ResStatus = [PSCustomObject][Ordered]@{
	Timestamp						= $Timestamp
	ComputerName					= $Env:ComputerName
	UserName						= $Env:UserName
	# Alle lokalen Laufwerke sind verschlüsselt
	BitlockerAllOK              	= $HasSystemDriveBitlockerActive -and $HasAllDataDriveBitlockerActive
	SysDrvBitlockerActive   		= $HasSystemDriveBitlockerActive
	SysDrvBitlockerHWTestPending 	= $HasSystemDriveBitlockerHWTestPending
	HasDataDrives					= $HasDataDrives
	AllDataDrvsBitlockerActive 		= $HasAllDataDriveBitlockerActive
	BIOS                        	= $BiosType
	TPMReady                    	= $IsTPMReady
	SecureBootEnabled           	= $IsUefiSecurebootEnabled
}


## Das Logfile schreiben?
If ([String]::IsNullOrEmpty($WriteLogToDir) -eq $False) {
	# Allenfalls versuchen, das Verzeichnis zu erstellen
	If ((Test-Path -LiteralPath $WriteLogToDir -PathType Container) -eq $False) {
		New-Item -Path $WriteLogToDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	}
	# Konnte das Verzeichnis erstellt werden?
	If (Test-Path -LiteralPath $WriteLogToDir -PathType Container) {
		# Logfile Namen berechnen
		$Filename = 'BitLocker-Status - {0} {1} {2}.txt' -f $Timestamp, $Env:UserName, $Env:ComputerName
		$LogFile = Join-Path $WriteLogToDir $FileName
		Log 0 "Erzeuge Logfile: $LogFile" -ForegroundColor DarkGray
		'Bitlocker Prerequisites-Status:' | Out-File $LogFile
		If ($ResStatus.BitlockerAllOK) {
			'  ✅ Alles OK: Das System- und alle Daten-Laufwerke sind mit Bitlocker verschlüsselt' | Out-File $LogFile -Append
		} Else {
			'  ❌ Nicht alles OK: Das System- und alle Daten-Laufwerke sind mit Bitlocker verschlüsselt' | Out-File $LogFile -Append
		}
		If ($ResStatus.SysDrvBitlockerActive) {
			'  ✅ Systemlaufwerk ist verschlüsselt' | Out-File $LogFile -Append
		} Else {
			If ($ResStatus.SysDrvBitlockerHWTestPending) {
				'  ❓ Systemlaufwerk: HW-Test pending' | Out-File $LogFile -Append
			} Else {
				'  ❌ Systemlaufwerk ist nicht verschlüsselt' | Out-File $LogFile -Append
			}
		}
		If ($ResStatus.AllDataDrvsBitlockerActive) {
			'  ✅ Alle Datenlaufwerke sind verschlüsselt' | Out-File $LogFile -Append
		} Else {
			'  ❌ Nicht alle Datenlaufwerke sind verschlüsselt' | Out-File $LogFile -Append
		}
		$ResStatus | Out-File $LogFile -Append
	} Else {
		# Konnte das Logverzeichnis nicht erstellen
		Log 0 "`nKann das Verzeichnis nicht finden:`n$($WriteLogToDir)" -ForegroundColor Red
	}
}


## Infos ausgeben
Log 0 'BitLocker-Informationen' -ForegroundColor Yellow


## Überprüfen Sie den BitLocker-Status auf jedem Laufwerk, das Sie verschlüsseln möchten
# 	Es ist nicht empfohlen, BitLocker für ein bereits verschlüsseltes Laufwerk zu aktivieren,

If ($HasSystemDriveBitlockerActive -and $HasAllDataDriveBitlockerActive) {
	Log 1 '  Alle Laufwerke sind bereits mit BitLocker verschlüsselt' -ForegroundColor Green
	# Return [eBitlockerCheckState]::AllLocalDrivesEncrypted

	# Allenfalls das Control Panel öffnen
	If ($OpenBitlockerControlPanel) { Open-BitlockerControlPanel }

	## Wir sind fertig
	If ($Silent) { Return } Else { Return $ResStatus }
}


### Bitlocker noch nicht komplett aktiv

$Col1Width = 17

## BIOS
Switch ($BiosType) {
	([eBiosType]::UEFI) {
		Log 1 ("{0,-$Col1Width}: {1}" -f 'BIOS', 'UEFI') -ForegroundColor Green
	}
	([eBiosType]::Legacy) {
		Log 1 ("{0,-$Col1Width}: {1}" -f 'BIOS', 'Legacy') -ForegroundColor Red
	}
}


## TPM
If ($IsTPMReady) {
	Log 1 ("{0,-$Col1Width}: {1}" -f 'TPM', 'Bereit') -ForegroundColor Green
}
Else {
	Log 1 ("{0,-$Col1Width}: {1}" -f 'TPM', 'Nicht bereit') -ForegroundColor Red
}


## Systemlaufwerk
$ResCheck = @()
If ($HasSystemDriveBitlockerActive) {
	# $ResCheck += [eBitlockerCheckState]::AllLocalDrivesEncrypted
	Log 1 ("{0,-$Col1Width}: {1}" -f 'System-Laufwerk', 'Mit BitLocker geschützt') -ForegroundColor Green
} Else {
	If ($HasSystemDriveBitlockerHWTestPending) {
		Log 1 ("{0,-$Col1Width}: {1}" -f 'System-Laufwerk', 'HW-Test pending') -ForegroundColor Cyan -BackgroundColor Red
	} Else {
		Log 1 ("{0,-$Col1Width}: {1}" -f 'System-Laufwerk', 'Nicht mit BitLocker geschützt') -ForegroundColor Red
	}
}


## Datenlaufwerke
If ($HasDataDrives) {
	If ($HasAllDataDriveBitlockerActive) {
		Log 1 ("{0,-$Col1Width}: {1}" -f 'Daten-Laufwerke', 'Mit BitLocker geschützt') -ForegroundColor Green
	} Else {
		Log 1 ("{0,-$Col1Width}: {1}" -f 'Daten-Laufwerke', 'Nicht mit BitLocker geschützt') -ForegroundColor Red
	}
} Else {
	Log 1 ("{0,-$Col1Width}: {1}" -f 'Daten-Laufwerke', 'Hat keine Datenlauferke') -ForegroundColor Green
}


## Secure Boot
If ($IsUefiSecurebootEnabled) {
	Log 1 ("{0,-$Col1Width}: {1}" -f 'Secure Boot', 'Aktiv (nicht relevant für Bitlocker)') -ForegroundColor Cyan
}
Else {
	Log 1 ("{0,-$Col1Width}: {1}" -f 'Secure Boot', 'Nicht aktiv (nicht relevant für Bitlocker)') -ForegroundColor Cyan
}

# Allenfalls das Control Panel öffnen
If ($OpenBitlockerControlPanel) { Open-BitlockerControlPanel }

## Wir sind fertig
If ($Silent) { Return } Else { Return $ResStatus }

