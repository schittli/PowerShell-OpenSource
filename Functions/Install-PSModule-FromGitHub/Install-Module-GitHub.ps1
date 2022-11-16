#
#
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
## Testfälle
#
#  ✅ Modul ist nicht installiert
#     ✅ Installation in: AllUsers Scope
#     ✅ Installation in: CurrentUser Scope
#
#  🟩 Modul ist installiert in: AllUsers Scope
#     ✅ Force Neuinstallation in: AllUsers Scope
#     ✅ Force Neuinstallation mit: -UpgradeInstalledModule
#     🟩 Parallele Installation in: CurrentUser Scope
#     🟩 Parallele Installation in: CurrentUser Scope und -UpgradeInstalledModule
#
#  🟩 Modul ist installiert in: CurrentUser Scope
#     🟩 Force Neuinstallation in: CurrentUser Scope
#     🟩 Force Neuinstallation mit: -UpgradeInstalledModule
#     🟩 Parallele Installation in: AllUsers Scope
#     🟩 Parallele Installation in: AllUsers Scope und -UpgradeInstalledModule
#
# -EnforceScope
#
#
#

# ✅
# 🟩


# Ex GitHub Zip
# c:\Scripts\PowerShell\Install-Module-GitHub\!Q GitHubRepository\GitHubRepository-master.zip


# !M Install-Module
# https://learn.microsoft.com/de-ch/powershell/module/PowershellGet/Install-Module?view=powershell-5.1

[CmdletBinding(DefaultParameterSetName = 'ProposeDefaultScope')]
Param(
   [Parameter(Mandatory, ParameterSetName = 'ProposeDefaultScope')]
   # Wenn das Modul noch nicht installiert ist, dann wird dieser Scope genützt
   [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   [Alias('DefaultScope')]
   [AllowEmptyString()][String]$ProposedDefaultScope,

   [Parameter(Mandatory, ParameterSetName = 'EnforceScope')]
   # Das Modul wird zwingend in diesem Scope installiert, auch wenn es schon anderso installiert ist
   [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   [AllowEmptyString()][String]$EnforceScope,

   [Parameter(Mandatory, ParameterSetName = 'UpgradeInstalledModule')]
   # Wenn das Modul schon installiert ist, wird es in diesem Scope aktualisiert
   [Switch]$UpgradeInstalledModule,

   # Installiere alle Module vom heruntergeladenen GitHub Repo
   [Switch]$InstallAllModules,

   # Liste der Modulnamen, die installiert werden sollen
   [String[]]$InstallModuleNames,

   # Ein bestehendes Modul wird zwingend aktualisiert
   [Switch]$Force
)



## Config Enums
Enum eModuleScope { Unknown; AllUsers; CurrentUser; System; VSCode; ThirdParty }

## Params in Enum konvertieren
If ([String]::IsNullOrWhiteSpace($ProposedDefaultScope)) {
   $eDefaultScope = $Null
} Else {
   $TmpDefaultScope = [eModuleScope]"$($ProposedDefaultScope)"
   Remove-Variable DefaultScope; $eDefaultScope = $TmpDefaultScope; Remove-Variable TmpDefaultScope
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

$ZipFile     = 'c:\Scripts\PowerShell\Install-Module-GitHub\!Q GitHubRepository\GitHubRepository-master.zip'
$ZielTestDir = 'c:\Scripts\PowerShell\Install-Module-GitHub\!Q GitHubRepository\ZielTestDir\'


## Install-Module: Scope
# AllUsers, CurrentUser
$AllUsersModulesDir = "$env:ProgramFiles\WindowsPowerShell\Modules"
$CurrentUserModulesDir = "$home\Documents\WindowsPowerShell\Modules"


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

# Substring, kommt mit Fehlern klar
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


# Join-Path, kommt mit Fehlern klar
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
      [Parameter(Mandatory, ParameterSetName = 'UpdateInstalledModule')]
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


      'UpdateInstalledModule' {

         # Ist das bereits installierte Modul veraltet?
         $ReinstallModule = $False
         Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $oInstalledModule.Version) ) {
            ([eVersionCompare]::Equal) {
               Write-Host ('  Bereits aktuell')
               If ($Force) {
                  Write-Host ('  > forciere Installation')
                  $ReinstallModule = $True
               }
            }

            ([eVersionCompare]::LeftIsNewer) {
               Write-Host ('  Veraltet')
               Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               $ReinstallModule = $True
            }

            ([eVersionCompare]::RightIsNewer) {
               Write-Host '  Lokale Version ist neuer!'
               Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$oInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
            }
         }

         If ($ReinstallModule) {
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


# Prüft, ob das GitHub heruntergeladenes Modul installiert / aktualisiert werden muss
Function Check-Install-GitHubModule() {
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

   $eZielScope = $null
   If ($eEnforceScope) { $eZielScope = $eEnforceScope }
   Else { $eZielScope = $eDefaultScope }

   # Ist das Modul bereits installiert?
   $InstalledModules = @($oModulesList | ? Name -eq $oGitHubModule.ModuleName)

   Switch ($InstalledModules.Count) {
      0 {
         # Debugged: OK
         # Noch nicht installiert - das Modul kopieren
         # Nur, wenn ein Zielscope angegeben wurde
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
         $eModuleScopeType = Get-ModuleScope-Type -ScopeDir $InstalledModuleScopeDir

         # Ist das Modul im gewünschten Scope?
         $IsInRightScope = ($null -eq $eZielScope) -or ($eModuleScopeType -eq $eZielScope)

         # Ist das installierte Modul veraltet?
         $UpgradeExistingModule = $False
         Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $ThisInstalledModule.Version) ) {
            ([eVersionCompare]::Equal) {
               Write-Host ('  Bereits aktuell')
               # Wenn installierte Module zwingend installiert werden sollen
               If ($UpgradeInstalledModule -and $Force -or $IsInRightScope -and $Force) {
                  Write-Host ('  > Forciere Neuinstallation')
                  $UpgradeExistingModule = $True
               }
            }

            ([eVersionCompare]::LeftIsNewer) {
               Write-Host ('  Veraltet')
               Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
               If ($IsInRightScope -or $IsInRightScope -eq $False -and $UpgradeInstalledModule) {
                  $UpgradeExistingModule = $True
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
         # Das installierte Modul aktualisieren
         If ($UpgradeExistingModule) {
            # Das Modul aktualisieren
            Upgrade-Module -oGitHubModule $oGitHubModule -oInstalledModule $ThisInstalledModule `
                           -BlackListDirsRgx $BlackListDirsRgx `
                           -Force:$Force
         }

         # Das Modul im richtigen Scope installieren
         If ($IsInRightScope -eq $False) {
            If ($EnforceScopeDir) {
               $ZielScopeDir = Join-Path $EnforceScopeDir $oGitHubModule.ModuleInstallSubDir
            } Else {
               $ZielScopeDir = Join-Path $ProposedDefaultScopeDir $oGitHubModule.ModuleInstallSubDir
            }
            Upgrade-Module -InstallScopeDir $ZielScopeDir -oGitHubModule $oGitHubModule `
                           -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $ThisInstalledModule
         }
      }

      Default {
         # Das Modul ist in mehreren Scopes installiert
         Write-Host ' Das Modul ist in mehreren Scopes installiert'
         ForEach ($InstalledModule in $InstalledModules) {
            # $ThisModuleScopeDir = ($InstalledModule.ModuleBase -split '\\' | select -SkipLast 2) -join '\'
            Write-Host (' {0}' -f $InstalledModule.ModuleBase) -NoNewline
            $ThisModuleScopeDir = Get-Module-ScopeDir -oModule $InstalledModule

            $InstallModule = $False
            Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.ModuleVersion) $InstalledModule.Version) ) {
               ([eVersionCompare]::Equal) {
                  Write-Host '  Bereits aktuell'
                  If ($Force) { $InstallModule = $True }
               }

               ([eVersionCompare]::LeftIsNewer) {
                  Write-Host '  Das Modul ist veraltet'
                  Write-Host ('   Installierte Version: {0} - GitHub Version: {1}' -f [String]$InstalledModule.Version, $oGitHubModule.PSDData.ModuleVersion)
                  If ($UpgradeInstalledModule) {
                     $InstallModule = $True
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
            If ($InstallModule) {
               # Das Modul aktualisieren
               Upgrade-Module -InstallScopeDir $ZielScopeDir -oGitHubModule $oGitHubModule `
                  -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $ThisInstalledModule
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



### Prepare
Add-Type -AssemblyName 'System.IO.Compression';
Add-Type -AssemblyName 'System.IO.Compression.FileSystem';


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

## Zip extrahieren
Extract-Zip -ZipFile $ZipFile -ZielDir $ZielTestDir

## im entpackten Zip PS Module suchen
$FoundGitHubModules = Find-PSD1-InDir -Dir $ZielTestDir


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
      Check-Install-GitHubModule -oGitHubModule $FoundGitHubModule -oModulesList $UsersModules `
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
