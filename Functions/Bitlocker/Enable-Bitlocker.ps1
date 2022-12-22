# Aktiviert BitLocker auf allen festen Partitionen
#
# Der Prozess ist zweistufig:
#	1a. Das Systemlaufwerk wird verschlüsselt
#	1b. Allenfalls wird das System neu gestartet
#	2.  Wenn vorhanden: alle Daten-Partitionen werden verschlüsselt
#
#
# !TT
# 	# Bitlocker-Status im Detail
#	# Liefert auch die genützte Verschlüsselung
# 	manage-bde.exe -status


# 001, 221202, Tom@jig.ch
# 002, 221205
# 003, 221205
# 004, 221205
# 	Start elevated
# 005, 221205
# 006, 221212
#	Logfile erzeugen
# 007, 221213
#	Bei HWTest pending wird nach dem Neustart das Script nochmals gestartet um die Inventar-Info zu generieren


[CmdLetBinding()]
Param(
	# Wenn True, dann wird der BitLocker Key im AD gesichert,
	# wenn der Computer das AD erreichen kann
	[Switch]$ForceBackupBitLockerKey,
	# Schreibt ins netlogon Inventar
	[Switch]$CreateInventarLog = $True,
	# Die elevated Shell nicht schliessen
	[Switch]$NoExit
)

$Version = '006, 221212'


## Pre-Conditions: PowerShell Version 5
# !Sj Autostart Shell elevated
If ($PSVersionTable.PSVersion.Major -gt 5) {
	Write-Host "`nDieses Script muss in PowerShell 5 gestartet werden" -ForegroundColor Red
	Start-Sleep -MilliS 10000
	Write-Host -NoNewLine "`nPress any key to continue…" -ForegroundColor Green
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	Return
}



### Config

$InventarLogDir = '\\akros.ch\sysvol\akros.ch\scripts\Inventar\Inventarfiles\'
$TestBitlockerPrerequisites_ps1 = 'Test-Bitlocker-Prerequisites.ps1'


If ($null -eq $MyInvocation.MyCommand.Path) {
	$ScriptDir = Get-Location
}
Else {
	$ScriptDir = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}

# Der Domänen-Namen des Computers, auf dem das Script läuft
$DomainName = $env:UserDnsDomain

# Test-IP-Adressen pro Domäne, um zu testen, ob der DC erreichbar ist
$DcIpV4Addresses =  @{
	'akros.ch' = '10.7.0.4'
}


## Auto-Config
$ScriptName = $MyInvocation.MyCommand.Source

# elevated
$Feedback = 'Rückmeldungen bitte an: schittli@akros.ch'

# Perma Link zum eigenen Script
# !Sj Autostart Shell elevated
$ThisScriptPermaLink = $ScriptName



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



#Region Add-Border-Text


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


# Add a border around a string of text
#
# !M		https://github.com/jdhitsolutions/PSScriptTools/blob/master/docs/Add-Border.md
# !Src	https://github.com/jdhitsolutions/PSScriptTools/blob/master/functions/Add-Border.ps1
#
# Ansi Color Codes
# #https://ss64.com/nt/syntax-ansi.html
# 221213
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
		# TomTom: Object[] und nicht String[], sinst können keine Leerzeilen übergeben werden
		# [ValidateNotNullOrEmpty()]
		[Alias("tb")]
		[Object[]]$TextBlock,

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


# Erzeugt eine Textbox
Function Add-Border-Text([String[]]$TextZeilen, [Int]$Tab) {
	$AnsiEsc =  "$([char] 27)" + "["
	Add-Border -TextBlock $TextZeilen -Character '*' -ANSIText ($AnsiEsc + '91m') -Tab $Tab -ANSIBorder ($AnsiEsc + '93m')
}

#EndRegion Add-Border-Text


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



# Liefert die Anzal Objekte, $null == 0
Function Count($Obj) {
   ($Obj | measure).Count
}


# Liefert True, wenn -DcIpV4Address Privat ist
Function Is-Private-IPv4-Address {
	Param(
		[Alias('IP', 'IPv4', 'IP4Address')]
		[Parameter(Mandatory,ValueFromPipeline)][String]$DcIpV4Address
	)
	Process {
		Return $DcIpV4Address -Match '(^127\.)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)'
	}
}


# Liefert true, wenn der Rechner die Domäne via privates Subnetz erreichen kann
# Is-Domain-InLan 'akros.ch'
Function Is-Domain-InLan($DomainName) {
	$IP4Address = Resolve-DnsName $DomainName | select -First 1 -ExpandProperty IP4Address
	Is-Private-IPv4-Address -DcIpV4Address $IP4Address
}


# Ein schnelles Ping
# 220127
Function Test-Connection-Fast {
	<#
	.DESCRIPTION
		Test-ComputerConnection sends a ping to the specified computer or IP Address specified in the ComputerName parameter. Leverages the System.Net object for ping
		and measures out multiple seconds faster than Test-Connection -Count 1 -Quiet.
	.PARAMETER ComputerName
		The name or IP Address of the computer to ping.
	.EXAMPLE
		Test-ComputerConnection -ComputerName "THATPC"
		Tests if THATPC is online and returns a custom object to the pipeline.
	.EXAMPLE
		$MachineState = Import-CSV .\computers.csv | Test-ComputerConnection -Verbose

		Test each computer listed under a header of ComputerName, MachineName, CN, or Device Name in computers.csv and
		and stores the results in the $MachineState variable.
	.NOTES
		001, 220127
	#>
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelinebyPropertyName)]
		[Alias('CN', 'MachineName', 'Device Name')]
		[String]$ComputerName,
		[Int]$TimeoutMs = 500,
		[Int]$NoOfPings = 5,
		# Versucht stilldie Pings und bricht bei Erfolg ab
		[Switch]$TestForSuccess,
		# Maximum number of times the ICMP echo message can be forwarded before reaching its destination.
		# Results in: TtlExpired
		# Range is 1-255. Default is 64
		[Int]$TTL = 64,
		# Buffer used with this command. Default 32
		[Int]$Buffersize = 32,
		# Wenn true und das Paket ist für einen Router oder gateway zum Host
		# grösser als die MTU: Status: PacketTooBig
		[Switch]$DontFragment = $false,
		[Switch]$PassThru
	)

	Begin {
		$options = New-Object System.Net.Networkinformation.PingOptions
		$options.TTL = $TTL
		$options.DontFragment = $DontFragment
		$buffer = ([System.Text.Encoding]::ASCII).getbytes('a' * $Buffersize)
		$ping = New-Object System.Net.NetworkInformation.Ping

		# mind. 1 Ping
		$NoOfPings = [Math]::Max($NoOfPings, 1)
		$DestinationReachedOnce = $False
		$ResPing = @()
	}

	Process {
		For ($Cnt = 0; $Cnt -lt $NoOfPings; $Cnt++) {
			Try {
				$reply = $ping.Send($ComputerName, $TimeoutMs, $buffer, $options)
			}
			Catch {
				$ErrorMessage = $_.Exception.Message
				Write-Host ($_ | Out-String)
				$Res = [PSCustomObject][Ordered]@{
					Message      = ($_.ToString())
					ComputerName = $ComputerName
					Success      = $False
					Timeout      = $True
					Status       = $ErrorMessage
				}
			}
			If ($reply.status -eq 'Success') {
				$Res = @{
					ComputerName = $ComputerName
					Success      = $True
					Timeout      = $False
					Status       = $reply.status
				}
			}
			Else {
				$Res = [PSCustomObject][Ordered]@{
					ComputerName = $ComputerName
					Success      = $False
					Timeout      = $True
					Status       = $reply.status
				}
			}
			If ($Res.Success) { $DestinationReachedOnce = $True }

			If ($TestForSuccess) {
				# Die Resultate sammeln
				$ResPing += $Res
				# Bei Erfolg stoppen
				If ($DestinationReachedOnce) {
					If ($PassThru) {
						Return $ResPing
					}
					Else {
						Return $True
					}
				}
			}
			Else {
				If ($PassThru) {
					$Res
				}
				Else {
					$Res.Success
				}
			}
		}
		If ($TestForSuccess) {
			If ($PassThru) {
				Return $ResPing
			}
			Else {
				Return $DestinationReachedOnce
			}
		}
	}
	End {}
}


# Liefert $True, wenn die Domäne via LAN / VPN erreichbar ist
Function Is-Domain-Reachable() {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		# e.g. Akros.ch
		[String]$DomainName,
		[Parameter(Mandatory)]
		# e.g. 10.7.0.4
		[String]$DcIpV4Address
	)

	If (Is-Domain-InLan $DomainName) {
		Return Test-Connection-Fast -ComputerName $DcIpV4Address -TimeoutMs 1500 -NoOfPings 1 -TestForSuccess
	} Else {
		# Die Domäne ist nicht im LAN / VPN
		Return $False
	}
}


# Prüft, ob die Domäne erreichbar ist und bittet den Benutzer allenfalls, das VPN zu starten
Function WaitFor-Domain-Reachable() {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		# e.g. Akros.ch
		[String]$DomainName,
		[Parameter(Mandatory)]
		# e.g. 10.7.0.4
		[String]$DcIpV4Address
	)

	## Config
	$TestDelaySec = 10

	$LoopCnt = 0
	Do {
		$IsReachable = Is-Domain-Reachable -DomainName $DomainName -DcIpV4Address $DcIpV4Address
		If ($IsReachable -eq $false) {
			If ($LoopCnt -eq 0) {
				Write-Host ("Bitte mit dem LAN oder VPN verbinden (Domäne {0} / {1} nicht erreichbar)" -f $DomainName, $DcIpV4Address) -ForegroundColor Red
			}
			$LoopCnt++
			Write-Host ("`r  Teste neu in {0}s (Test: {1})" -f $TestDelaySec, $LoopCnt) -NoNewline
			Start-Sleep -Seconds $TestDelaySec
		}
	} While ($IsReachable -eq $false)
	If ($LoopCnt -gt 0) {
		Write-Host ("`n  Domäne ist erreichbar: {0} / {1}" -f $DomainName, $DcIpV4Address, $TestDelaySec) -ForegroundColor Green
	}

	Return (Is-Domain-Reachable -DomainName $DomainName -DcIpV4Address $DcIpV4Address)
}



# Liste aller lokalen, fest eingebundenen Laufwerke
Function Get-LocalFixedDrive-Letters() {
	Get-WmiObject Win32_LogicalDisk | `
		? {$_.driveType -eq 3 } | `
		Select -ExpandProperty DeviceID
}


# Versucht, den TPM KeyProtector vom Laufwerk C: zu lesen
Function Get-TPM-OnC() {
	Get-BitLockerVolume -MountPoint c: | `
					Select -ExpandProperty KeyProtector | `
					? {$_.KeyProtectorType -eq 'TPM' }
}


# Aktiviert allenfalls auf C: den TPM KeyProtector
# Liefert $True, wenn auf C: TPM KeyProtector aktiviert ist
Function Assert-TPM-OnC() {
	Write-Host 'Teste TPM auf dem Laufwerk C:' -ForegroundColor Yellow
	If ( (Get-TPM-OnC) -eq $Null) {
		Write-Host '  Aktiviere TPM auf dem Laufwerk C:' -ForegroundColor Green
		# !TT
		#	Nur das Betriebssystemvolume darf mit dem TPM geschützt werden
		# 	Löschen:
		#		manage-bde.exe -Protectors -delete c:
		$Null = manage-bde.exe -Protectors -Add -TPM c:
		# Wenn TPM nicht aktiviert werden konnte
		If ( $Null -eq (Get-TPM-OnC)) {
			Write-Host '  Konnte TPM nicht aktivieren!' -ForegroundColor Red
			Return $False
		}
	}
	Return $True
}



# Liefert von allen lokalen, festen Partitionen die Laufwerkbuchstaben
# und den Status der Diskverschlüsselung
Function Get-FixedDrive-BitlockerState() {
	$LocalDrives = Get-LocalFixedDrive-Letters
	$ResUncryptedFixedDriveLetters = @()
	$LocalDrives | % {
		$DriveLetter = $_
		## Den Bitlocker-Status des Volumes bestimmen
		$BitLockerVolumeStatus = Get-BitLockerVolume -MountPoint $DriveLetter
		# On, Off
		$ProtectionStatus = $BitLockerVolumeStatus.ProtectionStatus
		# FullyEncrypted, EncryptionInProgress
		$VolumeStatus = $BitLockerVolumeStatus.VolumeStatus
		$VolumeIsEncrypted = $False
		If ($ProtectionStatus -ne 'Off') {
			$VolumeIsEncrypted = $True
		} Else {
			$IsEncryptedVolumeStatus = @('FullyEncrypted', 'EncryptionInProgress')
			$VolumeIsEncrypted = $IsEncryptedVolumeStatus -contains $VolumeStatus
		}

		$ResUncryptedFixedDriveLetters += [PSCustomObject][Ordered]@{
			DriveLetter = $DriveLetter
			IsSystemDrive = ($DriveLetter.Trim() -eq $Env:SystemDrive.Trim())
			IsEncrypted = $VolumeIsEncrypted
		}
	}
	$ResUncryptedFixedDriveLetters
}


# Aktiviert Bitlocker auf allen angegebenen Laufwerken
# Wenn -DriveLetters $Null ist,
#	dann	wird Bitlocker auf allen festen, lokalen Laufwerken aktiviert
#
# Stellt sicher, dass am Ende alle BitLocker-Laufwerke AutoUnlock aktiv haben,
# damit die User diese Laufwerke nicht von Hand 'unlocken' müssen
Function Enable-BitLocker-OnAllFixedDrives() {
	Param(
		# Optional
		[String[]]$DriveLetters
	)

	Write-Host "`nAktiviere Bitlocker" -ForegroundColor Yellow
	# Write-Host "Drive Letters: $($DriveLetters -join ', ')"

	# Allenfalls die Laufwerkliste holen
	If ($Null -eq $DriveLetters) {
		# Liste aller lokalen, fest eingebundenen Laufwerke
		$DriveLetters = Get-LocalFixedDrive-Letters
	}


	## !KH Welche Verschlüsselung?
	# Grundlagenwissen
	# !KH9 https://www.ubiqsecurity.com/128bit-or-256bit-encryption-which-to-use/
	#
	# Vorsichtige Empfehlung
	# https://www.tenable.com/audits/items/CIS_MS_Windows_10_Enterprise_Bitlocker_v1.6.1.audit:8feb085ceb2ee2dbbe2ffa348bc444d8

	# BitLocker auf allen Laufwerken aktivieren
	# und das recovery password generieren
	ForEach($DriveLetter in $DriveLetters) {
		Write-Host ('  Laufwerk: {0}' -f $DriveLetter)
		# PS ist extrem verbose
		# $Res = Enable-BitLocker -MountPoint $DriveLetter -EncryptionMethod XtsAes128 -RecoveryPasswordProtector
		$Res = manage-bde -on $DriveLetter -RecoveryPassword -EncryptionMethod xts_aes128
	}

	# Kurz warten
	Start-Sleep -Milliseconds 2500
}


# Auf allen Bitlocker-Laufwerken AutoUnlock aktivieren
# Ist für die Datenlaufwerke nötig
Function Enable-BitLocker-AutoUnlock() {
	Write-Host "`nAktiviere AutoUnlock" -ForegroundColor Yellow
	# Nur C: wird per default automatisch 'unlocked'
	# Auch die anderen Laufwerke 'autounlocken'
	Get-BitLockerVolume | ? { $_.AutoUnlockEnabled -eq $false } | % {
		Write-Host ('  Laufwerk: {0}' -f $_.MountPoint )
		$ResManageBde = manage-bde -autounlock -enable $_.MountPoint
		$HasErr = ($ResManageBde -join ' ') -like '*(Code 0x*'
		If ($HasErr) {
			Write-Host ('  Konnte AutoUnlock für Laufkwerk {0} nicht aktivieren!' -f $_.MountPoint) -ForegroundColor Red
		}
	}
}


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


# Speichert alle Bitlocker-Keys im AD
Function Save-BitLockerKeys-ToAD() {
	# Vom jedem Laufwerk mit RecoveryPassword lesen
	$BitLockerRecoveryPasswords = Get-BitLockerVolume | `
		? { $_.KeyProtector.KeyProtectorType -eq 'RecoveryPassword'} | `
		Select-Object MountPoint, `
			@{ N='KeyProtectorId'; Ex={ $_.KeyProtector | ? KeyProtectorType -eq 'RecoveryPassword' | Select -ExpandProperty KeyProtectorId }}

	# Alle Laufwerk RecoveryPasswords ins AD sichern
	$BitLockerRecoveryPasswords | % {
		$ThisVolumeBitLockerRecoveryData = $_
		Write-Host ('  Speichere {0}' -f $ThisVolumeBitLockerRecoveryData.MountPoint)
		# Alle KeyProtectorId im AD speichern
		$ThisVolumeBitLockerRecoveryData.KeyProtectorId | % {
			Backup-BitLockerKeyProtector -MountPoint $ThisVolumeBitLockerRecoveryData.MountPoint -KeyProtectorId $_
		}
	}
}


# Liefert True, wenn es DatenDisks zum Verschlüsseln hat
Function Get-BitlockerState-HasDataDisksToEncrypt() {
	# Systemstatus auslesen
	$FixedDriveBitlockerState = @(Get-FixedDrive-BitlockerState | ? IsEncrypted -eq $False)
	$AnzLocalDataDrives = Count ($FixedDriveBitlockerState | ? { $_.IsSystemDrive -eq $False } )
	$AnzDataDrivesAreEncrypted = Count ($FixedDriveBitlockerState | ? { $_.IsSystemDrive -eq $False -and $_.IsEncrypted })
	$AllDataDrivesAreEncrypted = $AnzDataDrivesAreEncrypted -eq $AnzLocalDataDrives
	Return $AllDataDrivesAreEncrypted -eq $False
}


# BitLocker wird in zwei Schritten eingerichtet
# 1a	Systemlaufwerk verschlüsseln
# 1b	Je nach System:
# 2	Zusätzliche lokale Laufwerke verschlüsseln
Enum eBitlockerSetupState {
	UnknownState;
	NoLocalDrivesEncrypted; SystemDriveToEncrypt; OnlySystemDriveIsEncrypted;
	DataDrivesToEncrypt; AllLocalDrivesEncrypted
}
Function Get-Bitlocker-SetupState() {
	## Systemstatus auslesen
	$FixedDriveBitlockerState = Get-FixedDrive-BitlockerState

	## Prozess-Status berechnen
	$IsSystemDriveEncrypted = $FixedDriveBitlockerState | ? IsSystemDrive | Select -ExpandProperty IsEncrypted

	$AnzLocalDrives = Count ($FixedDriveBitlockerState)
	$AnzLocalDataDrives = Count ($FixedDriveBitlockerState | ? { $_.IsSystemDrive -eq $False} )
	$HasLocalDataDrives = $AnzLocalDataDrives -gt 0

	$AnzDataDrivesAreEncrypted = Count ($FixedDriveBitlockerState | ? { $_.IsSystemDrive -eq $False -and $_.IsEncrypted })
	$AnzDataDrivesNotEncrypted = Count ($FixedDriveBitlockerState | ? { $_.IsSystemDrive -eq $False -and $_.IsEncrypted -eq $False })

	$NoDataDrivesAreEncrypted = $AnzDataDrivesAreEncrypted -eq 0
	$AllDataDrivesAreEncrypted = $AnzDataDrivesAreEncrypted -eq $AnzLocalDataDrives

	$UnencryptedDataDrives = $FixedDriveBitlockerState | ? { $_.IsSystemDrive -eq $False -and $_.IsEncrypted -eq $False }


	If (($FixedDriveBitlockerState | ? IsEncrypted).Count -eq 0) {
		If ($HasLocalDataDrives) {
			Return [eBitlockerSetupState]::NoLocalDrivesEncrypted
		} Else {
			Return [eBitlockerSetupState]::SystemDriveToEncrypt
		}
	}

	If ($IsSystemDriveEncrypted -eq $False) {
		Return [eBitlockerSetupState]::SystemDriveToEncrypt
	}

	If ($IsSystemDriveEncrypted -and $NoDataDrivesAreEncrypted) {
		If ($HasLocalDataDrives) {
			Return [eBitlockerSetupState]::OnlySystemDriveIsEncrypted
		} Else {
			Return [eBitlockerSetupState]::AllLocalDrivesEncrypted
		}
	}

	If ($HasLocalDataDrives -and $AllDataDrivesAreEncrypted -eq $false) {
		Return [eBitlockerSetupState]::DataDrivesToEncrypt
	}

	If (($FixedDriveBitlockerState | ? IsEncrypted).Count -eq $AnzLocalDrives) {
		Return [eBitlockerSetupState]::AllLocalDrivesEncrypted
	}

	Write-Error 'Unbekannter Status der aktuellen Disk-Verschlüsselung'
}

# Zeigt dem User den aktuellen Bitlocker-Status an
Function Show-Bitlocker-Status() {
	Param(
		[eBitlockerSetupState]$BitlockerStatus,
		[Int]$Ident = 1,
		[Switch]$ShowHeader
	)

	If ($ShowHeader) {
		Log $Ident 'Aktueller Bitlocker-Status'
		$StatusIdent = $Ident+1
	} Else {
		$StatusIdent = $Ident
	}
	Switch ($BitlockerStatus) {
		([eBitlockerSetupState]::UnknownState) {
			Log $StatusIdent 'Fehler: Unbekannt' -ForegroundColor Red
		}
		([eBitlockerSetupState]::NoLocalDrivesEncrypted) {
			Log $StatusIdent 'Pendent: System-Laufwerk mit Bitlocker verschlüsseln' -ForegroundColor White
			Log $StatusIdent 'Pendent: Alle Daten-Laufwerke mit Bitlocker verschlüsseln' -ForegroundColor White
		}
		([eBitlockerSetupState]::SystemDriveToEncrypt) {
			Log $StatusIdent 'Pendent: System-Laufwerk mit Bitlocker verschlüsseln' -ForegroundColor White
			Log $StatusIdent ' Unklar: Alle Daten-Laufwerke sind mit Bitlocker verschlüsselt' -ForegroundColor White
		}
		([eBitlockerSetupState]::OnlySystemDriveIsEncrypted) {
			Log $StatusIdent '     OK: System-Laufwerk ist mit Bitlocker verschlüsselt' -ForegroundColor Green
			Log $StatusIdent 'Pendent: Alle Daten-Laufwerke mit Bitlocker verschlüsseln' -ForegroundColor White
		}
		([eBitlockerSetupState]::DataDrivesToEncrypt) {
			Log $StatusIdent '     OK: System-Laufwerk ist mit Bitlocker verschlüsselt' -ForegroundColor Green
			Log $StatusIdent 'Pendent: Alle Daten-Laufwerke mit Bitlocker verschlüsseln' -ForegroundColor White
		}
		([eBitlockerSetupState]::AllLocalDrivesEncrypted) {
			Log $StatusIdent '     OK: System-Laufwerk ist mit Bitlocker verschlüsselt' -ForegroundColor Green
			Log $StatusIdent '     OK: Alle Daten-Laufwerke sind mit Bitlocker verschlüsselt' -ForegroundColor Green
		}
	}
	Write-Host ''
}




# Autostart eines Scripts nach dem Login
Function Set-RunOnce() {
	<#
      .SYNOPSIS
      Sets a Runonce-Key in the Computer-Registry. Every Program which will be added will run once at system startup.
      This Command can be used to configure a computer at startup.

		Besser mit KHLM und nicht mit HKCU\RunOnce arbeiten,
 		weil wenn der Script-Kontext temporär z.B. zu nypadmin geändert wird,
 		dann klappt HKCU nicht, weil sich beim nächsten Login ja der MA anmeldet

      .EXAMPLE
      Set-Runonce -command '%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -executionpolicy bypass -file c:\Scripts\start.ps1'

      Sets a Key to run Powershell at startup and execute C:\Scripts\start.ps1

      .NOTES
      Author: Holger Voges
      Version: 1.0
      Date: 2018-08-17

      .LINK
      https://www.netz-weise-it.training/
  #>
	[CmdletBinding()]
	Param (
		#The Name of the Registry Key in the Autorun-Key.
		[String]$KeyName = 'Run',
		#Command to run
		[String]$Command,
		[Switch]$HKLM,
		[Switch]$HKCU
	)

	# Default: HKLM
	If ($HKLM -eq $False -and $HKCU -eq $False) { $HKLM = $True }

	$RegkeyPaths = @()
	If ($HKLM) { $RegkeyPaths += 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce' }
	If ($HKCU) { $RegkeyPaths += 'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce' }

	$RegkeyPaths | % {
		$RegkeyPath = $_
		If (-not ((Get-Item -Path $RegkeyPath).$KeyName )) {
			$Res = New-ItemProperty -Path $RegkeyPath -Name $KeyName -Value $Command -PropertyType ExpandString -Force
		}
		Else {
			$Res = Set-ItemProperty -Path $RegkeyPath -Name $KeyName -Value $Command -PropertyType ExpandString -Force
		}
	}
}


# Neustart des Computers
Function Restart($TimeoutSec = 1) {
	$Cnt = 0
	While ($Cnt -lt $TimeoutSec) {
		Write-Host ('.' * ($TimeoutSec - $Cnt) + ' ' * $TimeoutSec + "`r") -NoNewLine
		Start-Sleep -Seconds 1
		$Cnt++
	}
	Write-Host (" `r`n")
	Restart-Computer
}


## Prepare: Start Elevated
# 221205

# True, wenn Elevated
# !Sj Autostart Shell elevated
# 220813
Function Is-Elevated() {
	([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}


# 221212 Option: $ShowText
Function Show-Countdown($TimeoutSec = 1, [Switch]$ShowText) {
	$Text = 'Es geht automatisch weiter in '
	$Cnt = 0
	While ($Cnt -lt $TimeoutSec) {
		If ($ShowText) {
			# Write-Host ("`rWeiter in $($TimeoutSec - $Cnt)s") -NoNewLine
			Write-Host ("`r$Text$($TimeoutSec - $Cnt)s   ") -NoNewLine
		}
		Else {
			# Pünktchen zeichen
			Write-Host ('.' * ($TimeoutSec - $Cnt) + ' ' * $TimeoutSec + "`r") -NoNewLine
			Write-Host ('.' * ($TimeoutSec - $Cnt) + ' ' * $TimeoutSec + "`r") -NoNewLine
		}
		Start-Sleep -Seconds 1
		$Cnt++
	}
	Write-Host ("`r" + ' ' * ($Text.Length + 5) + "`n")
}


# !Sj Autostart Shell elevated
# 221205
If (!(Is-Elevated)) {

	Write-Host "`n`n"
	Add-Border-Text -Tab 2 -TextZeilen @("Starte das Script als Administrator (elevated)",
										 "Bitte den folgenden Dialog mit 'JA' bestätigen","",
										 "Akros IT / Noser SSF IT",
										 "Version: $Version",
										 "$Feedback")
	Write-Host "`n`n"

	# Wait-For-UserInput 'Alle Daten gespeichert?' 'Kann BitLocker gestartet werden?' @('&Yes', '&Ja', '&No', '&Nein') 'Ja'
	# Write-Host ">> starte PowerShell als Administrator (Elevated)`n`n" -ForegroundColor Red
	Show-Countdown -TimeoutSec 5 -ShowText

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
	Clear-Host
	Log 0 'Pruefe, ob BitLocker aktiviert ist'
	Log 1 "Version: $Version" -ForegroundColor DarkGray
	Log 1 "$Feedback" -ForegroundColor DarkGray
}


# Assert is elevated
If ( (Is-Elevated) -eq $False) {
	Write-Host "`nDas Script muss als Administrator / Elevated ausgeführt werden" -ForegroundColor Red
	Start-Sleep -MilliS 3500
	Write-Host -NoNewLine "`nPress any key to continue…" -ForegroundColor Green
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	Return
}


# Beendet das Script, forciert aber, dass der User die Fehlermeldung sieht
Function Stop-Script-Wait($WaitOnEnd) {
	If ($WaitOnEnd -eq $null -or $WaitOnEnd -eq 0) {
		# 10s warten, wenn nichts definiert ist
		Stop-Script 10
	}
 Else {
		Stop-Script $WaitOnEnd
	}
}


# Stoppt das Script, allenfalls mit einer Benutzerbestätigung, mit einem Timeout oder einem sofortigen Abbruch
# $WaitOnEnd
# 0    Script sofort beenden
# 1    Script nach einer Benutzerbestätigung beenden
# >1   Script nach einem Timeout mit $WaitOnEnd Sekunden beenden
# 200807
Function Stop-Script($WaitOnEnd) {
	If ($WaitOnEnd -eq $Null) { $WaitOnEnd = $Script:WaitOnEnd }

	Switch ($WaitOnEnd) {
		0 {
			# Nichts zu tun, Script beenden
		}
		1 {
			# Pause
			Log 0 'Press any key to continue …'
			Try { $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } Catch {}
		}
		Default {
			# Start-Sleep -Seconds $WaitOnEnd
			Show-Countdown $WaitOnEnd -ShowText
		}
	}
	Break Script
}


# Wartet auf eine Antwort vom Benutzer
# Wait-For-UserInput 'Titel' 'Bist Du bereit?' @('&Yes', '&Ja', '&No', '&Nein') 'Ja'
Function Wait-For-UserInput($Titel, $Msg, $Options, $Default) {
	# Optionen ohne '&'
	$OptionsArrTxt = $Options | % { $_.Replace('&', '') }
	$DefaultIdx = $OptionsArrTxt.indexof($Default)
	$Response = $Host.UI.PromptForChoice($Titel, $Msg, $Options, $DefaultIdx)
	Return $OptionsArrTxt[$Response]
}


## Allenfalls das Status-Logfile schreiben
Function Test-Start-CreateInventar() {
	[CmdletBinding()]
	Param (
		[Switch]$CreateInventarLog,
		[Parameter(Mandatory)][String]$TestBitlockerPrerequisites_ps1,
		[Parameter(Mandatory)][String]$InventarLogDir,
		[Parameter(Mandatory)][String]$DomainName,
		[Parameter(Mandatory)][String]$DcIpV4Address
	)

	# 5s warten, um BitLocker allenfalls etwas Zeit zu geben
	Start-Sleep -Seconds 5

	If ($CreateInventarLog) {
		Log 0 "Erzeuge die Inventar-Informationen" -ForegroundColor Yellow
		If (Test-Path -LiteralPath $TestBitlockerPrerequisites_ps1 -PathType Leaf) {
			If (WaitFor-Domain-Reachable -DomainName $DomainName -DcIpV4Address $DcIpV4Address) {
				. $TestBitlockerPrerequisites_ps1 -WriteLogToDir $InventarLogDir -Silent
			}
		} Else {
			Log 4 'Kann die Inventar-Daten nicht schreiben, das Script fehlt:' -ForegroundColor Red
			Log 4 $TestBitlockerPrerequisites_ps1
			Start-Sleep -Seconds 5
		}
	}
}

Function Get-TempDir() {
	New-TemporaryFile | % { rm $_ -Force -WhatIf:$False; mkdir $_ -WhatIf:$False }
}


# Erzeugt in C:\Temp ein temporäres Verzeichnis für dieses Script
Function Get-CTemp-BitlockerScriptDir() {
	$TmpDir = 'C:\Temp\IT-Bitlocker-PS'
	If (Test-Path -LiteralPath $TmpDir) {
		Remove-Item -LiteralPath $TmpDir -Recurse -Force -EA SilentlyContinue | Out-Null
	}
	New-Item -Path $TmpDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
	Return $TmpDir
}


# Liefert $True, wenn die Pfade identisch sind
Function Are-Path-Identical() {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)][String]$Path1,
		[Parameter(Mandatory)][String]$Path2
	)
	# Sicherstellen, dass die \ vorhanden sind
	$Path1 = (Join-Path ($Path1.Trim()) '\').ToLower()
	$Path2 = (Join-Path ($Path2.Trim()) '\').ToLower()
	$Path1 = [IO.Path]::GetDirectoryName($Path1)
	$Path2 = [IO.Path]::GetDirectoryName($Path2)
	Return $Path1 -eq $Path2
}


# Bei Bedarf werden die Scripts aufs lokale Laufwerk kopiert,
# damit sie nach dem Neustart wieder gestartet werden können
#
# -ScriptDir	Quell-Verzeichnis mit den Scripts
# -Include		Filetypen, die zu kopieren sind, default cmd, ps1
#
# Return
#	Verzeichnis, in das die Scripts kopiert wurden
Function Copy-Script-ToLocalDrive() {
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)][String]$SrcDir,
		[String[]]$Include = @('*.cmd', '*.ps1')
	)

	$SrchPath = Join-Path $SrcDir '*'
	$CTempBitlockerScriptDir = Get-CTemp-BitlockerScriptDir

	# Ist das $ScriptDir schon im gewünschten ZielDir?
	If (Are-Path-Identical $SrcDir $CTempBitlockerScriptDir) {
		Return $SrcDir
	}

	$FilesToCopy = Get-ChildItem -Path $SrchPath -Include $Include
	$FilesToCopy | % { Copy-Item $_ -Destination $CTempBitlockerScriptDir -Force -EA SilentlyContinue }
	Return $CTempBitlockerScriptDir
}


### Prepare

## Die IP-Adresse des DCs
$DcIpV4Address = $DcIpV4Addresses[ $DomainName ]

## Haben wir das Script $TestBitlockerPrerequisites_ps1?
$TestBitlockerPrerequisites_ps1 = Join-Path $ScriptDir $TestBitlockerPrerequisites_ps1

## Ist die Domäne schon erreichbar?
$IsReachable = Is-Domain-Reachable -DomainName $DomainName -DcIpV4Address $DcIpV4Address

## Haben wir unverschlüsselte Laufwerke?

# Den Systemstatus der Disks
$FixedDriveBitlockerState = Get-FixedDrive-BitlockerState

# In welchem Status ist der Aktivierungsprozess für Bitlocker?
$BitlockerSetupState = Get-Bitlocker-SetupState



### Main

Log 0 "Aktueller Bitlocker Setup Status:" -ForegroundColor Yellow
Show-Bitlocker-Status -BitlockerStatus $BitlockerSetupState


If ($BitlockerSetupState -eq [eBitlockerSetupState]::AllLocalDrivesEncrypted) {
	Log 1 'Alle lokalen, festen Laufwerke sind verschlüsselt' -ForegroundColor Green

	## Die BitLockerKeys sichern?
	If ($ForceBackupBitLockerKey) {
		Log 2 'Speichere die Bitlocker-Keys ins AD' -ForegroundColor Yellow

		If (WaitFor-Domain-Reachable -DomainName $DomainName -DcIpV4Address $DcIpV4Address) {
			Save-BitLockerKeys-ToAD
			Log 1 'Erledigt.' -ForegroundColor Green
		} Else {
			Log 4 '  Keine Verbindung zu den Domänen-Controllern' -ForegroundColor Red
			Log 4 '  Kann kein Backup von den Bitlocker-Keys erstellen'
			Log 4 '  > VPN verbinden!' -ForegroundColor Cyan
			Break Script
		}
	}

	## Allenfalls das Status-Logfile schreiben
	Test-Start-CreateInventar -CreateInventarLog:$CreateInventarLog -TestBitlockerPrerequisites_ps1 $TestBitlockerPrerequisites_ps1 `
										-InventarLogDir $InventarLogDir `
										-DomainName $DomainName -DcIpV4Address $DcIpV4Address

	Log 0 "Das Fenster schliesst sich selber..."
	Stop-Script-Wait
}


### Disks verschlüsseln

## System-Disk verschlüsseln
If (($BitlockerSetupState -eq [eBitlockerSetupState]::NoLocalDrivesEncrypted) `
	-or ($BitlockerSetupState -eq [eBitlockerSetupState]::SystemDriveToEncrypt)) {

	Write-Host "`n`n"
	Add-Border-Text -Tab 2 -TextZeilen @('Alle Daten gespeichert?',
										 'Eventuell muss der Computer neu gestartet werden!')
	Write-Host "`n`n"

	Wait-For-UserInput 'Alle Daten gespeichert?' '' @('&Yes', '&Ja', '&No', '&Nein') 'Ja'


	# Versuchen, ob wir auf dem C: TPM explizit aktivieren können,
	#	weil wir nur mit HW arbeiten, die dies unterstützt
	If (-not (Assert-TPM-OnC)) {
		Log 4 'Konnte auf dem Laufwerk C: TPM nicht aktivieren.' -ForegroundColor Red
		Log 4 'Abbruch!' -ForegroundColor Yellow
		Break Script
	}

	## Haben wir eine Verbindung zum DC?
	If ((WaitFor-Domain-Reachable -DomainName $DomainName -DcIpV4Address $DcIpV4Address) -eq $False) {
		Log 4 'Konnte nicht mit der Domäne verbinden.' -ForegroundColor Red
		Log 4 'Abbruch!' -ForegroundColor Yellow
		Break Script
	}

	## Das Systemlaufwerk verschlüsseln
	Enable-BitLocker-OnAllFixedDrives -DriveLetters $Env:SystemDrive.Trim()

	## Allenfalls das Status-Logfile schreiben
	Test-Start-CreateInventar -CreateInventarLog:$CreateInventarLog -TestBitlockerPrerequisites_ps1 $TestBitlockerPrerequisites_ps1 `
		-InventarLogDir $InventarLogDir `
		-DomainName $DomainName -DcIpV4Address $DcIpV4Address

	## Prüfen, ob der BitLocker HW Test nötig ist
	Log 0 "Prüfe, ob der BitLocker HW-Test nötig ist" -ForegroundColor Yellow
	$BitlockerHWTestPendingState = Get-Bitlocker-HWTestPending-State 'C:'

	Switch ($BitlockerHWTestPendingState) {
		([eBitlockerHWTestPendingState]::TestPending) {
			Log 0 '  Der Computer wird neu gestartet,' -ForegroundColor Red
			Log 1 '  damit BitLocker die HW testen kann' -ForegroundColor Red

			## Wenn wir noch Datendisks verschlüsseln müssen,
			# dann das Script nach dem Login wieder starten
			
			# 007, 221213
			#	Bei HWTest pending wird nach dem Neustart das Script nochmals gestartet um die Inventar-Info zu generieren
			# If (Get-BitlockerState-HasDataDisksToEncrypt) {
				# Die Scripts ins lokale Dir kopieren
				$CTempBitlockerScriptDir = Copy-Script-ToLocalDrive -SrcDir $ScriptDir
				# Den lokalen Namen dieses Scripts berechnen
				$LocalScriptName = Join-Path $CTempBitlockerScriptDir ([IO.Path]::GetFileName($ScriptName))

				## Set-RunOnce -HKCU -KeyName 'OpenScriptDir' -Command "C:\Windows\explorer.exe `"$OnboardingScriptDir`""
				# Set-RunOnce -HKCU -KeyName 'Enable-Bitlocker.ps1' -Command "C:\Windows\explorer.exe `"$OnboardingScriptDir`""
				# Write-Host "RunOnce: $ScriptName"
				Set-Runonce -HKCU -KeyName 'Enable-Bitlocker.ps1' -Command ('%systemroot%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -NoProfile -File ' + "`"$LocalScriptName`"")
				# Start-Sleep -Seconds 5
			#}

			Restart -TimeoutSec 5
			Break Script
		}
		([eBitlockerHWTestPendingState]::TestFailed) {
			Log 4 '  Vorsicht!' -ForegroundColor Red
			Log 4 '  Dieses Gerät ist nicht mit BitLocker kompatibel' -ForegroundColor Red
		}
		Default {
			Log 0 '  Alles OK' -ForegroundColor Green
		}
	}
}


## Wenn kein HW-Test nötig ist
## oder beim vorherigen Boot das Systemlaufwerk verschlüsselt wurde,
## jetzt die Datendisks verschlüsseln

# Haben wir eine Verbindung zum DC?
If ((WaitFor-Domain-Reachable -DomainName $DomainName -DcIpV4Address $DcIpV4Address) -eq $False) {
	Log 4 'Konnte nicht mit der Domäne verbinden.' -ForegroundColor Red
	Log 4 'Die Datenlaufwerke wurden nicht verschlüsselt!' -ForegroundColor Red
	Log 4 'Abbruch!' -ForegroundColor Yellow
	Return
}

# Dem Netzwerk noch etwas Zeit geben
Start-Sleep -Seconds 5

# Alle noch nötigen Daten-Laufwerke verschlüsseln
$UnencryptedDataDrives = Get-FixedDrive-BitlockerState | ? { $_.IsSystemDrive -eq $False -and $_.IsEncrypted -eq $False }
$UnencryptedDataDriveLetters = $UnencryptedDataDrives | Select -ExpandProperty DriveLetter
Enable-BitLocker-OnAllFixedDrives -DriveLetters $UnencryptedDataDriveLetters

# Auto Unlok aktivieren
Enable-BitLocker-AutoUnlock

# Die BitLocker-Keys im AD speichern
Log 0 "Erzeuge ein Backup der Bitlocker-Keys" -ForegroundColor Yellow
Save-BitLockerKeys-ToAD

## Allenfalls das Status-Logfile schreiben
Test-Start-CreateInventar -CreateInventarLog:$CreateInventarLog -TestBitlockerPrerequisites_ps1 $TestBitlockerPrerequisites_ps1 `
	-InventarLogDir $InventarLogDir `
	-DomainName $DomainName -DcIpV4Address $DcIpV4Address

Log 0 "Alles fertig, die Disks werden mit BitLocker verschlüsselt" -ForegroundColor Green

Log 0 "Das Fenster schliesst sich selber..."
Stop-Script-Wait
