# Installiert PowerShell Module von einem GitHub Repository
#	Das GitHub Repo kann mehrere Module beinhalten
#	Das Script:
#	• Lädt das Repository zip herunter
#	• entpackt es
#	• sucht jedes Modul (die *.psd1 Dateien)
#	• und installiert je nach Parameter:
#		-InstallAllModules
#			alle gefundenen Module
#		-InstallModuleNames @('','')
#			Die aufgelisteten Modulnamen
#
#
# Wichtigste Parameter
#	
#	-InstallAllModules
#		alle gefundenen Module
#	-InstallModuleNames @('','')
#		Die aufgelisteten Modulnamen
#	-UpgradeInstalledModule
#		Aktualisiert bereits installierte Module
#	-Force
#		Installiert Module immer und überschreibt sie allenfalls
#
#
# !Ex
#	# Startet dieses Script direkt von GitHub
#	#	und holt die PS Module vom angegebenen GitHub Repo
#	# 	und aktualisiert die bereits installierten Module
#	$GitHubRepo = 'https://github.com/iainbrighton/GitHubRepository'
#	iex "& { $(irm 'https://g.akros.ch/githubs/PowerShell-OpenSource/raw/main/Functions/Install-PSModule-FromGitHub/Install-Module-GitHub.ps1') } -GitHubRepoUrl $GitHubRepo -UpgradeInstalledModule"
#
#
#  # Aktualisiert ein allenfalls bereits installierte Module.
#  # Wenn es noch nicht existiert, wird es im ProposedDefaultScope installiert
#  -UpgradeInstalledModule -ProposedDefaultScope AllUsers|CurrentUser
#
#  # Aktualisiert ein allenfalls bereits installierte Module.
#  # Wenn es noch nicht im Scope EnforceScope installiert ist, wird es zwingend auch darin installiert
#  -UpgradeInstalledModule -EnforceScope AllUsers|CurrentUser
#
#
#  # Aktualisiert alle bereits installierten PS Module vom GitHub Repo
#  # wenn sie veraltet sind
#  C:\Scripts\PowerShell\Install-Module-GitHub\Install-Module-GitHub.ps1 -GitHubRepoUrl 'https://github.com/iainbrighton/GitHubRepository' -UpgradeInstalledModule
#
#  # Installiert die PS Module vom GitHub Repo in den AllUsers Scope
#  C:\Scripts\PowerShell\Install-Module-GitHub\Install-Module-GitHub.ps1 -GitHubRepoUrl 'https://github.com/iainbrighton/GitHubRepository' -ProposedDefaultScope AllUsers -InstallAllModules
#
#  # Installiert die PS Module vom GitHub Repo in den AllUsers Scope
#  # und installiert die Module nochmals zwingend
#  C:\Scripts\PowerShell\Install-Module-GitHub\Install-Module-GitHub.ps1 -GitHubRepoUrl 'https://github.com/iainbrighton/GitHubRepository' -ProposedDefaultScope AllUsers -InstallAllModules -Force
#
#
#  ToDo
#  🟩 Neuer Parameter: GitHubUrl
#
# ✅
# 🟩

# Ex GitHub Zip
# c:\Scripts\PowerShell\Install-Module-GitHub\!Q GitHubRepository\GitHubRepository-master.zip

# !M Install-Module
# https://learn.microsoft.com/de-ch/powershell/module/PowershellGet/Install-Module?view=powershell-5.1

# -InstallZip 'c:\Scripts\PowerShell\Install-Module-GitHub\!Q GitHubRepository\GitHubRepository-master.zip'

[CmdletBinding(DefaultParameterSetName = 'InstallGitHubUrlProposedScope')]
Param(

   ## InstallGitHubUrl…
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubUrlProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubUrlEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubUrlUpgradeOnly')]

   ## PesterTestGithubDownloadOnly
   [Parameter(ParameterSetName = 'PesterTestGithubDownloadOnly')]
   # Die URL, von wo wir das Repo herunterladen
   # E.g.:
   #   https://github.com/rtCamp/login-with-google
   #   https://github.com/rtCamp/login-with-google/tree/develop
   #   https://github.com/rtCamp/login-with-google/releases/tag/1.3.1
   [String]$GitHubRepoUrl,

   ## InstallGitHubZip…
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubZipProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubZipEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubZipUpgradeOnly')]

   ## PesterTestGithubDownloadOnly
   [Parameter(ParameterSetName = 'PesterTestGithubDownloadOnly')]
   # Die URL zum Zip
   [String]$GitHubZipUrl,


   ## GitHubItemsBranch…
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchUpgradeOnly')]

   ## GitHubItemsTag…
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagUpgradeOnly')]

   ## PesterTestGithubDownloadOnly
   [Parameter(ParameterSetName = 'PesterTestGithubDownloadOnly')]
   # Der Name des GitHub Owners
   [String]$GitHubOwnerName,


   ## GitHubItemsBranch…
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchUpgradeOnly')]

   ## GitHubItemsTag…
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagUpgradeOnly')]

   ## PesterTestGithubDownloadOnly
   [Parameter(ParameterSetName = 'PesterTestGithubDownloadOnly')]
   # Der Name des GitHub Owners
   [String]$GitHubRepoName,


   ## GitHubItemsBranch…
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchUpgradeOnly')]

   ## GitHubItemsTag…
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagUpgradeOnly')]

   ## PesterTestGithubDownloadOnly
   [Parameter(ParameterSetName = 'PesterTestGithubDownloadOnly')]
   # Der Name des GitHub Owners
   [String]$GitHubBranchName,


   ## GitHubItemsTag…
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagUpgradeOnly')]

   ## PesterTestGithubDownloadOnly
   [Parameter(ParameterSetName = 'PesterTestGithubDownloadOnly')]
   # Der Name des GitHub Owners
   [String]$GitHubTag,


   ## InstallRepositoryZipFile…
   [Parameter(Mandatory, ParameterSetName = 'InstallRepositoryZipFileProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallRepositoryZipFileEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallRepositoryZipFileUpgradeOnly')]
   # Das Zip, das wir installieren
   [String]$RepositoryZipFileName,

   ## Mix der verschiedenen ParameterSets
   [Parameter(ParameterSetName = 'InstallGitHubUrlProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubZipProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileProposedScope')]
   # Wenn das Modul noch nicht installiert ist, dann wird dieser Scope genützt
   [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   [Alias('DefaultScope')]
   [AllowEmptyString()][String]$ProposedDefaultScope,


   ## Mix der verschiedenen ParameterSets
   [Parameter(ParameterSetName = 'InstallGitHubUrlEnforceScope')]
   [Parameter(ParameterSetName = 'InstallGitHubZipEnforceScope')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchEnforceScope')]
   [Parameter(ParameterSetName = 'GitHubItemsTagEnforceScope')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileEnforceScope')]
   # Das Modul wird zwingend in diesem Scope installiert, auch wenn es schon anderso installiert ist
   [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   [AllowEmptyString()][String]$EnforceScope,

   ## InstallGitHubUrl…
   [Parameter(ParameterSetName = 'InstallGitHubUrlUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallGitHubUrlProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubUrlEnforceScope')]

   ## InstallGitHubZip…
   [Parameter(ParameterSetName = 'InstallGitHubZipUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallGitHubZipProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubZipEnforceScope')]

   ## GitHubItemsBranch…
   [Parameter(ParameterSetName = 'GitHubItemsBranchUpgradeOnly')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchEnforceScope')]

   ## GitHubItemsTag…
   [Parameter(ParameterSetName = 'GitHubItemsTagUpgradeOnly')]
   [Parameter(ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsTagEnforceScope')]

   ## InstallRepositoryZipFile…
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileProposedScope')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileEnforceScope')]
   # Wenn das Modul schon installiert ist, wird es in diesem Scope aktualisiert
   [Switch]$UpgradeInstalledModule,


   ## InstallGitHubUrl…
   [Parameter(ParameterSetName = 'InstallGitHubUrlUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallGitHubUrlProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubUrlEnforceScope')]

   ## InstallGitHubZip…
   [Parameter(ParameterSetName = 'InstallGitHubZipUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallGitHubZipProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubZipEnforceScope')]

   ## GitHubItemsBranch…
   [Parameter(ParameterSetName = 'GitHubItemsBranchUpgradeOnly')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchEnforceScope')]

   ## GitHubItemsTag…
   [Parameter(ParameterSetName = 'GitHubItemsTagUpgradeOnly')]
   [Parameter(ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsTagEnforceScope')]

   ## InstallRepositoryZipFile…
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileProposedScope')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileEnforceScope')]
   # Installiere alle Module vom heruntergeladenen GitHub Repo
   [Switch]$InstallAllModules,

   ## InstallGitHubUrl…
   [Parameter(ParameterSetName = 'InstallGitHubUrlUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallGitHubUrlProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubUrlEnforceScope')]

   ## InstallGitHubZip…
   [Parameter(ParameterSetName = 'InstallGitHubZipUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallGitHubZipProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubZipEnforceScope')]

   ## GitHubItemsBranch…
   [Parameter(ParameterSetName = 'GitHubItemsBranchUpgradeOnly')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchEnforceScope')]

   ## GitHubItemsTag…
   [Parameter(ParameterSetName = 'GitHubItemsTagUpgradeOnly')]
   [Parameter(ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsTagEnforceScope')]

   ## InstallRepositoryZipFile…
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileProposedScope')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileEnforceScope')]
   # Liste der Modulnamen, die installiert werden sollen
   [String[]]$InstallModuleNames,


   ## InstallGitHubUrl…
   [Parameter(ParameterSetName = 'InstallGitHubUrlUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallGitHubUrlProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubUrlEnforceScope')]

   ## InstallGitHubZip…
   [Parameter(ParameterSetName = 'InstallGitHubZipUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallGitHubZipProposedScope')]
   [Parameter(ParameterSetName = 'InstallGitHubZipEnforceScope')]

   ## GitHubItemsBranch…
   [Parameter(ParameterSetName = 'GitHubItemsBranchUpgradeOnly')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsBranchEnforceScope')]

   ## GitHubItemsTag…
   [Parameter(ParameterSetName = 'GitHubItemsTagUpgradeOnly')]
   [Parameter(ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(ParameterSetName = 'GitHubItemsTagEnforceScope')]

   ## InstallRepositoryZip…
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileUpgradeOnly')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileProposedScope')]
   [Parameter(ParameterSetName = 'InstallRepositoryZipFileEnforceScope')]
   # Ein bestehendes Modul wird zwingend aktualisiert
   [Switch]$Force,

   [Parameter(ParameterSetName = 'PesterGetter')]
   # Liefert das berechnete AllUsers Modul Dir
   [Switch]$GetScopeAllUsers,

   [Parameter(ParameterSetName = 'PesterGetter')]
   # Liefert das berechnete CurrentUser Modul Dir
   [Switch]$GetScopeCurrentUser,

   [Parameter(ParameterSetName = 'PesterTestGithubDownloadOnly')]
   # Testet nur die Berechnung der Download-URL
   # und den Doanlod der zip-Datei
   [Switch]$PesterTestGithubDownloadOnly,

   # Wird zZ genützt, damit das Dummy-PS-Module testweise installiert wurd
   # Sonst wird das Dummy-PS-Module nicht installiert
   [Switch]$PesterIsActive
)


## Config Enums
Enum eModuleScope { Unknown; AllUsers; CurrentUser; System; VSCode; ThirdParty }

## Params in Enum konvertieren
If ([String]::IsNullOrWhiteSpace($ProposedDefaultScope)) {
   $eDefaultScope = $Null
} Else {
   $TmpDefaultScope = [eModuleScope]"$($ProposedDefaultScope)"
   Remove-Variable ProposedDefaultScope; $eDefaultScope = $TmpDefaultScope; Remove-Variable TmpDefaultScope
}

If ([String]::IsNullOrWhiteSpace($EnforceScope)) {
   $eEnforceScope = $Null
} Else {
   $TmpEnforceScope = [eModuleScope]"$($EnforceScope)"
   Remove-Variable EnforceScope; $eEnforceScope = $TmpEnforceScope; Remove-Variable TmpEnforceScope
}



### Config

# Verzeichnisse von GitHub, die bei PS Modul-Installaton nicht kopiert werden
$BlackListDirsRgx = @('^(\\|\.\\)*\.git', '\.vscode')


## Install-Module: Scope
# AllUsers, CurrentUser
$AllUsersModulesDir = "$env:ProgramFiles\WindowsPowerShell\Modules"
$CurrentUserModulesDir = "$home\Documents\WindowsPowerShell\Modules"


## Funktion: Nur Scopes zurückgeben
If ($GetScopeAllUsers) { Return $AllUsersModulesDir }
If ($GetScopeCurrentUser) { Return $CurrentUserModulesDir }




# 200806
Function Has-Value($Data) {
   If ($null -eq $Data) { Return $False }
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

Function Is-Empty($Data) {
   Return !(Has-Value $Data)
}

Function Is-Verbose() {
   $VerbosePreference -eq 'Continue'
}

Function Is-WhatIf() {
   $WhatIfPreference
}


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



#Region GitHub

Function Resolve-GitHub-ZipRepoUri {
<#
.SYNOPSIS
   Resolves the correct GitHub URI for the specified Owner, Repository and Branch.
#>
   [CmdletBinding()]
   [OutputType([System.Uri])]
   Param (
      [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
      [System.String] $OwnerName,

      [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
      [System.String] $RepoName,

      [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
      [System.String] $BranchName = 'master',

      [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
      # eg: 1.3.1
      [System.String] $Tag
   )

   Process {
      If ([String]::IsNullOrWhiteSpace($Tag)) {
         [URI]('https://github.com/{0}/{1}/archive/{2}.zip' -f $OwnerName, $RepoName, $BranchName)
      } Else {
         [URI]('https://github.com/{0}/{1}/archive/{2}.zip' -f $OwnerName, $RepoName, $Tag)
      }
   }
}


# Lädt eine Datei herunter und 'unlocked' sie
Function Download-File-FromUri {
   [CmdletBinding()]
   Param (
      [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
      [URI]$DownloadUrl,

      [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
      [String]$DestinationDir,

      [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
      [String]$DestinationFilename,

      [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Force')]
      # Stoppt das Script bei einem Fehler
      [Switch] $BreakScriptOnDownloadError,

      [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Force')]
      [Switch] $Force,

      [Int]$Ident = 3
   )

   Process {
      ## Fehler prüfen
      # Fehlende $DownloadUrl
      If ($null -eq $DownloadUrl) {
         Log 4 'Download-File-FromUri(): Leere -DownloadUrl erhalten'
         Break Script
      }

      # $DestinationDir ist eine Datei
      If (Test-Path -LiteralPath $DestinationDir -PathType Leaf) {
         Log 4 'Download-File-FromUri(): -DestinationDir muss ein Verzeichnis sein!'
         Break Script
      }

      # $DestinationDir fehlt: erzeugen
      If (-not (Test-Path -LiteralPath $DestinationDir)) {
         $Null = New-Item -Path $DestinationDir -ItemType Directory -Force
      }

      ## Prepare
      # Den Downloaded Dateinamen berechnen
      $DownloadedFileName = Join-Path $DestinationDir $DestinationFilename

      # Wenn die Downloaded Datei schon existiert
      If (Test-Path -LiteralPath $DownloadedFileName) {
         If ($Force) {
            Remove-Item -LiteralPath $DownloadedFileName -Force
         }
         Else {
            Return $DownloadedFileName
         }
      }

      ## Download File
      $Res = Invoke-WebRequest -Uri $DownloadUrl.AbsoluteUri -OutFile $DownloadedFileName -PassThru
   	Switch ($Res.StatusCode) {
	   	200 {
			   # OK
		   }
		   Default {
            Log ($Ident) ('Fehler Download von: {0}' -f $DownloadUrl) -ForegroundColor Yellow
            Log ($Ident) ('> {0}: {1}' -f $Res.StatusCode, $Res.StatusDescription) -ForegroundColor Red
            If ($BreakScriptOnDownloadError) { break Script }
			   Return $Null
	   	}
      }

      Unblock-File -LiteralPath $DownloadedFileName
      Return $DownloadedFileName
   }
}


Function Download-GitHub-Repo {
<#
.SYNOPSIS
   Downloads zip repo from GitHub
.DESCRIPTION
   Downloads zip repo from GitHub
.PARAMETER Owner
   Specifies the owner of the GitHub repository from whom to download the module.
.PARAMETER Repository
   Specifies the GitHub repository name to download.
.PARAMETER Branch
   Default: Master
   Specifies the specific Git repository branch to download.
.PARAMETER DestinationPath
   Specifies the path to the folder in which you want the command to save GitHub repository. Enter the path to a folder, but do not specify a file name or file name extension. If this parameter is not specified, it defaults to the '$env:ProgramFiles\WindowsPowershell\Modules' directory.
.PARAMETER OverrideRepository
   Specifies overriding the repository name when it's expanded to disk. Use this parameter when the extracted Zip file path does not meet your requirements, i.e. when the repository name does not match the Powershell module name.
.PARAMETER Force
   Forces downloading Repo zip File
#>
   [CmdletBinding()]
   Param (
      [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
      [String]$Owner,

      [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
      [String]$Repository,

      [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
      [String]$Branch = 'master',

      [Parameter(ValueFromPipelineByPropertyName)] [ValidateNotNullOrEmpty()]
      [String]$DestinationDir,

      [Parameter(ValueFromPipelineByPropertyName, ParameterSetName = 'Force')]
      [Switch]$Force
   )

   Process {
      $Uri = Resolve-GitHub-ZipRepoUri -Owner $Owner -Repository $Repository -Branch $Branch
      Download-File-FromUri -DownloadUrl $Uri -DestinationDir $DestinationDir -DestinationFilename 'GitHubRepo.zip' `
                              -Force:$Force -BreakScriptOnDownloadError
   }
}


#EndRegion GitHub



# Extrahiert ein Zip-File in ein Ziel-Dir
# Debugged: OK
Function Extract-Zip() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [String]$ZipFile,
      [Parameter(Mandatory)]
      [String]$ZielDir,
      [Switch]$Force = $True
   )

   # Wenn das ZielDir bereits existiert
   If (Test-Path -LiteralPath $ZielDir) {
      If ($Force) {
         Remove-Item -LiteralPath $ZielDir -Recurse -Force
      } Else {
         Log 4 ("ZielDir existiert bereits: {0}`n-Force nützen!" -f $ZielDir)
      }
   }

   If (Test-Path -LiteralPath $ZipFile -PathType Leaf) {
      Try {
         $oZip = [System.IO.Compression.ZipFile]::OpenRead($ZipFile);

         [System.IO.Compression.ZipFileExtensions]::ExtractToDirectory($oZip, $ZielDir)

         ## !Ex
         # Extract all txt files
         # $oZip.Entries | Where-Object Name -like *.txt | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$extractPath\$($_.Name)", $true) }
         # Extract all files modified last month
         # $oZip.Entries | Where-Object { $_.LastWriteTime.DateTime -gt (Get-Date).AddMonths(-1) } | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$extractPath\$($_.Name)", $true) }

      }
      Finally {
         $oZip.Dispose()
      }
   } Else {
      Log 4 ('File existiert nicht: {0}' -f $ZipFile)
   }
}



# Erzeugt ein Verzeichnis und stoppt, wenn wir PermissionDenied erhalten
# Debugged: OK
Function New-Dir-Check-Permission($NewDir) {
   Try {
      $Null = New-Item -ItemType Directory -Path $NewDir -Force -EA Stop
   }
   Catch {
      # $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
      # $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
      If ($_.CategoryInfo.Category -eq 'PermissionDenied') {
         Log 4 'Kein Schreibrecht!, als Admin starten!' -ForegroundColor Red
         Log 4 'Abbruch.' -ForegroundColor Red
         Break script
      }
   }
}


# Löscht ein Verzeichnis und stoppt, wenn wir PermissionDenied erhalten
# Debugged: OK
Function Del-Dir-Check-Permission() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [PSCustomObject]$DelDir,
      # Abbruch des Scripts bei einem Fehler?
      [Switch]$AbortOnError
   )

   Try {
      $Null = Remove-Item -LiteralPath $DelDir -Recurse -Force -EA Stop
   }
   Catch {
      # $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
      # $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
      If ( @('PermissionDenied', 'WriteError') -contains $_.CategoryInfo.Category) {
         Log 4 'Konnte das Verzeichnis nicht löschen:' -ForegroundColor Red
         Log 4 "$DelDir" -ForegroundColor Yellow
         If ($AbortOnError) {
            Break Script
         }
      }
   }
}


# Löscht ein PowerShell-Modul, indem das ganze Verzeichnis gelöscht wird
#
# ModuleRootDir: Verzeichnis, in dem das Modul installiert ist
#     C:\Users\schittli\Documents\WindowsPowerShell\Modules\ImportExcel\7.8.2
# Debugged: OK
Function Delete-Module() {
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '')]
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory, ParameterSetName = 'oGitHubModule')]
      [PSCustomObject]$oGitHubModule,
      [Parameter(Mandatory, ParameterSetName = 'oInstalledModule')]
      [PSCustomObject]$oInstalledModule,
      [Parameter(Mandatory, ParameterSetName = 'ModuleDir')]
      [String]$ModuleName,
      [Parameter(Mandatory, ParameterSetName = 'ModuleDir')]
      [String]$ModuleDir,
      # Abbruch des Scripts bei einem Fehler?
      [Switch]$AbortOnError
   )

   ## Prepare
   Switch ($PsCmdlet.ParameterSetName) {
     'oGitHubModule' {
         $ModulName = $oGitHubModule.ModuleName
         $ModuleRootDir = $oGitHubModule.ModuleRootDir
      }
      'oInstalledModule' {
         # RootModule: GitHubRepository.psm
         $ModulName = [IO.Path]::GetFileNameWithoutExtension($oInstalledModule.RootModule)
         $ModuleRootDir = $oInstalledModule.ModuleBase
      }
      'ModuleDir' {
         $ModulName = $ModuleName
         $ModuleRootDir = $ModuleDir
      }
   }

   ## Das Modul entladen
   Log -IfVerbose 0 "Entlade Modul: $ModulName"
   Remove-Module -Name $ModulName -Force -EA SilentlyContinue

   # eg ModuleRootDir (Alias: ModuleBase)
   # C:\Users\schittli\Documents\WindowsPowerShell\Modules\ImportExcel\7.8.2
   ## Das Modul aus dem Verzeichns löschen
   If (Test-Path -LiteralPath $ModuleRootDir) {
      Del-Dir-Check-Permission -DelDir $ModuleRootDir -AbortOnError:$AbortOnError
   } Else {
      # Bereits OK
      # Log 4 ('Verzeichnis existiert nicht: {0}' -f $oGitHubModule.ModuleRootDir)
   }
}


# Sucht in einem Verzeichnis alle psd1 Files, um PowerShell Module zu finden
# Debugged: OK
Function Find-PSD1-InDir() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [String]$Dir
   )
   Get-ChildItem -Recurse -LiteralPath $Dir -Filter *.psd1 | % {
      $PSDData = Import-PowerShellDataFile -LiteralPath $_.FullName
      # Name                           Value
      # ----                           ---- -
      # Copyright                      (c) 2016 Iain Brighton. All rights reserved.
      # Description                    Downloads and installs PowerShell modules and DSC resources directly from GitHub.
      # PrivateData { PSData }
      # PowerShellVersion              4.0
      # CompanyName                    Iain Brighton
      # GUID                           0027d388-f938-411a-b48e-282dc2668f2c
      # Author                         Iain Brighton
      # FunctionsToExport { Install-GitHubRepository }
      # RootModule                     GitHubRepository.psm1
      # ModuleVersion                  1.2.0

      $ModuleInstallSubDir = Join-Path $_.BaseName ([String]$PSDData.ModuleVersion)
      [PSCustomObject][Ordered]@{
         # GitHubRepository
         ModuleName     = $_.BaseName
         # C:\Temp\...\GitHubRepository-master\GitHubRepository.psd1
         Psd1FileName   = $_.FullName
         # Typ: FileInfo
         oPsd1File      = $_
         PSDData        = $PSDData
         # Das Verzeichnis mit dem Root des Moduls
         # C:\Temp\...\\GitHubRepository-master
         ModuleRootDir      = $_.DirectoryName
         # Das Unterverzeichnis, in dem das Modul installiert wird
         # <ModulName>\<Version>
         ModuleInstallSubDir = $ModuleInstallSubDir
      }
   }
}


# Vergleicht zwei [Version] Objs
Enum eVersionCompare { Equal; LeftIsNewer; RightIsNewer}
# Debugged: OK
Function Compare-Version() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [AllowNull()][Version]$vLeft,
      [Parameter(Mandatory)]
      [AllowNull()][Version]$vRight
   )

   If ($vLeft -eq $vRight) { Return [eVersionCompare]::Equal }

   If ($null -eq $vLeft) { Return [eVersionCompare]::RightIsNewer }
   If ($null -eq $vRight) { Return [eVersionCompare]::LeftIsNewer }

   If ($vLeft -gt $vRight) {
      Return [eVersionCompare]::LeftIsNewer
   } Else {
      Return [eVersionCompare]::RightIsNewer
   }
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


# Join-Path-Funktion, die mit Argumen-Fehlern klarkommt
# Debugged: OK
Function Join-Path() {
   [CmdletBinding()]
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '')]
   Param(
      [Parameter(Mandatory)][AllowEmptyString()][String]$Item1,
      [Parameter(Mandatory)][AllowEmptyString()][String]$Item2
   )

   # Ohne Item1 und ohne Item2 haben wir nichts
   If ( [String]::IsNullOrWhiteSpace($Item1) -and [String]::IsNullOrWhiteSpace($Item2) ) { Return $Null }

   # Wenn eines null ist, das andere zurückgeben
   If ([String]::IsNullOrWhiteSpace($Item1)) { Return $Item2 }
   If ([String]::IsNullOrWhiteSpace($Item2)) { Return $Item1 }
   Microsoft.PowerShell.Management\Join-Path $Item1 $Item2
}


# Kopiert ein Verzeichnis an ein Ziel
# und überspringt Verzeichnisse in der Blacklist
# und optional bereits existierende Files
# -Force: Ziel zuerst löschen
# Debugged: OK
Function Copy-Dir-WithBlackList() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [String]$SrcDir,
      [Parameter(Mandatory)]
      [String]$DstDir,
      # Das oberste Verzeichnis:
      # '^(\\|\.\\)*\.git'
      [String[]]$BlackListDirsRgx,
      [Switch]$Overwrite,
      # Lösct das ZielDir, wenn es schon existiert
      [Switch]$Force
   )

   # \ ergänzen
   $SrcDir = Join-Path $SrcDir '\'
   $DstDir = Join-Path $DstDir '\'

   # Zieldir löschen?
   If ($Force) { Del-Dir-Check-Permission -DelDir $DstDir -AbortOnError }
   # Zieldir erzeugen
   New-Dir-Check-Permission -NewDir $DstDir

   # Alle Files & Dirs von der Quelle kopieren
   Get-ChildItem -LiteralPath $SrcDir -Recurse  -Force | % {
      $ThisItem = $_
      ## Den relativen Pfad zum Ziel berechnen
      If ($ThisItem.PSIsContainer) {
         $RelativeSubDir = $ThisItem.FullName.SubString( $SrcDir.Length )
      } Else {
         # $RelativeSubItem = $ThisItem.DirectoryName.SubString( $SrcDir.Length )
         $RelativeSubDir = SubString $ThisItem.DirectoryName $SrcDir.Length
         $RelativeFileName = SubString $ThisItem.FullName $SrcDir.Length
      }

      # Ist das Zielverzeichnis blacklisted?
      $IsBlacklisted = @($BlackListDirsRgx | ? { $RelativeSubDir -match $_ })
      If ($IsBlacklisted.Count -gt 0) {
         If ([String]::IsNullOrWhiteSpace($RelativeFileName)) {
            Log -IfVerbose 0 ('Blacklisted: {0}' -f $RelativeSubDir)
         } Else {
            Log -IfVerbose 0 ('Blacklisted: {0}' -f $RelativeFileName)
         }
      } Else {
         # Haben wir ein Verzeichnis?
         If ($ThisItem.PSIsContainer) {
            # Ein Verzeichnis? > Erzeugen
            $ZielDir = Join-Path $DstDir $RelativeSubDir
            Log -IfVerbose 0 ('Erzeuge: {0}' -f $ZielDir)
            New-Dir-Check-Permission -NewDir $ZielDir
         } Else {
            # Eine Datei? > Kopieren
            $RelativeZielFile = Join-Path $RelativeSubDir $ThisItem.Name
            Log -IfVerbose 0 ('Kopiere: {0}' -f $RelativeZielFile)
            $ZielFile = Join-Path $DstDir $RelativeZielFile
            # Wenn sie schon existiert: Überschreiben?
            If ((Test-Path -LiteralPath $ZielFile) -and ($Overwrite -eq $False)) {
               # Dieses Pipeline-Element überspringen
               Return
            }
            # Copy-Item -LiteralPath $ThisItem -Destination $ZielFile
            $Null = $ThisItem.CopyTo($ZielFile, $True)
         }
      }
   }
}


# Liefert von einem installieren Modul den Scope
#
# ModuleBase: Verzeichnis, in dem das Modul insalliert ist:
# eg: C:\Users\schittli\Documents\WindowsPowerShell\Modules\ImportExcel\7.8.2
#
# > C:\Users\schittli\Documents\WindowsPowerShell\Modules
# Debugged: OK
Function Get-Module-ScopeDir() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)][PSModuleInfo]$oModule
   )
   $ModulesDir = (Get-Item -LiteralPath $oModule.ModuleBase -EA SilentlyContinue).Parent.Parent.FullName
   If ($ModulesDir) {
      # \ Ergänzen
      $ModulesDir = Join-Path $ModulesDir '\'
      $ModulesDir
   }
}


# Löscht allenfalls ein vorhandenes Modul
# und installiert die neue Version
Function Upgrade-Module() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)][PSCustomObject]$oGitHubModule,
      # Wir installieren das Modul in den gewünschten Scope
      [Parameter(Mandatory, ParameterSetName = 'InstallToScope')]
      [eModuleScope]$eInstallScope,
      # Das Modul ist schon installiert und wir prüfen, ob es aktualisiert werden muss
      [Parameter(Mandatory, ParameterSetName = 'InstallToInstalledModule')]
      [PSModuleInfo]$oInstalledModule,
      # Liste von Verzeichnissen, die für die Modul-Installaton nicht kopiert werden
      # Das oberste Verzeichnis:
      # '^(\\|\.\\)*\.git'
      [String[]]$BlackListDirsRgx,
      # Wenn true, dann wird das Modul immer neu installiert, auch wenn es schon aktuell ist
      [Switch]$Force,

      [Int]$Ident = 3
   )

   Switch ($PsCmdlet.ParameterSetName) {
      'InstallToScope' {
         # Debugged: OK
         $ZielDir = Join-Path (Get-ModuleScope-Dir $eInstallScope) $oGitHubModule.ModuleInstallSubDir

         # Existiert Modul bereits?
         If (Test-Path -LiteralPath $ZielDir) {
            # Die Modulversion muss nicht geprüft werden, weil das Verzeichnis anhand von $oGitHubModule erstellt wird
            If ($Force) {
               # Modul löschen
               Delete-Module -ModuleName $oGitHubModule.ModuleName -ModuleDir $ZielDir -AbortOnError
               If (Test-Path -LiteralPath $ZielDir) {
                  # Das Modul existiert immer noch
                  Log 4 ('Konnte das installierte Modul nicht löschen: {0}' -f $oGitHubModule.ModuleRootDir)
                  Return
               }
            } Else {
               # Das Modul ist bereits installiert
               Return
            }
         }

         # Das Modul Installieren
         Copy-Dir-WithBlackList -SrcDir $oGitHubModule.ModuleRootDir -DstDir $ZielDir `
                                 -BlackListDirsRgx $BlackListDirsRgx
      }


      'InstallToInstalledModule' {
         # Debugged: OK
         # Ist das bereits installierte Modul veraltet?
         Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $oInstalledModule.Version) ) {
            ([eVersionCompare]::Equal) {
               # Log ($Ident) 'Bereits aktuell (2)'
               If ($Force) {
                  # Log ($Ident+1) '> forciere Installation'
                  # Modul löschen
                  Delete-Module -oInstalledModule $oInstalledModule
                  If (Test-Path -LiteralPath $oInstalledModule.ModuleBase) {
                     # Das Modul existiert immer noch
                     Log 4 ('Konnte das installierte Modul nicht löschen: {0}' -f $oInstalledModule.ModuleBase)
                     Return
                  }
                  # Das Modul Installieren
                  Copy-Dir-WithBlackList -SrcDir $oGitHubModule.ModuleRootDir -DstDir $oInstalledModule.ModuleBase `
                     -BlackListDirsRgx $BlackListDirsRgx
               } Else {
                  Log ($Ident+1) '-Force wurde nicht angegeben > Modul wird nicht aktualisiert' -ForegroundColor Red
               }
            }

            ([eVersionCompare]::LeftIsNewer) {
               Log ($Ident) 'Veraltet'
               Log ($Ident+1) ('Installiert: {0} - GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               If ($Force) {
                  # Modul aktualisieren
                  Log ($Ident+1) '> Upgrade Module'
                  Delete-Module -oInstalledModule $oInstalledModule
                  If (Test-Path -LiteralPath $oInstalledModule.ModuleBase) {
                     # Das Modul existiert immer noch
                     Log 4 ('Konnte das installierte Modul nicht löschen: {0}' -f $oInstalledModule.ModuleBase)
                     Return
                  }

                  # Das Modul in den Scope des bereits installierten Moduls installieren
                  $ZielDir = Join-Path (Get-ModuleScope-Dir $oInstalledModule.eModuleScope) $oGitHubModule.ModuleInstallSubDir
                  Copy-Dir-WithBlackList -SrcDir $oGitHubModule.ModuleRootDir -DstDir $ZielDir `
                                         -BlackListDirsRgx $BlackListDirsRgx
               } Else {
                  Log ($Ident) '-Force wurde nicht angegeben > Modul wird nicht aktualisiert' -ForegroundColor Red
               }
            }

            ([eVersionCompare]::RightIsNewer) {
               Log ($Ident) '  Lokale Version ist neuer!'
               Log ($Ident+1) ('   Installiert: {0} - GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               Log ($Ident+1) 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
            }
         }

      }
   }

}


# Liefert von einem [eModuleScope] das Scope-Verzeichnis
Function Get-ModuleScope-Dir([eModuleScope]$eScope) {
   Switch ($eScope) {
      ([eModuleScope]::AllUsers) { Return (Join-Path $AllUsersModulesDir '\') }
      ([eModuleScope]::CurrentUser) { Return (Join-Path $CurrentUserModulesDir '\') }
      Default { Return $Null }
   }
}


# Liefert von einem Verzeichnis den [eModuleScope] Typ
Function Get-ModuleScope-Type($ScopeDir) {
   If ([String]::IsNullOrWhiteSpace($ScopeDir)) { Return [eModuleScope]::Unknown }

   # \ ergänzen
   $ScopeDir = Join-Path $ScopeDir '\'

   If ($ScopeDir.StartsWith($AllUsersModulesDir)) { Return [eModuleScope]::AllUsers }
   If ($ScopeDir.StartsWith($CurrentUserModulesDir)) { Return [eModuleScope]::CurrentUser }
   Return [eModuleScope]::Unknown
}


# Gibt einen Fehler, wenn $_ ungleich $null ist und nicht einem [eModuleScope]:: entspricht
Filter Assert-eModuleScope {
   If ($_ -ne $Null) {
      If ($_.GetType().Name -ne 'eModuleScope') {
         Log 4 "Müsste ein [eModuleScope] sein: $($_)"
      }
   }
}


# Prüft, ob für das von GitHub heruntergeladenes Modul
# in 1 PS Module Scope installiert werden kann / muss
Function Check-Install-GitHubModule() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      # Das zu installierende Modul von GitHub
      [PSCustomObject]$oGitHubModule,
      [Parameter(Mandatory)]
      [PSModuleInfo]$oInstalledModule,
      # Wenn das Modul noch nicht schon installiert ist, wird dieser Scope benützt
      [Object]$eDefaultScope,
      # Auch wenn das Modul schon in einem anderen Scope installiert ist, wird es trotzdem in diesem Scope installiert
      [Object]$eEnforceScope,
      # Aktualisiert das Modul, wenn es bereits installiert ist
      [Switch]$UpgradeInstalledModule,
      # Das oberste Verzeichnis:
      # '^(\\|\.\\)*\.git'
      [String[]]$BlackListDirsRgx,
      # Erzwingt die Installation immer
      [Switch]$Force,
      [Int]$Ident = 3
   )

   # Das Modul ist in einem Scope installiert
   # Das Scope-Dir bestimmen
   $InstalledModuleScopeDir = Get-Module-ScopeDir -oModule $oInstalledModule
   $InstalledeModuleScopeType = Get-ModuleScope-Type -ScopeDir $InstalledModuleScopeDir

   # Ist das Modul im gewünschten Scope?
   $IsInRightScope = $True
   If ($null -eq $eDefaultScope -and $null -eq $eEnforceScope) {
      $IsInRightScope = $True
   } ElseIf ($eEnforceScope -and ($InstalledeModuleScopeType -ne $eEnforceScope)) {
      $IsInRightScope = $False
   }

   # Ist das installierte Modul veraltet?
   $UpgradeExistingModule = $False
   Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $oInstalledModule.Version) ) {
            ([eVersionCompare]::Equal) {
         Log ($Ident) 'Modul ist bereits aktuell' -ForegroundColor Green
         # Wenn installierte Module zwingend installiert werden sollen
         If ($IsInRightScope) {
            If ($Force) {
               Log ($Ident+1) '> Forciere Neuinstallation' -ForegroundColor Magenta
               $UpgradeExistingModule = $True
            }
         } Else {
            # Wenn das Modul nicht im richtigen Scope ist,
            # die schon richtige Version nur bei -Force aktualisieren
            If ($UpgradeInstalledModule -and $Force) {
               Log ($Ident + 1) '> Forciere Neuinstallation' -ForegroundColor Magenta
               $UpgradeExistingModule = $True
            }
         }
      }

      ([eVersionCompare]::LeftIsNewer) {
         Log ($Ident) 'Veraltet'
         Log ($Ident+1) ('Version installiert: {0} - Version GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
         If ($UpgradeInstalledModule -or ($IsInRightScope -and $Force)) {
            If ($Force) { Log ($Ident+1) '> Forciere Neuinstallation' }
            Else { Log ($Ident+1) '> Aktualisiere Modul' }
            $UpgradeExistingModule = $True
         }
         Else {
            Log ($Ident) '-UpgradeInstalledModule wurde nicht angegeben' -ForegroundColor Red
            Log ($Ident+1) 'Modul wird nicht aktualisiert' -ForegroundColor Red
         }
      }

      ([eVersionCompare]::RightIsNewer) {
         Log ($Ident) 'Lokale Version ist neuer!'
         Log ($Ident+1) ('   Version installiert: {0} - Version GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
         Log ($Ident+1) 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
      }
   }
   # Das installierte Modul aktualisieren
   If ($UpgradeExistingModule) {
      # Das Modul aktualisieren
      Upgrade-Module -oGitHubModule $oGitHubModule -oInstalledModule $oInstalledModule `
         -BlackListDirsRgx $BlackListDirsRgx `
         -Force:$True
   }

   # Das Modul im richtigen Scope installieren
   If ($IsInRightScope -eq $False) {
      If ($eEnforceScope) { $eZielScope = $eEnforceScope }
      Else { $eZielScope = $eDefaultScope }
      Upgrade-Module -oGitHubModule $oGitHubModule `
         -eInstallScope $eZielScope `
         -BlackListDirsRgx $BlackListDirsRgx `
         -Force:$Force
   }
}



# Prüft, ob für das von GitHub heruntergeladenes Modul
# in 1 oder mehreren PS Module Scopes installiert werden kann / muss
Function Check-Install-GitHubModules() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      # Das zu installierende Modul von GitHub
      [PSCustomObject]$oGitHubModule,
      [Parameter(Mandatory)]
      # Die Liste der installierten Module
      [Array]$oModulesList,
      # Wenn das Modul noch nicht schon installiert ist, wird dieser Scope benützt
      [Object]$eDefaultScope,
      # Auch wenn das Modul schon in einem anderen Scope installiert ist, wird es trotzdem in diesem Scope installiert
      [Object]$eEnforceScope,
      # Aktualisiert das Modul, wenn es bereits installiert ist
      [Switch]$UpgradeInstalledModule,
      # Das oberste Verzeichnis:
      # '^(\\|\.\\)*\.git'
      [String[]]$BlackListDirsRgx,
      # Erzwingt die Installation immer
      [Switch]$Force,
      [Int]$Ident = 3
   )


   ## Prepare
   $eDefaultScope | Assert-eModuleScope
   $eEnforceScope | Assert-eModuleScope

   # Ist das Modul bereits installiert?
   $InstalledModules = @($oModulesList | ? Name -eq $oGitHubModule.ModuleName)

   Switch ($InstalledModules.Count) {
      0 {
         Log ($Ident) 'Modul ist noch nicht installiert'
         If ($eEnforceScope) { $eZielScope = $eEnforceScope }
         Else { $eZielScope = $eDefaultScope }
         If ($eZielScope) {
            Log ($Ident + 1) ('Installiere Modul, Ziel: {0}' -f $eZielScope) -ForegroundColor Yellow
            Upgrade-Module -oGitHubModule $oGitHubModule `
                           -eInstallScope $eZielScope `
                           -BlackListDirsRgx $BlackListDirsRgx `
                           -Force:$Force
         } Else {
            Log 4 'Kein Ziel-Scope angegeben (-ProposedDefaultScope / -EnforceScope)'
         }
      }

      1 {
         Log ($Ident) 'Modul ist in diesem PS Modul-Scope installiert:'
         $ThisInstalledModule = $InstalledModules[0]
         Log ($Ident+1) $ThisInstalledModule.ModuleBase -ForegroundColor White

         Check-Install-GitHubModule -oGitHubModule $oGitHubModule -oInstalledModule $ThisInstalledModule `
                                    -eDefaultScope $eDefaultScope -eEnforceScope $eEnforceScope `
                                    -UpgradeInstalledModule:$UpgradeInstalledModule `
                                    -BlackListDirsRgx $BlackListDirsRgx -Force:$Force
      }

      Default {
         # Das Modul ist in mehreren Scopes installiert
         Log ($Ident) ' Das Modul ist in mehreren PS Modul-Scopes installiert'
         ForEach ($InstalledModule in $InstalledModules) {
            # $ThisModuleScopeDir = ($InstalledModule.ModuleBase -split '\\' | select -SkipLast 2) -join '\'
            Log ($Ident+1) (' {0}' -f $InstalledModule.ModuleBase) -NoNewline

            Check-Install-GitHubModule -oGitHubModule $oGitHubModule -oInstalledModule $InstalledModule `
               -eDefaultScope $eDefaultScope -eEnforceScope $eEnforceScope `
               -UpgradeInstalledModule:$UpgradeInstalledModule `
               -BlackListDirsRgx $BlackListDirsRgx -Force:$Force
         }
      }
   }

}



# Berechnet für jedes Modul den Scope, in dem es installiert ist
Function Add-Module-ScopeData() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)][Array]$ModuleList,
      [Parameter(Mandatory)][String]$AllUsersScope,
      [Parameter(Mandatory)][String]$CurrentUserScope
   )

   # \ Append
   $AllUsersScope = Join-Path $AllUsersScope '\'
   $CurrentUserScope = Join-Path $CurrentUserScope '\'

   $ModuleList | % {
      $InstalledModuleScopeDir = Get-Module-ScopeDir -oModule $_

      If ($InstalledModuleScopeDir.StartsWith('C:\WINDOWS\system32\WindowsPowerShell\v1.0\')) {
         $InstalledScope = [eModuleScope]::System
      } ElseIf ($InstalledModuleScopeDir.StartsWith($AllUsersScope)) {
         $InstalledScope = [eModuleScope]::AllUsers
      } ElseIf ($InstalledModuleScopeDir.StartsWith($CurrentUserScope)) {
         $InstalledScope = [eModuleScope]::CurrentUser
      } ElseIf ($InstalledModuleScopeDir -like '*.vscode*') {
         $InstalledScope = [eModuleScope]::VSCode
      } Else {
         $InstalledScope = [eModuleScope]::ThirdParty
      }
      $_ | Add-Member -MemberType NoteProperty -Name eModuleScope -Value $InstalledScope
      $_ | Add-Member -MemberType NoteProperty -Name ModuleScopeDir -Value $InstalledModuleScopeDir
   }
}


# Erzeugt aus einem String[] eine Liste von PSCustomObject
# Debugged: OK
Function Array-ToObj() {
   [CmdletBinding()]
   Param(
      [String[]]$Items
   )
   Begin {}
   Process {
      ForEach ($Item in $Items) {
         [PSCustomObject][Ordered]@{
            Item = $Item
         }
      }
   }

   End {}
}

Function Get-TempDir() {
   New-TemporaryFile | % { rm $_; mkdir $_ }
}


# Erzeugt aus diesen URL-Typen die Download-URL für das Repository zip File:
#   https://github.com/rtCamp/login-with-google
#   https://github.com/rtCamp/login-with-google/tree/develop
#   https://github.com/rtCamp/login-with-google/releases/tag/1.3.1
#
Function Get-GitHubUrl-RepoZipUri($GitHubUrl) {
   $UriSegments = [URI]$GitHubUrl | select -ExpandProperty Segments | % { $_.Trim('/') }
   Switch ($UriSegments.Count) {
      3 {
         #   https://github.com/rtCamp/login-with-google
         # > https://github.com/rtCamp/login-with-google/archive/master.zip
         [URI]('https://github.com/{0}/{1}/archive/master.zip' -f $UriSegments[1], $UriSegments[2])
      }
      5 {
         #   https://github.com/rtCamp/login-with-google/tree/develop
         # > https://github.com/rtCamp/login-with-google/archive/develop.zip
         [URI]('https://github.com/{0}/{1}/archive/{2}.zip' -f $UriSegments[1], $UriSegments[2], $UriSegments[4])
      }
      6 {
         #   https://github.com/rtCamp/login-with-google/releases/tag/1.3.1
         # > https://github.com/rtCamp/login-with-google/archive/1.3.1.zip
         [URI]('https://github.com/{0}/{1}/archive/{2}.zip' -f $UriSegments[1], $UriSegments[2], $UriSegments[5])
      }
   }
}

# Liefert die Anzal Objekte, $null == 0
Function Count($Obj) {
   ($Obj | measure).Count
}



### Prepare

Log 0 'Initialisierung'
Add-Type -AssemblyName 'System.IO.Compression';
Add-Type -AssemblyName 'System.IO.Compression.FileSystem';


## Die Liste der Modul-Namen, die der User installiert haben möchte
$oInstallModuleNames = Array-ToObj ($InstallModuleNames | ? { -not [String]::IsNullOrWhiteSpace($_) })
# um zu erfassen, ob ein Modul in GitHub gefunden wurde
$oInstallModuleNames | Add-Member -MemberType NoteProperty -Name FoundOnGitHub -Value $False

# $HasInstallModuleNames = Count $oInstallModuleNames
# If ($HasInstallModuleNames -eq $False -And $InstallAllModules -eq $False) {
#    Log 1 '-InstallModuleNames nicht angegeben > aktiviere -InstallAllModules' -ForegroundColor Red
#    $InstallAllModules = $True
# }


## Wurde mind. 1 Parameter definiert, der eine Modulinstallation verlangt?
If ($PesterIsActive -eq $false `
   -and $PesterTestGithubDownloadOnly -eq $false `
   -and $UpgradeInstalledModule -eq $False `
   -and $InstallAllModules -eq $False `
   -and ($oInstallModuleNames | Measure).Count -eq 0) {

   Log 1 'Fehler: ' -ForegroundColor Red -NoNewline
   Log 1 'Mindestens einer dieser Parameter muss angegeben werden:' -Append
   '-UpgradeInstalledModule','-InstallAllModules','-InstallModuleNames' | % {
      Log 2 $_
   }
   Log 1 'Abbruch' -ForegroundColor Red
   Break Script
}


# Erzeuge ein temporäre Verzeichnis
$TempDirRoot = Get-TempDir
$TempDirForZipFile = Join-Path $TempDirRoot 'ZipFile'
$TempDirExtractedZip = Join-Path $TempDirRoot 'Extracted'


### Haben wir eine Repository-URL erhalten?
If ([String]::IsNullOrWhiteSpace($GitHubRepoUrl) -eq $False) {
   ## Wir haben erhalten: $GitHubRepoUrl
   Log 1 'Download GitHub Repository'
   # Versuchen, die DL Zip URL herauszufinden
   $RepoZipUri = Get-GitHubUrl-RepoZipUri $GitHubRepoUrl
   # Download starten
   $RepositoryZipFileName = Download-File-FromUri -DownloadUrl $RepoZipUri `
                                 -DestinationDir $TempDirForZipFile -DestinationFilename 'GitHubRepo.zip' `
                                 -Force:$Force -BreakScriptOnDownloadError

} ElseIf ([String]::IsNullOrWhiteSpace($GitHubZipUrl) -eq $False) {
   ## Wir haben erhalten: $GitHubZipUrl
   Log 1 'Download GitHub Repository'
   # Download starten
   $RepositoryZipFileName = Download-File-FromUri -DownloadUrl $GitHubZipUrl `
                                 -DestinationDir $TempDirForZipFile -DestinationFilename 'GitHubRepo.zip' `
                                 -Force:$Force -BreakScriptOnDownloadError

} ElseIf ([String]::IsNullOrWhiteSpace($GitHubOwnerName) -eq $False) {
   ## Wir haben erhalten: $GitHubOwnerName
   Log 1 'Download GitHub Repository'

   # Versuchen, die DL Zip URL herauszufinden
   If ([String]::IsNullOrWhiteSpace($GitHubBranchName) -eq $False) {
      ## $GitHubOwnerName mit einem $GitHubBranchName
      $RepoZipUri = Resolve-GitHub-ZipRepoUri -OwnerName $GitHubOwnerName `
                                  -RepoName $GitHubRepoName `
                                  -BranchName $GitHubBranchName
   } Else {
      ## $GitHubOwnerName mit einem $GitHubTag
      $RepoZipUri = Resolve-GitHub-ZipRepoUri -OwnerName $GitHubOwnerName `
                                   -RepoName $GitHubRepoName `
                                   -Tag $GitHubTag
   }
   ## Download starten
   $RepositoryZipFileName = Download-File-FromUri -DownloadUrl $RepoZipUri `
                                    -DestinationDir $TempDirForZipFile `
                                    -DestinationFilename 'GitHubRepo.zip' `
                                    -Force:$Force -BreakScriptOnDownloadError
}


## Wenn Pester nur den Download testet, dann sind wir fertig
If ($PesterTestGithubDownloadOnly) {
   Return $RepositoryZipFileName
}


# !KH
# $PathResoved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath);


## Alle installierten Module suchen
Log 1 'Analysiere installierte PS Module'
$AllInstalledModules = Get-Module -ListAvailable -Verbose:$False
# Metadaten ergänzen
Add-Module-ScopeData -ModuleList $AllInstalledModules -AllUsersScope $AllUsersModulesDir -CurrentUserScope $CurrentUserModulesDir
# Uns interessieren nur AllUsers und CurrentUser
$AllUsersAndCurrentUserModules = $AllInstalledModules | ? { @([eModuleScope]::AllUsers, [eModuleScope]::CurrentUser) -contains $_.eModuleScope }



### Main

Log 0 'Prüfe Modul-Installation'

Try {

   ## Ist die zip Datei vorhanden?
   If (-not(Test-Path -LiteralPath $RepositoryZipFileName -PathType Leaf)) {
      Log 4 ('Zip-Datei nicht gefunden: {0}' -f $RepositoryZipFileName) -ForegroundColor Red
      Break Script
   }

   ## Zip extrahieren
   Extract-Zip -ZipFile $RepositoryZipFileName -ZielDir $TempDirExtractedZip

   ## im entpackten Zip PS Module suchen
   $FoundGitHubModules = Find-PSD1-InDir -Dir $TempDirExtractedZip

   ## Alle gefundenen PS Module verarbeiten

   $HasProposedDefaultScope = $eDefaultScope -ne $null
   $HasEnforceScope = $eEnforceScope -ne $null

   ForEach ($FoundGitHubModule in $FoundGitHubModules) {
      Log 1 ('Modul: {0}' -f $FoundGitHubModule.ModuleName)

      # Das Dummy-PS-Module überspringen, ausser Pester ist aktiv
      If (($FoundGitHubModule.ModuleName -eq 'Dummy-PS-Module') `
            -and ($PesterIsActive -eq $False)) {
         Continue
      }

      ## Finden wir das GitHub Modul in der gewünschten Installationsliste?
      $oModuleToInstall = $oInstallModuleNames | ? Item -eq $FoundGitHubModule.ModuleName
      # Das gewünschte Modul als gefunden markieren
      $oModuleToInstall | % { $_.FoundOnGitHub = $True }
      $IsInExplicitList = (Count $oModuleToInstall) -gt 0

      # Ist das Modul bereits installiert?
      $IsModuleInstalled = (Count ($AllUsersAndCurrentUserModules | ? Name -eq $FoundGitHubModule.ModuleName) -gt 0)

      If ($InstallAllModules -or $IsInExplicitList `
            -or ($IsModuleInstalled -and $UpgradeInstalledModule)) {
         Log 2 'Prüfe Installation'
         Log -IfVerbose 3 (' GitHub-Modul:')
         Log -IfVerbose 3 (' Modulname: {0}' -f $oGitHubModule.ModuleName)
         Log -IfVerbose 3 (' Version  : {0}' -f $oGitHubModule.PSDData.ModuleVersion)
         Log -IfVerbose 3 (' Quell-Dir: {0}' -f $oGitHubModule.ModuleRootDir)

         Check-Install-GitHubModules -oGitHubModule $FoundGitHubModule -oModulesList $AllUsersAndCurrentUserModules `
            -eDefaultScope $eDefaultScope -eEnforceScope $eEnforceScope `
            -UpgradeInstalledModule:$UpgradeInstalledModule `
            -BlackListDirsRgx $BlackListDirsRgx `
            -Force:$Force

      } Else {
         If ($UpgradeInstalledModule -and $IsModuleInstalled -eq $False) {
            Log 2 ('Skipped, Modul ist nicht installiert')
         } Else {
            Log 2 ('Skipped, nicht in der gewünschten Modulliste')
         }
      }
   }


   ## Wollte der User Module installieren, die das GitHub Repo nicht hat?
   $MissingGithubModules = $oInstallModuleNames | ? FoundOnGitHub -eq $False
   If ($MissingGithubModules) {
      Log 0 'Diese Module sind nicht im GitHub-Repository' -ForegroundColor Red
      $MissingGithubModules | % { Log 1 " $($_.Item)" }
   }

} Catch {
   $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
   $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
   $ExceptionStackTrace = $_.Exception.StackTrace
   Write-Host ('{0}: {1}' -f $MessageId, $ErrorMessage)
   Write-Host "`nErrorDetails"
   Write-Host $_.ErrorDetails
   Write-Host "`nScriptStackTrace"
   Write-Host $_.ScriptStackTrace
   Write-Host "`nExceptionStackTrace"
   Write-Host $ExceptionStackTrace
   Write-Host "`nStackTrace"
   Write-Host $StackTrace

} Finally {
   # Das Arbeitsverzeichnis löschen
   Remove-Item -LiteralPath $TempDirRoot -Recurse -Force -EA SilentlyContinue
}
