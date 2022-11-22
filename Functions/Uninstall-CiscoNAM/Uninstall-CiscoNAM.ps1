# Deinstalliert das Cisco Modul Network Access Manager (NAM)
# Aktualisiert wenn nötig die anderen Cisco Module
# 
# 
# !Ex
# 	# In PowerShell ausführen:
# 	[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex "& { $(irm 'https://github.com/schittli/PowerShell-OpenSource/raw/main/Functions/Uninstall-CiscoNAM/Uninstall-CiscoNAM.ps1') }"
# 
# 
# 
# 001, 221122

[CmdletBinding(SupportsShouldProcess)]
Param (
	# Die elevated Shell nicht schliessen
	[Switch]$NoExit = $True,
	# Wenn definiert, dann wird nicht die automatische Deinstallation gestartet
	[Switch]$TestControlPanel
)


## Pre-Conditions
If ($PSVersionTable.PSVersion.Major -gt 5) {
	Write-Host "`nDieses Script muss in PowerShell 5 gestartet werden" -ForegroundColor Red
	Start-Sleep -MilliS 2500
	Write-Host -NoNewLine "`nPress any key to continue…" -ForegroundColor Green
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	Return
}




## Config 

$Version = '1.0, 22.11.22'
$Feedback = 'bitte an: schittli@akros.ch'

# Perma Link zum eigenen Script
$ThisScriptPermaLink = 'https://github.com/schittli/PowerShell-OpenSource/raw/main/Functions/Uninstall-CiscoNAM/Uninstall-CiscoNAM.ps1'



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



# Erzeugt aus
# C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\Uninstall.exe -remove
# Den richtigen Befehl:
# "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\Uninstall.exe" -remove
# 
Function Split-Command-AndArgs($Command) {
	$Items = $Command -split ' '
	for ($i=0; $i -lt $Items.Count; $i++) {
		$TestPath = $items[0 .. $i] -join ' '
		# Get-Command erkennt auch Befehle, ohne dass die Dateierweiterung angegeben wird :-)
		$Cmd = Get-Command $TestPath -ErrorAction SilentlyContinue
		If ($Cmd -ne $null) {
			Return ("`"{0}`" {1}" -f $TestPath, ($items[($i+1) .. ($Items.Count-1)] -join ' '))
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
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [Parameter(ValueFromPipeline              =$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0
        )]
        [String[]]$ComputerName = $env:COMPUTERNAME,
        [Parameter(Position=0)]
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
        } else {
            $HashProperty = @{}
            $SelectProperty = @('ComputerName','ProgramName')
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
                        } else {
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
                        
                        $RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::$_,$Computer)
                        $RegistryLocation | ForEach-Object {
                            $CurrentReg = $_
                            if ($RegBase) {
                                $CurrentRegKey = $RegBase.OpenSubKey($CurrentReg)
                                if ($CurrentRegKey) {
                                    $CurrentRegKey.GetSubKeyNames() | ForEach-Object {
                                        Write-Verbose -Message ('{0}{1}{2}' -f $RegName, $CurrentReg, $_)

                                        $DisplayName = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayName')
                                        if (($DisplayName -match '^@{.*?}$') -and ($CurrentReg -eq $MSStoreRegPath)) {
                                            $DisplayName = $DisplayName  -replace '.*?\/\/(.*?)\/.*','$1'
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
                                            } else {
                                                $IncludeProgram | Where-Object {
                                                    $DisplayName -notlike ($_ -replace '\[','`[')
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
                                            } else {
                                                $ExcludeProgram | Where-Object {
                                                    $DisplayName -like ($_ -replace '\[','`[')
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
														} Else {
															$UninstallStringCln = $UninstallStringCln.Trim()
															# Äussere " entfernen
															If ($UninstallStringCln[0] -eq '"' -and $UninstallStringCln[-1] -eq '"') {
																$UninstallStringCln = $UninstallStringCln[1..($UninstallStringCln.Length-2)] -Join ''
															}
															# Äussere ' entfernen
															If ($UninstallStringCln[0] -eq "'" -and $UninstallStringCln[-1] -eq "'") {
																$UninstallStringCln = $UninstallStringCln[1..($UninstallStringCln.Length-2)] -Join ''
															}
															# Erzeugt:
															# "C:\Program Files (x86)\Cisco\Cisco AnyConnect Secure Mobility Client\Uninstall.exe" -remove
															$UninstallStringCln = Split-Command-AndArgs $UninstallStringCln
															$HashProperty.$CurrentProperty = $UninstallString
															$HashProperty.UninstallStringCln = $UninstallStringCln
														}
													} Else {
														$HashProperty.$CurrentProperty = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
													}
                                                }
                                            }
                                            if ($LastAccessTime) {
                                                $InstallPath = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('InstallLocation') -replace '\\$',''
                                                if ($InstallPath) {
                                                    $WmiSplat = @{
                                                        ComputerName = $Computer
                                                        Query        = $("ASSOCIATORS OF {Win32_Directory.Name='$InstallPath'} Where ResultClass = CIM_DataFile")
                                                        ErrorAction  = 'SilentlyContinue'
                                                    }
                                                    $HashProperty.LastAccessTime = Get-WmiObject @WmiSplat |
                                                        Where-Object {$_.Extension -eq 'exe' -and $_.LastAccessed} |
                                                        Sort-Object -Property LastAccessed |
                                                        Select-Object -Last 1 | ForEach-Object {
                                                            $_.ConvertToDateTime($_.LastAccessed)
                                                        }
                                                } else {
                                                    $HashProperty.LastAccessTime = $null
                                                }
                                            }

                                            if ($psversiontable.psversion.major -gt 2) {
                                                [PSCustomObject]$HashProperty
                                            } else {
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
            } catch {
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


# True, wenn Elevated
# 220813
Function Is-Elevated() {
	([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
}



## Prepare

# Start Elevated
if (!(Is-Elevated)) {
	Write-Host ">> starte PowerShell als Administrator (Elevated)`n`n" -ForegroundColor Red
	Start-Sleep -Seconds 4

	$Command = "[Net.ServicePointManager]::SecurityProtocol = 'Tls12'; Invoke-Expression -Command (Invoke-RestMethod -Uri `"$ThisScriptPermaLink`")"
	
	If ($NoExit) {
		Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -NoExit -Command $Command"
	} Else {
		Start-Process PowerShell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -Command $Command"
	}

	# Exit from the current, unelevated, process
	Start-Sleep -MilliS 2500
	Exit
	
} Else {
	$Host.UI.RawUI.WindowTitle = $MyInvocation.MyCommand.Definition + ' (Elevated)'
	$Host.UI.RawUI.BackgroundColor = 'DarkBlue'
	Clear-Host
	Log 0 'Pruefe, ob das Cisco Modul Network Access Manager (NAM) installiert ist'
	Log 1 "Version: $Version" -ForegroundColor DarkGray
	Log 1 "Rückmeldungen bitte an: $Feedback" -ForegroundColor DarkGray
}


# Stellt sicher, 
# - dass MSI-Uninstall-Strings nicht als App-Install/Konfig-Strings ausgeführt werden
# - dass ein Reboot wann immer möglich unterdrückt wird
Function Uninstall-Software-By-UninstallString() {
	[CmdletBinding(SupportsShouldProcess)]
	Param (
		[Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$UninstallString,
		[Parameter(Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$ProgramName, 
		[Switch]$ShowDebugInfo
	)

	If (Has-Value $ProgramName) { Log 2 "Deinstalliere: $ProgramName" }
	If ($ShowDebugInfo) { Log 3 "UninstallString: $UninstallString" }

	If ($UninstallString -like 'MsiEx*') {
		# Uninstall mit MSI
		$Items = $UninstallString -Split '\s+'
		$Command = $Items[0]
		# Dummerweise sind manche Uninstall-Strings im Endeffekt App-Install/Konfig-Strings
		# Drum /I mit /x ersetzen
		$Arg1 = $Items[1] -replace '/i','/x'
		If ($ShowDebugInfo) {
			Log 3 "Starte MSI:"
			Log 4 "$Command $($Arg1) /qn REBOOT=SUPPRESS"
		}
		Start-Process $Command -ArgumentList "$($Arg1) /qn REBOOT=SUPPRESS" -Wait
	} Else {
		# Uninstall ohne MSI
		If ($ShowDebugInfo) { Log 3 "UninstallString Ori: $UninstallString" }
		$FixedUninstallString = Fix-UninstallString $UninstallString
		If ($ShowDebugInfo) { Log 3 "UninstallString Bereinigt: $FixedUninstallString" }
		$Program, $Arguments = Split-Programm-And-Arguments $FixedUninstallString
		If ($ShowDebugInfo) { Log 3 "Starte Uninstall-String:" }
		If ($ShowDebugInfo) { Log 4 "Program: $Program" }
		If ($ShowDebugInfo) { Log 4 "Arguments: $Arguments" }
		Start-Process $Program -ArgumentList $Arguments -Wait
	}	
}


If ( (Is-Elevated) -eq $False) {
	Write-Host "`nDas Script muss als Administrator / Elevated ausgeführt werden" -ForegroundColor Red
	Start-Sleep -MilliS 3500
	Write-Host -NoNewLine "`nPress any key to continue…" -ForegroundColor Green
	$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
	Return
}



## Main

Log 1 'Lese die Liste der installierten SW'
# Alle installierte Cisco SW bestimmen
$CiscoSW = Get-CiscoSW-ToUninstall -Property DisplayVersion, VersionMajor, Installdate, UninstallString

# Ist der NAM / Network Access Manager installiert?
$CiscoNAM = $CiscoSW | ? ProgramName -like '*Network Access Manager*'

# Wenn NAM vorhanden: Deinstallieren
If ($CiscoNAM) {
	Log 1 'Gefunden: Cisco Network Access Manager (NAM)'
	
	Log 2 'Starte die Deinstallation, bitte warten'
	$CiscoNAM | % {
		# Uninstall-CiscoAMPforEndpointsConnector -UninstallString $CiscoNAM.UninstallString
		If ($TestControlPanel -eq $False) {
			Uninstall-Software-By-UninstallString -UninstallString $_.UninstallString
		}
	}
	
	# Kurz warten
	Start-Sleep -Milliseconds 1500
	
	Log 2 'Pruefe, ob die Deinstallation erfolgreich war'
	# Wurde NAM erfolgreich deinstalliert?
	$CiscoSW = Get-CiscoSW-ToUninstall -Property DisplayVersion, VersionMajor, Installdate, UninstallString

	# Ist der NAM / Network Access Manager installiert?
	$CiscoNAM = $CiscoSW | ? ProgramName -like '*Network Access Manager*'
	# Immer noch installiert
	If ($CiscoNAM) {
		Log 2 'Bitte den Cisco Network Access Manager (NAM) von Hand deinstallieren!' -ForegroundColor Red -NewLineBefore
		Log 2 'Starte das Windows Control Panel...' -ForegroundColor Red
		Start-Sleep -Milliseconds 2500
		# 201117: Öffne das Control Panel 'Programs and Features'
		appwiz.cpl
	} Else {
		Log 1 'Alles OK!, der Cisco Network Access Manager (NAM) ist nicht mehr installiert' -ForegroundColor Green
	}
} Else {
	Log 1 'Alles OK!, der Cisco Network Access Manager (NAM) ist nicht mehr installiert' -ForegroundColor Green
}


If ($NoExit -eq $False) {
	Write-Host ' Das Fenster wird sich in 5s selber schliessen' -ForegroundColor Gray
	Start-Sleep -Milliseconds 5000
}
