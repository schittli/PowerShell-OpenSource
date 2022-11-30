# Suppress PSScriptAnalyzer Warning
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSShouldProcess', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]


# Erzeugt ein File mit einer gewünschten Grösse und Zufalllsdaten
#
#

## !Ex
#
#	# Das Verzeichnis c:\…\…\
#	# anonymisiert mit identischen Files und Dirs nachbilden
#	.\ch.jig.tools\Public\Clone-Dir-WithRandomData.ps1 -SrcDir 'c:\…\…\' -DstDir 'c:\Temp\Test-Random' -RandomizeDirNames -RandomizeFileNames -RandomizeFileExt -Force
#
#

## Version
# 001, 221130


## ToDo, Ideen
   # 🟩 ...


[CmdletBinding(SupportsShouldProcess)]
Param(
	[String]$SrcDir,
	[String]$DstDir,
	[Switch]$RandomizeDirNames,
	[Switch]$RandomizeFileNames,
	[Switch]$RandomizeFileExt,
	# Ziel neu initialisieren?
	[Switch]$Force
)



## Config

$NewFileWithRamdomData_ps1 = 'New-File-WithRamdomData.ps1'


If ($null -eq $MyInvocation.MyCommand.Path) {
	$ScriptDir = Get-Location
}
Else {
	$ScriptDir = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
}


# Liefert einen Zufallstext
Function Get-Random-Text([Int]$AnzChars, [Switch]$Numbers, [Switch]$UCChars, [Switch]$LCChars) {
	If ($AnzChars -le 0) { Return '' }

	# Default setzen
	If ((-not $Numbers) -and (-not $UCChars) -and (-not $LCChars)) {
		$Numbers = $UCChars = $LCChars = $True
	}

	# 0..9
	# -join ((48..57) | %{[char]$_ })
	# A..Z
	# -join ((65..90) | %{[char]$_ })
	# a..z
	# -join ((97..122) | %{[char]$_ })

	# -join (((48..57)+(65..90)+(97..122)) * $AnzChars |Get-Random -Count $AnzChars | %{[char]$_} )

	$CharSet = @()
	If ($Numbers) { $CharSet += (48..57) }
	If ($UCChars) { $CharSet += (65..90) }
	If ($LCChars) { $CharSet += (97..122) }

	$CharSet = $CharSet * $AnzChars

	-join ($CharSet |Get-Random -Count $AnzChars | %{[char]$_} )
}


# Liefert einen zufälligen Dateinamen
Function Get-Random-FileName([Int]$NameLen, [Int]$ExtLen = 3) {
	('{0}.{1}' -f (Get-Random-Text -AnzChars $NameLen), (Get-Random-Text -AnzChars $ExtLen -LCChars))
}


# Substring-Funktion, die mit Argumen-Fehlern klarkommt
# Debugged: OK
Function SubString() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)][String]$Str1,
      [Parameter(Mandatory)][Int]$Len
   )

   If ([String]::IsNullOrWhiteSpace($Str1)) { Return '' }

   If ($Len -gt $Str1.Length) {
      Return ''
   } Else {
      Return $Str1.Substring($Len)
   }
}


# Liest eine Verzeichnisstruktur rekursiv
# Und berechnet für jedes *Unterverzeichnis* einen zufälligen Verzeichnisnamen
#
# In $oDictionary erhält man:
# Key		Original Verzeichnisname
# Value	Randmized Verzeichnisname
#
#	!Ex
#		C:\GitWork\GitHub.com\schittli\PowerShell-OpenSource\Repo\Module\ch.jig.tools
#		C:\GitWork\GitHub.com\schittli\PowerShell-OpenSource\Repo\Module\2W.Vcz.VuJtr
#
#		C:\GitWork\GitHub.com\schittli\PowerShell-OpenSource\Repo\Module\ch.jig.tools\.vscode
#		C:\GitWork\GitHub.com\schittli\PowerShell-OpenSource\Repo\Module\2W.Vcz.VuJtr\.0Zahx8
Function Calc-Ramdomized-SubdirNames() {
	Param(
		[Parameter(Mandatory)][String]$ThisDir,
		[Parameter(Mandatory)][Object]$oDictionary
	)
	# $AllDirItems = Get-ChildItem -LiteralPath $RootDir -Force -Recurse
	$ThisDirDirs = Get-ChildItem -LiteralPath $ThisDir -Force -Directory
	$ThisDirDirs | % {
		## Den Verzeichnisnamen ramdomisieren
		$ThisSubdirName = $_.Name
		# Bei Verzeichnissen mit '.' den Punkt erhalten
		$DotItems = @()
		$ThisSubdirName.Split('.') | % {
			$DotItems += Get-Random-Text $_.Length
		}
		$ThisSubdirNameRnd = $DotItems -join '.'

		# Das übergeordnete Dir berechnen
		$ParentDir = [IO.Path]::GetDirectoryName($_.FullName)
		# Haben wir das Parent Dir bereits berechnet?
		If ($oDictionary.ContainsKey($ParentDir)) {
			$ThisDirRnd = Join-Path -Path ($oDictionary[$ParentDir]) -ChildPath $ThisSubdirNameRnd
		} Else {
			$ThisDirRnd = Join-Path -Path ([IO.Path]::GetDirectoryName($_.FullName)) -ChildPath $ThisSubdirNameRnd
		}
		$oDictionary.Add($_.FullName, $ThisDirRnd)
		# Rekursiver Aufruf
		Calc-Ramdomized-SubdirNames -ThisDir $_.FullName -oDictionary $oDictionary
	}
}



## Prepare

$NewFileWithRamdomData_ps1 = Join-Path $ScriptDir $NewFileWithRamdomData_ps1

If ((Test-Path -LiteralPath $SrcDir) -eq $False) {
	Write-Host "Quell-Verzeichnis existiert nicht: $SrcDir" -ForegroundColor Red
	Return
}


# Hat das Zielverzeichnis Inhalt?
$HasDstDirFiles = @(Get-ChildItem -LiteralPath $DstDir -Force -Recurse | select -First 1)
If ($HasDstDirFiles.Count -gt 0) {
	If ($Force) {
		Remove-Item -LiteralPath $DstDir -Force -Recurse
	} Else {
		Write-Host "Ziel-Verzeichnis hat bereits Inhalt: $DstDir" -ForegroundColor Red
		Return
	}
}


## Wenn benötigt, die Zufalls-Verzeichnisnamen berechnen
If ($RandomizeDirNames) {
	$oDictRandomizedDirs = New-Object 'System.Collections.Generic.Dictionary[string,string]'
	Calc-Ramdomized-SubdirNames -ThisDir $SrcDir -oDictionary $oDictRandomizedDirs
}


## Cache, mit denm Pfaden von den Src SubDirs zu den Dst SubDirs
$CacheSrcToDstDir = New-Object 'System.Collections.Generic.Dictionary[string,string]'



## Main

# Write-Host $SrcDir -ForegroundColor Red
# Write-Host $DstDir -ForegroundColor Red

# Die Quelle lesen
$AllSrcFiles = Get-ChildItem -File -LiteralPath $SrcDir -Force -Recurse

ForEach ($SrcFile in $AllSrcFiles) {
	$ThisSrcDir = $SrcFile.DirectoryName
	$ThisFileName = $SrcFile.BaseName
	$ThisFileNameExtension = $SrcFile.Extension

	$ThisSrcDirRelativeToSrcDir = SubString -Str1 $ThisSrcDir -Len $SrcDir.Length
	Write-Host "bearbeite: $(Join-Path $ThisSrcDirRelativeToSrcDir $SrcFile.Name)"

	# Haben wir das Zielverzeichnis bereicht berechnet?
	If ($CacheSrcToDstDir.ContainsKey($ThisSrcDir)) {
		$ThisDstDir = $CacheSrcToDstDir[$ThisSrcDir]
	} Else {
		# Das *Ziel* SubDir berechnen
		$DirDelta = SubString $ThisSrcDir $SrcDir.Length
		# Allenfalls das Zieldir durch Zufallsdaten ersetzen
		If ($RandomizeDirNames) {
			If ($oDictRandomizedDirs.ContainsKey($ThisSrcDir)) {
				# Das randomisierte Verzeichnis
				$DirRnd = $oDictRandomizedDirs[$ThisSrcDir]
				# Das für uns relevante randomisierte SubDir
				$SubDirRnd = SubString $DirRnd $SrcDir.Length
			} Else {
				Write-Error 'Ungültiger Cache!'
			}
			$ThisDstDir = Join-Path $DstDir $SubDirRnd
		} Else {
			$ThisDstDir = Join-Path $DstDir $DirDelta
		}
		# Write-Host $ThisDstDir

		# Den Dir-Cache aktualisieren
		$CacheSrcToDstDir.Add($ThisSrcDir, $ThisDstDir)
	}

	## Das Zielverzeichnis erstellen
	New-Item -Path $ThisDstDir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

	## Den Zieldatei-Namen berechnen

	# Debugging
	# If ($SrcFile.Name -eq 'ReadMe.md') {
	# 	$ddd = 1
	# }

	If ($RandomizeFileNames) {
		$ThisFileName = Get-Random-Text -AnzChars $ThisFileName.Length
	}
	If ($RandomizeFileExt) {
		$ThisFileNameExtension = '.{0}' -f (Get-Random-Text -AnzChars ($ThisFileNameExtension.Length - 1) -LCChars)
	}

	$NewFileName = '{0}{1}' -f $ThisFileName, $ThisFileNameExtension
	$NewFileFullName = Join-Path $ThisDstDir $NewFileName

	## Das File mit den Zufallsdaten erzeugen
	& $NewFileWithRamdomData_ps1 -FileName $NewFileFullName -FileSize $SrcFile.Length -Force
}

