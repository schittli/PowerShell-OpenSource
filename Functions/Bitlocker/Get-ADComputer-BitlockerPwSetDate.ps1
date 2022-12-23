# Analysiert das AD
# und liefert Information, welche Computer / User BitLocker aktiviert haben
# 
# 
# 
# BitlockerPWSetDate
# 	Das Datum, an dem das Bitlocker PW das letzte Mal gesetzt wurde
# 
# 
# \\akros.ch\Ablage\IT-Scripts\AD-Bitlocker\Get-ADComputer-BitlockerPwSetDate.ps1 | select -First 3
# ComputerName LastLogonDate       BitlockerPWSetDate
# ------------ -------------       ------------------
# AKR005       05.06.2015 03:38:52
# BASDC001     01.06.2022 12:43:38
# BASDC002     03.06.2022 09:29:22



# Ex
# 
# 	# BitLocker-Status aus dem AD lesen
# 	$BitLockerInfo = \\akros.ch\Ablage\IT-Scripts\AD-Bitlocker\Get-ADComputer-BitlockerPwSetDate.ps1
# 
# 	# Alle Daten anzeigen
# 	$BitLockerInfo | select ComputerName, UserNamen, IsSingleOwner, AnzOwner, Betriebssystem, LastLogonDate, BitlockerPWSetDate | ft
# 
# 	# Alle Computer ohne BitLocker
# 
# 
# 	# Alle Computer, die mehr als 1 User haben
# 	$BitLockerInfo |  ? IsSingleOwner -eq $false | select ComputerName, UserNamen, IsSingleOwner, AnzOwner, Betriebssystem, LastLogonDate, BitlockerPWSetDate | ft
# 
# 	# Alle User, die mehr als 1 Computer haben
# 	$BitLockerInfo | Group Usernamen | ? Count -gt 1 | select -ExpandProperty Group | select UserNamen, ComputerName
# 
# 	# Alle User, die Bitlocker nicht aktiviert haben
# 	$BitlockerDisabled = $BitLockerInfo | ? { $_.BitlockerPWSetDate -eq $null -and $_.UserNamen } | select ComputerName, UserNamen, IsSingleOwner, AnzOwner, Betriebssystem, LastLogonDate, BitlockerPWSetDate
# 	$BitlockerDisabled.Count
# 
# 	# Alle User, die Bitlocker aktiviert haben
# 	$BitlockerEnabled = $BitLockerInfo | ? { $_.BitlockerPWSetDate -and $_.UserNamen } | select ComputerName, UserNamen, IsSingleOwner, AnzOwner, Betriebssystem, LastLogonDate, BitlockerPWSetDate
# 	$BitlockerEnabled.Count
# 
# 	# Anzeigen
#  $BitlockerDisabled | ogv
# 



# 001, tom@jig.ch
# 002, 221205
# 



### Configure



# Liefert die Anzal Objekte, $null == 0
Function Count($Obj) {
	($Obj | Measure).Count
}
 

# Liest vom AD den BitLocker-Status aller Computer Objekte
Function Get-Bitlocker() {
	[CmdletBinding()]
	Param (
		# [string]$SearchBase = "OU=YourOUforWorkstations,DC=Your,DC=Domain"
		[string]$SearchBase = 'DC=akros,DC=ch'
	)

	Try { Import-Module ActiveDirectory -ErrorAction Stop }
	Catch { Write-Warning "Unable to load Active Directory module because $($Error[0])"; Exit }


	Write-Verbose "Getting Workstations..." -Verbose
	$AllAdComputers = Get-ADComputer -Filter * -SearchBase $SearchBase -Properties LastLogonDate, OperatingSystem
	
	## Die OS-Info standardisieren
	# $AllAdComputers | select OperatingSystem -Unique
	$AllAdComputers | % {
		$ThisComputer = $_
		Switch -Regex ($ThisComputer.OperatingSystem) {
			$Null {
				$ThisComputer | Add-Member -MemberType NoteProperty -Name 'Betriebssystem' -Value 'Unbekannt' -Force
			}
			'Server|Windows NT' {
				$ThisComputer | Add-Member -MemberType NoteProperty -Name 'Betriebssystem' -Value 'WindowsServer' -Force
			}			
			'Windows 10|Windows 7|Windows 8|Windows XP|Windows Vista|Windows 2000' {
				$ThisComputer | Add-Member -MemberType NoteProperty -Name 'Betriebssystem' -Value 'WindowsClient' -Force
			}
			'Ubuntu|Linux' {
				$ThisComputer | Add-Member -MemberType NoteProperty -Name 'Betriebssystem' -Value 'Linux' -Force
			}
			Default {
				$ThisComputer | Add-Member -MemberType NoteProperty -Name 'Betriebssystem' -Value $ThisComputer.OperatingSystem -Force
			}
		}
	}

	$Count = 1
	$Results = ForEach ($Computer in $AllAdComputers)
	{
		 Write-Progress -Id 0 -Activity "Searching BitLocker-Data for Computers" -Status "$Count of $($AllAdComputers.Count)" -PercentComplete (($Count / $AllAdComputers.Count) * 100)
		 New-Object PSObject -Property @{
			  ComputerName = $Computer.Name
			  Betriebssystem = $Computer.Betriebssystem
			  LastLogonDate = $Computer.LastLogonDate 
			  BitlockerPWSetDate = Get-ADObject -Filter "objectClass -eq 'msFVE-RecoveryInformation'" -SearchBase $Computer.distinguishedName -Properties msFVE-RecoveryPassword,whenCreated | Sort whenCreated -Descending | Select -First 1 | Select -ExpandProperty whenCreated
		 }
		 $Count ++
	}
	Write-Progress -Id 0 -Activity " " -Status " " -Completed
	$Results
}



# Liefert alle AD-Gruppen der Local Admins und die jeweiligen Hostnamen
# 
# $LocalAdminsADGroups = Get-ADGroup-LocalAdmins
Function Get-ADGroup-LocalAdmins() {
	$Prefix = '__localAdmins_'
	$PrefixLen = $Prefix.Length
	$AllAdminsAdGroups = Get-ADGroup -Filter * | ? Name -like "$($Prefix)*"
	
	$AllAdminsAdGroups | % { $_ | Add-Member -MemberType NoteProperty -Name 'Hostname' -Value ($_.Name.Substring($PrefixLen)) -Force }
	$AllAdminsAdGroups
}



# Sucht in den __localAdmins_ Gruppen
# die Mitglieder
# und bestimmt, ob ein einzelner User der Owner ist oder mehrere
# Im Resultat werden diese Properties gesetzt:
# 	Owners			Alle Mitglieder der ADGruppe
# 	IsSingleOwner	True, wenn nur einer der Owner ist
# 	Owner				Wenn nur einer Owner ist, der ADUser ders Owners
# 	
# 
# eg
# 	$LocalAdminsAdgroups = Get-ADGroup-LocalAdmins
# 	Get-ADGroup-Members $LocalAdminsAdgroups
# 	Get-ADGroup-Members $LocalAdminsAdgroups anb007
Function Get-ADGroup-Members() {
	[CmdletBinding()]
	Param (
		# Liste der ADGruppen, von denen wir die Mitglieder suchen 
		[Parameter(Mandatory)][Object]$ADGroups,
		# Die Liste aller AD-User mit zusätzlichen Properties
		[Parameter(Mandatory)][Object]$AllAdUsers,
		# Nur für einen Hostnamen die Daten bestimmen?
		$Hostname = $null
	)

	# Wenn $Hostname definiert ist, nur von diesem die Owner zurückgeben
	$Res = @()
	$Count = 0
	$ADGroups | ? { If ($Hostname -ne $null) {$_.Hostname -eq $Hostname} Else {$True} } | % {
		$Count++
		Write-Progress -Id 0 -Activity 'Analysiere lokale Admins' -Status "$Count of $($ADGroups.Count)" -PercentComplete (($Count / $ADGroups.Count) * 100)

		$ThisHost = $_
		# Write-Host $ThisHost.Hostname
		
		# Die AD Gruppen Users lesen
		$Users = Get-ADGroupMember -Identity $_.Name

		# Die erweiterten Props der Gruppen-Mitglieder suchen
		$ThisGroupAdUsers = $Users | Select -ExpandProperty SamAccountName | % {
			$SamAccountName = $_
			$AllAdUsers | ? SamAccountName -eq $SamAccountName
		}

		$ThisHost | Add-Member -MemberType NoteProperty -Name 'IsSingleOwner' -Value ((Count $Users) -eq 1) -Force
		$ThisHost | Add-Member -MemberType NoteProperty -Name 'Owners' -Value ($ThisGroupAdUsers) -Force
		$Res += $ThisHost
	}
	$Res
}



### Main

Write-Host 'Lese alle AD User'
$AllAdUsers = Get-ADUser -Filter * -Properties UserPrincipalName, DisplayName, Company, Enabled, GivenName, sn, Surname

## Alle Localadmins bestimmen
Write-Host 'Suche die Host-Admins'
$LocalAdminsADGroups = Get-ADGroup-LocalAdmins

Write-Host 'Weise den Host-Admins die AD-User zu'
$LocalAdminsData = Get-ADGroup-Members -ADGroups $LocalAdminsAdgroups -AllAdUsers $AllAdUsers

Write-Host 'Lese die Bitlocker-States'
$BitLockerStates = Get-Bitlocker | Sort @{ Ex='BitlockerPWSetDate'; Descending=$True},@{ Ex='LastLogonDate'; Descending=$True}

# Merge Bitlocker-State mit den Userdaten
ForEach($BitLockerState in $BitLockerStates) {
	$ThisComputerName = $BitLockerState.ComputerName
	# Die User-Info suchen
	$ThisOwners = $LocalAdminsData | ? Hostname -eq $ThisComputerName
	$AnzOwners = Count $ThisOwners.Owners

	# Daten ergänzen
	$BitLockerState | Add-Member -MemberType NoteProperty -Name 'AnzOwner' -Value $AnzOwners
	$BitLockerState | Add-Member -MemberType NoteProperty -Name 'Owners' -Value ($ThisOwners) -Force
	$BitLockerState | Add-Member -MemberType NoteProperty -Name 'IsSingleOwner' -Value ($AnzOwners -eq 1) -Force

	# Namen + Vornamen sammeln
	$UserNamen = $ThisOwners.Owners | Select @{N='NameVorname'; Ex= { '{0} {1}' -f $_.Surname, $_.GivenName }} | Select -ExpandProperty NameVorname
	$UserNamen = $UserNamen -join ', '
	$BitLockerState | Add-Member -MemberType NoteProperty -Name 'UserNamen' -Value ($UserNamen) -Force
}


## Das Resultat filtern

# OS ausschliessen
$BetriebssystemBlacklist = @('WindowsServer', 'Cisco Identity Services Engine', 'Unbekannt')
$BitLockerStates = $BitLockerStates | ? { $BetriebssystemBlacklist -notcontains $_.Betriebssystem }

# Hostnamen ausschliessen
#e.g.  Schittli-Testrechner
$HostnamesBlacklist = @('ANB078')
$BitLockerStates = $BitLockerStates | ? { $HostnamesBlacklist -notcontains $_.ComputerName }

# Login war in den letzten 13 Monaten
$LastLoginDate = (Get-Date).AddMonths(-13)
$BitLockerStates = $BitLockerStates | ? LastLogonDate -ge $LastLoginDate

# Sortieren
$BitLockerStates | Sort Betriebssystem, UserNamen

$Ende = 1



