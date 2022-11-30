# Suppress PSScriptAnalyzer Warning
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]


# Erzeugt ein File mit einer gewünschten Grösse und Zufalllsdaten
#
#



## !Ex
#
#	# Ein File mit 1GB erzeugen, das bestehende File überschreiben
# 	.\New-File-WithRamdomData.ps1 -FileName 'c:\temp\test100b.tmp' -FileSize 1GB -Force
#

## Version
# 001, 221130


## ToDo, Ideen
   # 🟩 ...


[CmdletBinding(SupportsShouldProcess)]
Param(
	[String]$FileName,
	[Int]$FileSize,
	# Überschreiben?
	[Switch]$Force
)


## Config
$MaxBufferSize = 100MB


## Prepare
$BufferSize = [Math]::Min($MaxBufferSize, $FileSize)
$Buffer = [Byte[]]::New($BufferSize);


## Main


If (Test-Path -LiteralPath $FileName -PathType Leaf) {
	If ($Force) {
		Remove-Item -LiteralPath $FileName -Force
	} Else {
		Write-Host "File existiert bereits: $FileName" -ForegroundColor Red
		Return
	}
}

Try {
	# Den Randomizer initialisieren
	$oCrypto = [System.Security.Cryptography.RNGCryptoServiceProvider]::New()

	Try {
		# Den Filestream öffnen
		# !M https://learn.microsoft.com/en-us/dotnet/api/system.io.filestream?view=net-7.0
		$oFileStream = New-Object IO.FileStream $FileName, 'Append', 'Write', 'Read'
		
		# So lange Daten schreiben, bis die Dateigrösse erreicht ist
		[UInt64]$ByteCnt = 0
		While ($ByteCnt -lt $FileSize) {
			# Wie viele Bytes sind noch zu schreiben?
			$RestBytes = $FileSize - $ByteCnt
			# Zufallsdaten erzeugen
			$NewBufSize = [Math]::Min($MaxBufferSize, $RestBytes)
			$oCrypto.GetBytes($Buffer);
			# [System.IO.File]::WriteAllBytes($filename, $contents)
			$oFileStream.Write($Buffer, 0, $NewBufSize)
			$ByteCnt += $NewBufSize
		}
	}
	Finally {
		$oFileStream.Close()
		$oFileStream.Dispose()
	}
}
Finally {
	$oCrypto.Dispose()
}
