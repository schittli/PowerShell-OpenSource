#
#
#
#
#

# ✅
# 🟩


# !M Install-Module
# https://learn.microsoft.com/de-ch/powershell/module/PowershellGet/Install-Module?view=powershell-5.1

[CmdletBinding(DefaultParameterSetName = 'DefaultScope')]
Param(
   [Parameter(Mandatory, ParameterSetName = 'DefaultScope')]
   # Wenn das Modul noch nicht installiert ist, dann wird dieser Scope genützt
   [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   [String]$DefaultScope,

   [Parameter(Mandatory, ParameterSetName = 'EnforceScope')]
   # Das Modul wird zwingend in diesem Scope installiert, auch wenn es schon anderso installiert ist
   [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   [String]$EnforceScope,

   # Wenn das Modul schon installiert ist, wird es in diesem Scope aktualisiert
   [Switch]$UpgradeInstalledModule,

   # Ein bestehendes Modul wird zwingend aktualisiert
   [Switch]$Force
)



### Config

# Verzeichnisse, die nicht kopiert werden
$BlackListDirsRgx = @('^(\\|\.\\)*\.git', '\.vscode')

[Switch]$InstallAllModules = $True
$InstallModules = @()

$ZipFile = 'c:\Scripts\PowerShell\Install-Module-GitHub\!Q GitHubRepository\GitHubRepository-master.zip'
$ZielTestDir = 'c:\Scripts\PowerShell\Install-Module-GitHub\!Q GitHubRepository\ZielTestDir\'


## Install-Module: Scope
# AllUsers, CurrentUser
$AllUsersModulesDir = "$env:ProgramFiles\WindowsPowerShell\Modules"
$CurrentUserModulesDir = "$home\Documents\WindowsPowerShell\Modules"


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



# Löscht ein PowerShell-Modul, indem das ganze Verzeichnis gelöscht wird
#  ModuleBase
#     C:\Users\schittli\Documents\WindowsPowerShell\Modules\ImportExcel\7.8.2
Function Delete-Module() {
   [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidOverwritingBuiltInCmdlets', '')]
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [Alias('ModuleBaseDir')]
      [String]$ModuleBase
   )

   If ([String]::IsNullOrWhiteSpace($ModuleBase)) { Return }

   ## Das Modul entladen
   # eg ModuleBase
   # C:\Users\schittli\Documents\WindowsPowerShell\Modules\ImportExcel\7.8.2
   $ModulName = (Get-Item -LiteralPath $ModuleBase).Parent.Name
   Write-Verbose "Entlade Modul: $ModulName"
   Remove-Module -Name $ModulName -Force -EA n SilentlyContinue

   ## Das Modul aus dem Verzeichns löschen
   If (Test-Path -LiteralPath $ModuleBase) {
      Remove-Item -LiteralPath $ModuleBase -Recurse -Force
   }
   Else {
      Write-Error ('Verzeichnis existiert nicht: {0}' -f $ModuleBase)
   }
}


# Sucht in einem Verzeichnis alle psd1 Files, um PowerShell Module zu finden
Function Find-PSD1-InDir() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [String]$Dir
   )
   Get-ChildItem -Recurse -LiteralPath $Dir -Filter *.psd1 | % {
      $PSDData = Import-PowerShellDataFile -LiteralPath $_.FullName
      $ModuleInstallSubDir = Join-Path $_.BaseName [String]$PSDData.Version
      [PSCustomObject][Ordered]@{
         ModuleName     = $_.BaseName
         Psd1FileName   = $_.FullName
         oPsd1File      = $_
         PSDData        = $PSDData
         ModuleDir      = $_.DirectoryName
         # Das Unterverzeichnis, in dem das Modul installiert wird
         ModuleInstallSubDir = $ModuleInstallSubDir
      }
   }
}


# Vergleicht zwei [Version] Objs
Enum eVersionCompare { Equal; LeftIsNewer; RightIsNewer}
Function Compare-Version() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [Version]$vLeft,
      [Parameter(Mandatory)]
      [Version]$vRight
   )

   If ($vLeft -eq $vRight) { Return [eVersionCompare]::Equal }

   If ($vLeft -gt $vRight) {
      Return [eVersionCompare]::LeftIsNewer
   } Else {
      Return [eVersionCompare]::RightIsNewer
   }
}

# Substring, kommt mit Fehlern klar
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
   If ($Force) { $Null = Remove-Item -LiteralPath $DstDir -Recurse -Force -EA SilentlyContinue }

   Get-ChildItem -LiteralPath $SrcDir -Recurse  -Force | % {
      $ThisItem = $_
      If ($ThisItem.PSIsContainer) {
         $RelativeSubDir = $ThisItem.FullName.SubString( $SrcDir.Length )
      } Else {
         # $RelativeSubItem = $ThisItem.DirectoryName.SubString( $SrcDir.Length )
         $RelativeSubDir = SubString $ThisItem.DirectoryName $SrcDir.Length
      }

      $IsBlacklisted = @($BlackListDirsRgx | ? { $RelativeSubDir -match $_ })

      If ($IsBlacklisted.Count -gt 0) {
         Write-Verbose ('Blacklisted: {0}' -f $RelativeSubDir)
      } Else {
         If ($ThisItem.PSIsContainer) {
            # Ein Verzeichnis? > Erzeugen
            $ZielDir = Join-Path $DstDir $RelativeSubDir
            Write-Verbose ('Erzeuge: {0}' -f $ZielDir)
            $Null = New-Item -Path $ZielDir -ItemType Directory -EA SilentlyContinue
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
# eg
# ModuleBase : C:\Users\schittli\Documents\WindowsPowerShell\Modules\ImportExcel\7.8.2
# > C:\Users\schittli\Documents\WindowsPowerShell\Modules
Function Get-Module-ScopeDir() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)][PSModuleInfo]$oModule
   )
   $ModulesDir = (Get-Item -LiteralPath $oModule.ModuleBase).Parent.Parent.FullName
   $ModulesDir
}


# Löscht allenfalls ein vorhandenes Modul
# und installiert die neue Version
Function Upgrade-Module() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)][String]$InstallScopeDir,
      [Parameter(Mandatory)][PSCustomObject]$oGitHubModule,
      [PSModuleInfo]$oInstalledModule,
      # Das oberste Verzeichnis:
      # '^(\\|\.\\)*\.git'
      [String[]]$BlackListDirsRgx,
      [Switch]$Force
   )

   ## Ist bereits ein Modul installiert?
   $HasModuleInstalled = $oInstalledModule -ne $null
   $DeleteInstalledModule = $True
   $InstallGitHubModule = $True
   If ($HasModuleInstalled) {
      # Ist das GitHub Modul neuer?
      If ([Version]$oGitHubModule.PSDData.Version -gt $oInstalledModule.Version) {
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

         Copy-Dir-WithBlackList -SrcDir $oGitHubModule.ModuleDir -DstDir $ZielDir `
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
      [String]$DefaultScopeDir,
      # Auch wenn das Modul schon in einem anderen Scope installiert ist, wird es trotzdem in diesem Scope installiert
      [String]$EnforceScopeDir,
      # Aktualisiert das Modul, wenn es bereits installiert ist
      [String]$UpgradeInstalledModule,
      # Das oberste Verzeichnis:
      # '^(\\|\.\\)*\.git'
      [String[]]$BlackListDirsRgx,
      # Erzwingt die Installation immer
      [Switch]$Force
   )


   If ($oInstalledModule -eq $null) {
      # Das Modul noch nicht installiert
      If ($EnforceScopeDir) {
         $ZielDir = Join-Path $EnforceScopeDir $oGitHubModule.ModuleInstallSubDir
      } Else {
         $ZielDir = Join-Path $DefaultScopeDir $oGitHubModule.ModuleInstallSubDir
      }

      # Das Modul installieren
      Upgrade-Module -InstallScopeDir $ZielDir -oGitHubModule $oGitHubModule `
         -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $oInstalledModule `
         -Force $Force

   } Else {
      # Das Modul ist bereits installiert
      $InstalledModuleScopeDir = Get-Module-ScopeDir $oInstalledModule

      ## Bestehende Module aktualisieren?
      If ($UpgradeInstalledModule) {
         $ZielDir = $InstalledModuleScopeDir

         # Das Modul aktualisieren
         Upgrade-Module -InstallScopeDir $ZielDir -oGitHubModule $oGitHubModule `
            -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $oInstalledModule `
            -Force:$True
      }

      ## Modul zwingend in einen Scope installieren?
      If ($EnforceScopeDir) {
         $ZielDir = Join-Path $EnforceScopeDir $oGitHubModule.ModuleInstallSubDir
         # Das Modul aktualisieren
         Upgrade-Module -InstallScopeDir $ZielDir -oGitHubModule $oGitHubModule `
            -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $oInstalledModule `
            -Force $Force
      }
   }
}



# Installiert ein von GitHub heruntergeladenes Modul, wenn es noch nicht installiert wurde
Function Install-GitHubModule() {
   [CmdletBinding()]
   Param(
      [Parameter(Mandatory)]
      [PSCustomObject]$oGitHubModule,
      [Parameter(Mandatory)]
      [Array]$AllInstalledModules,
      # Wenn das Modul noch nicht schon installiert ist, wird dieser Scope benützt
      [String]$DefaultScopeDir,
      # Auch wenn das Modul schon in einem anderen Scope installiert ist, wird es trotzdem in diesem Scope installiert
      [String]$EnforceScopeDir,
      # Aktualisiert das Modul, wenn es bereits installiert ist
      [String]$UpgradeInstalledModule,
      # Das oberste Verzeichnis:
      # '^(\\|\.\\)*\.git'
      [String[]]$BlackListDirsRgx,
      # Erzwingt die Installation immer
      [Switch]$Force
   )


   Write-Host 'Installiere GitHub Modul'
   Write-Host (' Modulname : {0}' -f $oGitHubModule.ModuleName)
   Write-Host (' InstallDir: {0}' -f $oGitHubModule.ModuleBase)
   Write-Host (' Version   : {0}' -f $oGitHubModule.PSDData.Version)

   # Ist das Modul bereits installiert?
   $InstalledModules = @($AllInstalledModules | ? Name -eq $oGitHubModule.ModuleName)

   Switch ($InstalledModules.Count) {
      0 {
         # Noch nicht installiert - kopieren
         If ($EnforceScopeDir) {
            $ZielDir = Join-Path $EnforceScopeDir $oGitHubModule.ModuleInstallSubDir
         } Else {
            $ZielDir = Join-Path $DefaultScopeDir $oGitHubModule.ModuleInstallSubDir
         }
         # Das Modul installieren
         Upgrade-Module -InstallScopeDir $ZielDir -oGitHubModule $oGitHubModule -BlackListDirsRgx $BlackListDirsRgx
      }

      1 {
         # Das Modul ist in einem Scope installiert
         $ThisInstalledModule = $InstalledModules[0]
         Write-Host (' {0}' -f $ThisInstalledModule.ModuleBase) -NoNewline

         # Installiert - veraltet?
         $InstallModule = $False
         Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.Version) $ThisInstalledModule.Version) ) {
            ([eVersionCompare]::Equal) {
               Write-Host ('  Bereits aktuell')
               If ($Force) { $InstallModule = $True }
            }
            ([eVersionCompare]::LeftIsNewer) {
               Write-Host ('  Veraltet')
               Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.Version)
               If ($UpgradeInstalledModule) {
                  $InstallModule = $True
               } Else {
                  Write-Host '-UpgradeInstalledModule wurde nicht angegeben' -ForegroundColor Red
                  Write-Host 'Modul wird nicht aktualisiert' -ForegroundColor Red
               }
            }
            ([eVersionCompare]::RightIsNewer) {
               Write-Host '  Lokale Version ist neuer!'
               Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$ThisInstalledModule.Version, $oGitHubModule.PSDData.Version)
               Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
            }
         }
         If ($InstallModule) {
            # Das Modul aktualisieren
            Upgrade-Module -InstallScopeDir $ZielDir -oGitHubModule $oGitHubModule `
                           -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $ThisInstalledModule
         }
      }

      Default {
         # Das Modul ist in mehreren Scopes installiert
         Write-Host ' Das Modul ist in mehreren Scopes installiert'
         ForEach ($InstalledModule in $InstalledModules) {
            # $ThisModuleScopeDir = ($InstalledModule.ModuleBase -split '\\' | select -SkipLast 2) -join '\'
            Write-Host (' {0}' -f $InstalledModule.ModuleBase) -NoNewline
            $ThisModuleScopeDir = Get-Module-ScopeDir $InstalledModule

            $InstallModule = $False
            Switch ( (Compare-Version ([Version]$oGitHubModule.PSDData.Version) $InstalledModule.Version) ) {
               ([eVersionCompare]::Equal) {
                  Write-Host '  Bereits aktuell'
                  If ($Force) { $InstallModule = $True }
               }

               ([eVersionCompare]::LeftIsNewer) {
                  Write-Host '  Das Modul ist veraltet'
                  Write-Host ('   Installierte Version: {0} - GitHub Version: {1}' -f [String]$InstalledModule.Version, $oGitHubModule.PSDData.Version)
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
                  Write-Host ('   Installiert: {0} - GitHub: {1}' -f [String]$InstalledModule.Version, $oGitHubModule.PSDData.Version)
                  Write-Host 'Lokale Kopie wird nicht aktualisiert!' -ForegroundColor Red
               }
            }
            If ($InstallModule) {
               # Das Modul aktualisieren
               Upgrade-Module -InstallScopeDir $ZielDir -oGitHubModule $oGitHubModule `
                  -BlackListDirsRgx $BlackListDirsRgx -oInstalledModule $ThisInstalledModule
            }
         }
      }
   }

}



### Prepare
Add-Type -AssemblyName 'System.IO.Compression';
Add-Type -AssemblyName 'System.IO.Compression.FileSystem';


Switch ($DefaultScope) {
   'AllUsers'    { $DefaultScopeDir = $AllUsersModulesDir }
   'CurrentUser' { $DefaultScopeDir = $CurrentUserModulesDir }
   Default       { $DefaultScopeDir = $Null }
}

Switch ($EnforceScope) {
   'AllUsers'    { $EnforceScopeDir = $AllUsersModulesDir }
   'CurrentUser' { $EnforceScopeDir = $CurrentUserModulesDir }
   Default       { $EnforceScopeDir = $Null }
}



[Parameter(Mandatory, ParameterSetName = 'EnforceScope')]
# Das Modul wird zwingend in diesem Scope installiert, auch wenn es schon anderso installiert ist
[ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
[String]$EnforceScope,


# !KH
# $PathResoved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationPath);

# Alle installierten Module suchen
$AllInstalledModules = Get-Module -ListAvailable



### Main

Extract-Zip -ZipFile $ZipFile -ZielDir $ZielTestDir

$FoundGitHubModules = Find-PSD1-InDir -Dir $ZielTestDir

ForEach ($FoundGitHubModule in $FoundGitHubModules) {
   Write-Verbose ('Testing: {0}' -f $FoundGitHubModule.ModuleName)
   # 🟩 Installieren?
   If ($InstallAllModules -or ($InstallModules -contains $FoundGitHubModule.ModuleName)) {
      Write-Verbose ('Testing Version')
      Install-GitHubModule -oGitHubModule $FoundGitHubModule -AllInstalledModules $AllInstalledModules `
         -DefaultScopeDir $DefaultScopeDir -EnforceScopeDir $EnforceScopeDir `
         -UpgradeInstalledModule $UpgradeInstalledModule `
         -BlackListDirsRgx $BlackListDirsRgx `
         -Force $Force

    } Else {
      Write-Verbose ('Skipped')
   }

}

