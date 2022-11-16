#
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
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubUrlProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubZipProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagProposedScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallRepositoryZipFileProposedScope')]
   # Wenn das Modul noch nicht installiert ist, dann wird dieser Scope genützt
   [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   [Alias('DefaultScope')]
   [AllowEmptyString()][String]$ProposedDefaultScope,

   ## Mix der verschiedenen ParameterSets
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubUrlEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'InstallGitHubZipEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsBranchEnforceScope')]
   [Parameter(Mandatory, ParameterSetName = 'GitHubItemsTagEnforceScope')]

   [Parameter(Mandatory, ParameterSetName = 'InstallRepositoryZipFileEnforceScope')]
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
   [Switch]$PesterTestGithubDownloadOnly
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
      [Switch] $Force
   )

   Process {
      ## Fehler prüfen
      # Fehlende $DownloadUrl
      If ($null -eq $DownloadUrl) {
         Write-Error 'Download-File-FromUri(): Leere -DownloadUrl erhalten'
         Break Script
      }

      # $DestinationDir ist eine Datei
      If (Test-Path -LiteralPath $DestinationDir -PathType Leaf) {
         Write-Error 'Download-File-FromUri(): -DestinationDir muss ein Verzeichnis sein!'
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
            Write-Host ('Fehler Download von: {0}' -f $DownloadUrl) -ForegroundColor Yellow
            Write-Host ('> {0}: {1}' -f $Res.StatusCode, $Res.StatusDescription) -ForegroundColor Red
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
         Write-Error ("ZielDir existiert bereits: {0}`n-Force nützen!" -f $ZielDir)
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
      Write-Error ('File existiert nicht: {0}' -f $ZipFile)
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
         Write-Host 'Kein Schreibrecht!, als Admin starten!' -ForegroundColor Red
         Write-Host 'Abbruch.' -ForegroundColor Red
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
         Write-Host 'Konnte das Verzeichnis nicht löschen:' -ForegroundColor Red
         Write-Host "$DelDir" -ForegroundColor Yellow
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
   Write-Verbose "Entlade Modul: $ModulName"
   Remove-Module -Name $ModulName -Force -EA SilentlyContinue

   # eg ModuleRootDir (Alias: ModuleBase)
   # C:\Users\schittli\Documents\WindowsPowerShell\Modules\ImportExcel\7.8.2
   ## Das Modul aus dem Verzeichns löschen
   If (Test-Path -LiteralPath $ModuleRootDir) {
      Del-Dir-Check-Permission -DelDir $ModuleRootDir -AbortOnError:$AbortOnError
   } Else {
      # Bereits OK
      # Write-Error ('Verzeichnis existiert nicht: {0}' -f $oGitHubModule.ModuleRootDir)
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

   If ($vLeft -eq $null) { Return [eVersionCompare]::RightIsNewer }
   If ($vRight -eq $null) { Return [eVersionCompare]::LeftIsNewer }

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
            Write-Verbose ('Blacklisted: {0}' -f $RelativeSubDir)
         } Else {
            Write-Verbose ('Blacklisted: {0}' -f $RelativeFileName)
         }
      } Else {
         # Haben wir ein Verzeichnis?
         If ($ThisItem.PSIsContainer) {
            # Ein Verzeichnis? > Erzeugen
            $ZielDir = Join-Path $DstDir $RelativeSubDir
            Write-Verbose ('Erzeuge: {0}' -f $ZielDir)
            New-Dir-Check-Permission -NewDir $ZielDir
         } Else {
            # Eine Datei? > Kopieren
            $RelativeZielFile = Join-Path $RelativeSubDir $ThisItem.Name
            Write-Verbose ('Kopiere: {0}' -f $RelativeZielFile)
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


# Liefert vom Modulverzeichnis (c:\Program Files\WindowsPowerShell\Modules\GitHubRepository\1.2.0\)
# Die Version als Obj
# Debugged: OK
Function Get-ModuleDir-Version($ModuleDir) {
   [Version](Get-Item -LiteralPath $ModuleDir).Name
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
      [Switch]$Force
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
                  Write-Error ('Konnte das installierte Modul nicht löschen: {0}' -f $oGitHubModule.ModuleRootDir)
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
               Write-Host ('  Bereits aktuell')
               If ($Force) {
                  Write-Host ('  > forciere Installation')
                  # Modul löschen
                  Delete-Module -oInstalledModule $oInstalledModule
                  If (Test-Path -LiteralPath $oInstalledModule.ModuleBase) {
                     # Das Modul existiert immer noch
                     Write-Error ('Konnte das installierte Modul nicht löschen: {0}' -f $oInstalledModule.ModuleBase)
                     Return
                  }
                  # Das Modul Installieren
                  Copy-Dir-WithBlackList -SrcDir $oGitHubModule.ModuleRootDir -DstDir $oInstalledModule.ModuleBase `
                     -BlackListDirsRgx $BlackListDirsRgx
               } Else {
                  Write-Host '-Force wurde nicht angegeben > Modul wird nicht aktualisiert' -ForegroundColor Red
               }
            }

            ([eVersionCompare]::LeftIsNewer) {
               Write-Host ('  Veraltet')
               Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               If ($Force) {
                  # Modul aktualisieren
                  Write-Host ('  > Upgrade Module')
                  Delete-Module -oInstalledModule $oInstalledModule
                  If (Test-Path -LiteralPath $oInstalledModule.ModuleBase) {
                     # Das Modul existiert immer noch
                     Write-Error ('Konnte das installierte Modul nicht löschen: {0}' -f $oInstalledModule.ModuleBase)
                     Return
                  }

                  # Das Modul in den Scope des bereits installierten Moduls installieren
                  $ZielDir = Join-Path (Get-ModuleScope-Dir $oInstalledModule.eModuleScope) $oGitHubModule.ModuleInstallSubDir
                  Copy-Dir-WithBlackList -SrcDir $oGitHubModule.ModuleRootDir -DstDir $ZielDir `
                                         -BlackListDirsRgx $BlackListDirsRgx
               } Else {
                  Write-Host '-Force wurde nicht angegeben > Modul wird nicht aktualisiert' -ForegroundColor Red
               }
            }

            ([eVersionCompare]::RightIsNewer) {
               Write-Host '  Lokale Version ist neuer!'
               Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
            }
         }

      }
   }

   Return

   ## Ist bereits ein Modul installiert?
   $HasModuleInstalled = $oInstalledModule -ne $null
   $DeleteInstalledModule = $False
   $InstallGitHubModule = $True
   If ($HasModuleInstalled) {

      # Ist das bereits installierte Modul im richtigen Scope?
      $IsInRIghtScope = $oInstalledModule.eModuleScope -eq $eInstallScope


      Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $ThisInstalledModule.Version) ) {
         ([eVersionCompare]::Equal) {
            Write-Host ('  Bereits aktuell')
            If ($Force) { $DeleteInstalledModule = $True }
         }

         ([eVersionCompare]::LeftIsNewer) {
            Write-Host ('  Veraltet')
            Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
            If ($UpgradeInstalledModule) {
               $InstallModule = $True
            } Else {
               Write-Host '-UpgradeInstalledModule wurde nicht angegeben' -ForegroundColor Red
               Write-Host 'Modul wird nicht aktualisiert' -ForegroundColor Red
            }
         }

         ([eVersionCompare]::RightIsNewer) {
            Write-Host '  Lokale Version ist neuer!'
            Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
            Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
         }
      }


      # Ist das GitHub Modul neuer?
      If ([Version]$oGitHubModule.PSDData.ModuleVersion -gt $oInstalledModule.Version) {
         $DeleteInstalledModule = $True
      } Else {
         # Das Installierte Modul ist bereits aktuell oder sogar neuer!
         If ($Force) {
            $DeleteInstalledModule = $True
         } Else {
            $InstallGitHubModule = $False
         }
      }

      If ($DeleteInstalledModule) {
         # Modul löschen
         Delete-Module -ModuleBaseDir $oInstalledModule.ModuleBaseDir
      }
   }

   ## Das Modul installieren
   If (($DeleteInstalledModule) -and (Test-Path -LiteralPath $oInstalledModule.ModuleBaseDir)) {
      # Das Modul existiert immer noch
      Write-Error ('Konnte das installierte Modul nicht löschen: {0}' -f $oInstalledModule.ModuleBaseDir)
   } Else {
      # Löschen war OK
      If ($InstallGitHubModule) {
         # Das neue Modul Installieren
         $ZielDir = Join-Path $InstallScopeDir $oGitHubModule.ModuleInstallSubDir

         Copy-Dir-WithBlackList -SrcDir $oGitHubModule.ModuleRootDir -DstDir $ZielDir `
            -BlackListDirsRgx $BlackListDirsRgx

      }
      # Das Modul laden
      Import-Module $oGitHubModule.ModuleName
   }
}


# Testet, ob ein Modul aktualisiert werden soll
# und aktualisiert es allenfalls
Function Test-Module-Update() {
   [CmdletBinding()]
   Param(
      [PSModuleInfo]$oInstalledModule,
      [Parameter(Mandatory)][PSCustomObject]$oGitHubModule,
      # Wenn das Modul noch nicht schon installiert ist, wird dieser Scope benützt
      [eModuleScope]$ProposedDefaultScopeDir,
      # Auch wenn das Modul schon in einem anderen Scope installiert ist, wird es trotzdem in diesem Scope installiert
      [eModuleScope]$EnforceScopeDir,
      # Aktualisiert das Modul, wenn es bereits installiert ist
      [Switch]$UpgradeInstalledModule,
      # Das oberste Verzeichnis:
      # '^(\\|\.\\)*\.git'
      [String[]]$BlackListDirsRgx,
      # Erzwingt die Installation immer
      [Switch]$Force
   )


   If ($oInstalledModule -eq $null) {
      # Das Modul noch nicht installiert
      If ($EnforceScopeDir) {
         $ZielScopeDir = Join-Path $EnforceScopeDir $oGitHubModule.ModuleInstallSubDir
      } Else {
         $ZielScopeDir = Join-Path $ProposedDefaultScopeDir $oGitHubModule.ModuleInstallSubDir
      }

      # Das Modul installieren
      Upgrade-Module -InstallScopeDir $ZielScopeDir -oGitHubModule $oGitHubModule `
         -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $oInstalledModule `
         -Force $Force

   } Else {
      # Das Modul ist bereits installiert
      $InstalledModuleScopeDir = Get-Module-ScopeDir -oModule $oInstalledModule

      $InstallModule = $False
      $ZielScopeDir = $Null
      Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $oInstalledModule.Version) ) {
         ([eVersionCompare]::Equal) {
            Write-Host ('  Bereits aktuell')
            If ($Force) {
               $InstallModule = $True
               If ($EnforceScopeDir) {
                  $ZielScopeDir = Join-Path $EnforceScopeDir $oGitHubModule.ModuleInstallSubDir
               } Else {
                  $ZielScopeDir = Join-Path $ProposedDefaultScopeDir $oGitHubModule.ModuleInstallSubDir
               }
            }
         }
         ([eVersionCompare]::LeftIsNewer) {
            Write-Host ('  Veraltet')
            Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
            If ($UpgradeInstalledModule) {
               $InstallModule = $True
               $ZielScopeDir = Join-Path $InstalledModuleScopeDir
            } Else {
               Write-Host '-UpgradeInstalledModule wurde nicht angegeben' -ForegroundColor Red
               Write-Host 'Modul wird nicht aktualisiert' -ForegroundColor Red
            }
         }
         ([eVersionCompare]::RightIsNewer) {
            Write-Host '  Lokale Version ist neuer!'
            Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
            Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
         }
      }



      ## Bestehende Module aktualisieren?
      If ($UpgradeInstalledModule) {
         $ZielScopeDir = $InstalledModuleScopeDir

         # Das Modul aktualisieren
         Upgrade-Module -InstallScopeDir $ZielScopeDir -oGitHubModule $oGitHubModule `
            -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $oInstalledModule `
            -Force:$True
      }

      ## Modul zwingend in einen Scope installieren?
      If ($EnforceScopeDir) {
         $ZielScopeDir = Join-Path $EnforceScopeDir $oGitHubModule.ModuleInstallSubDir
         # Das Modul aktualisieren
         Upgrade-Module -InstallScopeDir $ZielScopeDir -oGitHubModule $oGitHubModule `
            -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $oInstalledModule `
            -Force $Force
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
         Write-Error "Müsste ein [eModuleScope] sein: $($_)"
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
      [Switch]$Force
   )

   # Das Modul ist in einem Scope installiert
   Write-Host (' {0}' -f $oInstalledModule.ModuleBase) -NoNewline

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
         Write-Host ('  Bereits aktuell')
         # Wenn installierte Module zwingend installiert werden sollen
         # 221114 200528
         # If ($UpgradeInstalledModule -or ($IsInRightScope -and $Force)) {
         #    If ($Force) { Write-Host ('  > Forciere Neuinstallation') }
         #    Else { Write-Host ('  > Aktualisiere Modul') }
         #    $UpgradeExistingModule = $True
         # }
         If ($IsInRightScope) {
            If ($Force) {
               Write-Host ('  > Forciere Neuinstallation')
               $UpgradeExistingModule = $True
            }
         } Else {
            # Wenn das Modul nicht im richtigen Scope ist,
            # die schon richtige Version nur bei -Force aktualisieren
            If ($UpgradeInstalledModule -and $Force) {
               Write-Host ('  > Forciere Neuinstallation')
               $UpgradeExistingModule = $True
            }
         }
      }

      ([eVersionCompare]::LeftIsNewer) {
         Write-Host ('  Veraltet')
         Write-Host ('   Version installiert: {0} - Version GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
         If ($UpgradeInstalledModule -or ($IsInRightScope -and $Force)) {
            If ($Force) { Write-Host ('  > Forciere Neuinstallation') }
            Else { Write-Host ('  > Aktualisiere Modul') }
            $UpgradeExistingModule = $True
         }
         Else {
            Write-Host '-UpgradeInstalledModule wurde nicht angegeben' -ForegroundColor Red
            Write-Host 'Modul wird nicht aktualisiert' -ForegroundColor Red
         }
      }

      ([eVersionCompare]::RightIsNewer) {
         Write-Host '  Lokale Version ist neuer!'
         Write-Host ('   Version installiert: {0} - Version GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
         Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
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
      [Switch]$Force
   )


   Write-Host 'Installiere GitHub Modul'
   Write-Host (' Modulname: {0}' -f $oGitHubModule.ModuleName)
   Write-Host (' Version  : {0}' -f $oGitHubModule.PSDData.ModuleVersion)
   Write-Host (' Quell-Dir: {0}' -f $oGitHubModule.ModuleRootDir)

   ## Prepare
   $eDefaultScope | Assert-eModuleScope
   $eEnforceScope | Assert-eModuleScope

   # Ist das Modul bereits installiert?
   $InstalledModules = @($oModulesList | ? Name -eq $oGitHubModule.ModuleName)

   Switch ($InstalledModules.Count) {
      0 {
         # Debugged: OK
         # Noch nicht installiert - das Modul kopieren
         # Nur, wenn ein Zielscope angegeben wurde
         If ($eEnforceScope) { $eZielScope = $eEnforceScope }
         Else { $eZielScope = $eDefaultScope }
         If ($eZielScope) {
            Upgrade-Module -oGitHubModule $oGitHubModule `
                           -eInstallScope $eZielScope `
                           -BlackListDirsRgx $BlackListDirsRgx `
                           -Force:$Force
         }
      }

      1 {
         # Das Modul ist in einem Scope installiert
         $ThisInstalledModule = $InstalledModules[0]
         Write-Host (' {0}' -f $ThisInstalledModule.ModuleBase) -NoNewline

         Check-Install-GitHubModule -oGitHubModule $oGitHubModule -oInstalledModule $ThisInstalledModule `
                                    -eDefaultScope $eDefaultScope -eEnforceScope $eEnforceScope `
                                    -UpgradeInstalledModule:$UpgradeInstalledModule `
                                    -BlackListDirsRgx $BlackListDirsRgx -Force:$Force
      }

      Default {
         # Das Modul ist in mehreren Scopes installiert
         Write-Host ' Das Modul ist in mehreren Scopes installiert'
         ForEach ($InstalledModule in $InstalledModules) {
            # $ThisModuleScopeDir = ($InstalledModule.ModuleBase -split '\\' | select -SkipLast 2) -join '\'
            Write-Host (' {0}' -f $InstalledModule.ModuleBase) -NoNewline

            Check-Install-GitHubModule -oGitHubModule $oGitHubModule -oInstalledModule $InstalledModule `
               -eDefaultScope $eDefaultScope -eEnforceScope $eEnforceScope `
               -UpgradeInstalledModule:$UpgradeInstalledModule `
               -BlackListDirsRgx $BlackListDirsRgx -Force:$Force
         }
      }
   }

}



# Prüft, ob für das von GitHub heruntergeladenes Modul
# in 1 oder mehreren PS Module Scopes installiert werden kann / muss
Function Check-Install-GitHubModules_001() {
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
      [Switch]$Force
   )


   Write-Host 'Installiere GitHub Modul'
   Write-Host (' Modulname: {0}' -f $oGitHubModule.ModuleName)
   Write-Host (' Version  : {0}' -f $oGitHubModule.PSDData.ModuleVersion)
   Write-Host (' Quell-Dir: {0}' -f $oGitHubModule.ModuleRootDir)

   ## Prepare
   $eDefaultScope | Assert-eModuleScope
   $eEnforceScope | Assert-eModuleScope

   # Ist das Modul bereits installiert?
   $InstalledModules = @($oModulesList | ? Name -eq $oGitHubModule.ModuleName)

   Switch ($InstalledModules.Count) {
      0 {
         # Debugged: OK
         # Noch nicht installiert - das Modul kopieren
         # Nur, wenn ein Zielscope angegeben wurde
         If ($eEnforceScope) { $eZielScope = $eEnforceScope }
         Else { $eZielScope = $eDefaultScope }
         If ($eZielScope) {
            Upgrade-Module -oGitHubModule $oGitHubModule `
                           -eInstallScope $eZielScope `
                           -BlackListDirsRgx $BlackListDirsRgx `
                           -Force:$Force
         }
      }

      1 {
         # Das Modul ist in einem Scope installiert
         $ThisInstalledModule = $InstalledModules[0]
         Write-Host (' {0}' -f $ThisInstalledModule.ModuleBase) -NoNewline

         # Das Scope-Dir bestimmen
         $InstalledModuleScopeDir = Get-Module-ScopeDir -oModule $ThisInstalledModule
         $InstalledeModuleScopeType = Get-ModuleScope-Type -ScopeDir $InstalledModuleScopeDir

         # Ist das Modul im gewünschten Scope?
         $IsInRightScope = $True
         If ($eEnforceScope -and ($InstalledeModuleScopeType -ne $eEnforceScope)) {
            $IsInRightScope = $False
         }

         # Ist das installierte Modul veraltet?
         $UpgradeExistingModule = $False
         Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $ThisInstalledModule.Version) ) {
            ([eVersionCompare]::Equal) {
               Write-Host ('  Bereits aktuell')
               # Wenn installierte Module zwingend installiert werden sollen
               If ($UpgradeInstalledModule -or ($IsInRightScope -and $Force)) {
                  If ($Force) { Write-Host ('  > Forciere Neuinstallation') }
                  Else { Write-Host ('  > Aktualisiere Modul') }
                  $UpgradeExistingModule = $True
               }
            }

            ([eVersionCompare]::LeftIsNewer) {
               Write-Host ('  Veraltet')
               Write-Host ('   Version installiert: {0} - Version GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               If ($UpgradeInstalledModule -or ($IsInRightScope -and $Force)) {
                  If ($Force) { Write-Host ('  > Forciere Neuinstallation') }
                  Else { Write-Host ('  > Aktualisiere Modul') }
                  $UpgradeExistingModule = $True
               } Else {
                  Write-Host '-UpgradeInstalledModule wurde nicht angegeben' -ForegroundColor Red
                  Write-Host 'Modul wird nicht aktualisiert' -ForegroundColor Red
               }
            }

            ([eVersionCompare]::RightIsNewer) {
               Write-Host '  Lokale Version ist neuer!'
               Write-Host ('   Version installiert: {0} - Version GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
            }
         }
         # Das installierte Modul aktualisieren
         If ($UpgradeExistingModule) {
            # Das Modul aktualisieren
            Upgrade-Module -oGitHubModule $oGitHubModule -oInstalledModule $ThisInstalledModule `
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

      Default {
         # Das Modul ist in mehreren Scopes installiert
         Write-Host ' Das Modul ist in mehreren Scopes installiert'
         ForEach ($InstalledModule in $InstalledModules) {
            # $ThisModuleScopeDir = ($InstalledModule.ModuleBase -split '\\' | select -SkipLast 2) -join '\'
            Write-Host (' {0}' -f $InstalledModule.ModuleBase) -NoNewline
            $ThisModuleScopeDir = Get-Module-ScopeDir -oModule $InstalledModule

            $UpgradeExistingModule = $False
            Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $InstalledModule.Version) ) {
               ([eVersionCompare]::Equal) {
                  Write-Host '  Bereits aktuell'
                  If ($Force) { $InstallModule = $True }
               }

               ([eVersionCompare]::LeftIsNewer) {
                  Write-Host '  Das Modul ist veraltet'
                  Write-Host ('   Installierte Version: {0} - GitHub Version: {1}' -f [String]$InstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
                  If ($UpgradeInstalledModule -or ($IsInRightScope -and $Force)) {
                     If ($Force) { Write-Host ('  > Forciere Neuinstallation') }
                     Else { Write-Host ('  > Aktualisiere Modul') }
                     $UpgradeExistingModule = $True
                  }
                  Else {
                     Write-Host '-UpgradeInstalledModule wurde nicht angegeben' -ForegroundColor Red
                     Write-Host 'Modul wird nicht aktualisiert' -ForegroundColor Red
                  }
               }

               ([eVersionCompare]::RightIsNewer) {
                  Write-Host '  Lokale Version ist neuer!'
                  Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$InstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
                  Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
               }
            }
            # Das installierte Modul aktualisieren
            If ($UpgradeExistingModule) {
               # Das Modul aktualisieren
               # Upgrade-Module -InstallScopeDir $ZielScopeDir -oGitHubModule $oGitHubModule `
               #    -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $ThisInstalledModule
               Upgrade-Module -oGitHubModule $oGitHubModule -oInstalledModule $ThisInstalledModule `
                  -BlackListDirsRgx $BlackListDirsRgx `
                  -Force:$True
            }
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
   [CmdletBinding(SupportsShouldProcess)]
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



### Prepare
Add-Type -AssemblyName 'System.IO.Compression';
Add-Type -AssemblyName 'System.IO.Compression.FileSystem';

# Erzeuge ein temporäre Verzeichnis
$TempDir = Get-TempDir

### Haben wir eine Repository-URL erhalten?
If ([String]::IsNullOrWhiteSpace($GitHubRepoUrl) -eq $False) {
   ## Wir haben erhalten: $GitHubRepoUrl
   # Versuchen, die DL Zip URL herauszufinden
   $RepoZipUri = Get-GitHubUrl-RepoZipUri $GitHubRepoUrl
   # Download starten
   $RepositoryZipFileName = Download-File-FromUri -DownloadUrl $RepoZipUri `
                                 -DestinationDir $TempDir -DestinationFilename 'GitHubRepo.zip' `
                                 -Force:$Force -BreakScriptOnDownloadError

} ElseIf ([String]::IsNullOrWhiteSpace($GitHubZipUrl) -eq $False) {
   ## Wir haben erhalten: $GitHubZipUrl
   # Download starten
   $RepositoryZipFileName = Download-File-FromUri -DownloadUrl $GitHubZipUrl `
                                 -DestinationDir $TempDir -DestinationFilename 'GitHubRepo.zip' `
                                 -Force:$Force -BreakScriptOnDownloadError

} ElseIf ([String]::IsNullOrWhiteSpace($GitHubOwnerName) -eq $False) {
   ## Wir haben erhalten: $GitHubOwnerName

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
                                    -DestinationDir $TempDir `
                                    -DestinationFilename 'GitHubRepo.zip' `
                                    -Force:$Force -BreakScriptOnDownloadError
}


## Wenn Pester nur den Download testet, dann sind wir fertig
If ($PesterTestGithubDownloadOnly) {
   Return $RepositoryZipFileName
}


## Die Liste der zu installierenden Module in Objekte konvertieren
$oInstallModuleNames = Array-ToObj $InstallModuleNames
# um zu erfassen, ob ein Modul in GitHub gefunden wurde
$oInstallModuleNames | Add-Member -MemberType NoteProperty -Name FoundOnGitHub -Value $False


# !KH
# $PathResoved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath);

## Alle installierten Module suchen
$AllInstalledModules = Get-Module -ListAvailable -Verbose:$False
# Metadaten ergänzen
Add-Module-ScopeData -ModuleList $AllInstalledModules -AllUsersScope $AllUsersModulesDir -CurrentUserScope $CurrentUserModulesDir
# Uns interessieren nur AllUsers und CurrentUser
$UsersModules = $AllInstalledModules | ? { @([eModuleScope]::AllUsers, [eModuleScope]::CurrentUser) -contains $_.eModuleScope }



### Main


Try {

   ## Ist die zip Datei vorhanden?
   If (-not(Test-Path -LiteralPath $RepositoryZipFileName -PathType Leaf)) {
      Write-Host ('Zip-Datei nicht gefunden: {0}' -f $RepositoryZipFileName) -ForegroundColor Red
      Break Script
   }

   ## Zip extrahieren
   Extract-Zip -ZipFile $RepositoryZipFileName -ZielDir $TempDir

   ## im entpackten Zip PS Module suchen
   $FoundGitHubModules = Find-PSD1-InDir -Dir $TempDir


   ## Alle gefundenen PS Module verarbeiten
   ForEach ($FoundGitHubModule in $FoundGitHubModules) {
      Write-Verbose ('Testing: {0}' -f $FoundGitHubModule.ModuleName)
      # 🟩 Installieren?

      ## Finden wir das GitHub Modul in der gewünschten Installationsliste?
      $oModuleToInstall = $oInstallModuleNames | ? Item -eq $FoundGitHubModule.ModuleName
      # Das gewünschte Modul als gefunden markieren
      $oModuleToInstall | % { $_.FoundOnGitHub = $True }

      If ($InstallAllModules -or $oModuleToInstall) {
         Write-Verbose ("Prüfe Modul: ")
         Check-Install-GitHubModules -oGitHubModule $FoundGitHubModule -oModulesList $UsersModules `
            -eDefaultScope $eDefaultScope -eEnforceScope $eEnforceScope `
            -UpgradeInstalledModule:$UpgradeInstalledModule `
            -BlackListDirsRgx $BlackListDirsRgx `
            -Force:$Force

       } Else {
         Write-Verbose ('Skipped')
      }

   }

   ## Wollte der User Module installieren, die das GitHub Repo nicht hat?
   $MissingGithubModules = $oInstallModuleNames | ? FoundOnGitHub -eq $False
   If ($MissingGithubModules) {
      Write-Host 'Module auf GitHub nicht gefunden:' -ForegroundColor Red
      $MissingGithubModules | % { Write-Host " $($_.Item)" }
   }

} Finally {
   # Das Arbeitsverzeichnis löschen
   Remove-Item -LiteralPath $TempDir -Recurse -Force -EA SilentlyContinue
}
