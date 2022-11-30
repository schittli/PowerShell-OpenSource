#Requires -Version 7.0

## !TT
##  #Requires -RunAsAdministrator
##  #Requires -Modules

# Suppress PSScriptAnalyzer Warning
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]


# Schickt ein WOL (Wake on LAN) Magic Packet an eine MAC-Adresse
#	Die MAC-Adresse kann man einfach herausfinden, wenn das Zielsystem läuft
#
#
# Based on:
# !Q https://powershell.one/code/11.html
#

## !Ex
#
#	# Die MAC-Adresse für 10.11.1.105 suchen und ihr dann das WOL Magic Paket schicken
#	C:\Scripts\PowerShell\Hypervisor-VM-Control\Find-ARP-MacAddress.ps1 -IPs 10.11.1.105 | C:\Scripts\PowerShell\Hypervisor-VM-Control\Invoke-WakeOnLan.ps1 -Verbose
#
#	# Einer MAC-Adresse das WOL Magic Paket schicken
#	C:\Scripts\PowerShell\Hypervisor-VM-Control\Invoke-WakeOnLan.ps1 -MacAddresses '00-11-32-b4-89-93' -Verbose
#
#

## Version
# 001, 221028


## ToDo, Ideen
   # 🟩 ...


[CmdletBinding(SupportsShouldProcess)]
Param(
	[Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
	# Die MAC-Adresse mit je 2 Zeichen, getrennt durch : oder -
	[ValidatePattern('^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$')]
	# Die MAC-Adresse(n)
	[Alias('MAC', '$MacAddress')]
	[String[]]$MacAddresses
)

Begin {
	# Instantiate a UDP client:
	$UDPclient = [System.Net.Sockets.UdpClient]::new()
}

Process {
	Function Find-ARP-IPAddress($MacAddr) {
		If ([String]::IsNullOrWhiteSpace($MacAddr)) { Return $Null }
		# Sicherstellen, dass die MAC Addr mit - getrennt ist
		$MacAddr = ($MacAddr -replace ':', '-').Trim()
		# Von arp -a die passende Zeile suchen und die erste Spalte zurückgeben
		$IPAddr = (arp -a | ? { $_ -match "\s+$([Regex]::Escape($MacAddr))\s+" }) `
			-split '\s+' | ? { $_ } | select -First 1
		If ($IPAddr) {
			Return $IPAddr.Trim()
		}
	}


	ForEach ($MacAddress in $MacAddresses) {
		Try {
			# get byte array from mac address
			$mac = $MacAddress -split '[:-]' |
				# convert the hex number into byte
				ForEach-Object { [System.Convert]::ToByte($_, 16) }

			#region compose the "magic packet"

			# create a byte array with 102 bytes initialized to 255 each:
			$packet = [byte[]](,0xFF * 102)

			# leave the first 6 bytes untouched, and
			# repeat the target mac address bytes in bytes 7 through 102:
			6..101 | Foreach-Object {
				# $_ is indexing in the byte array,
				# $_ % 6 produces repeating indices between 0 and 5
				# (modulo operator)
				$packet[$_] = $mac[($_ % 6)]
			}

			#endregion

			# connect to port 400 on broadcast address
			$UDPclient.Connect(([System.Net.IPAddress]::Broadcast), 4000)

			# send the magic packet to the broadcast address
			Write-Verbose "Sening magic packet to $MacAddress"
			$null = $UDPclient.Send($packet, $packet.Length)
		}
		Catch  {
		  Write-Warning "Unable to send magic packet to: $_"
		}
	}
}

End {
	 # release the UDF client and free its memory:
	 $UDPclient.Close()
	 $UDPclient.Dispose()
}
