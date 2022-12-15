## Bitlocker auf allen Partitionen deaktivieren
#
#
# 002, 221205
# 003, 221205
#

# Bevor BitLocker deaktiviert werden kann, müssen alle AutoUnlock deaktiviert werden
Write-Host "`nDeaktiviere 'AutoUnlok'" -ForegroundColor Yellow
Clear-BitLockerAutoUnlock -EA SilentlyContinue

# BitLocker deaktivieren
Write-Host "`nDeaktiviere BitLocker" -ForegroundColor Yellow
Get-BitLockerVolume | Disable-BitLocker -EA SilentlyContinue

# Den Status der Entschlüsselung anzeigen
Write-Host "`nEntschlüssle die Disks" -ForegroundColor Yellow
Do {
	# Get-BitLockerVolume | Select MountPoint, EncryptionPercentage
	$PercentSum = (Get-BitLockerVolume | Select EncryptionPercentage) | `
						Measure -Property EncryptionPercentage -Sum -EA SilentlyContinue | `
						Select -ExpandProperty Sum

	If ($null -eq $PercentSum) { $PercentSum = 0 }

	Write-Host ("`rDisks Verschlüsselt: {0,3}% (Total)" -f $PercentSum) -NoNewline
	Start-Sleep -Milliseconds 1500

} While ($PercentSum -gt 0)

Write-Host ''
