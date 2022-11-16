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
#     📌 Parallele Installation in: CurrentUser Scope
#     🟩 Parallele Installation in: CurrentUser Scope und -UpgradeInstalledModule
#
#  🟩 Modul ist installiert in: CurrentUser Scope
#     🟩 Force Neuinstallation in: CurrentUser Scope
#     🟩 Force Neuinstallation mit: -UpgradeInstalledModule
#     🟩 Parallele Installation in: AllUsers Scope
#     🟩 Parallele Installation in: AllUsers Scope und -UpgradeInstalledModule
#
# 🟩 -EnforceScope
#
#
#

# ✅
# 🟩


# Ex GitHub Zip
# c:\Scripts\PowerShell\Install-Module-GitHub\!Q GitHubRepository\GitHubRepository-master.zip


# !M Install-Module
# https://learn.microsoft.com/de-ch/powershell/module/PowershellGet/Install-Module?view=powershell-5.1

   # [Parameter(Mandatory, ParameterSetName = 'ProposeDefaultScope')]
   # # Wenn das Modul noch nicht installiert ist, dann wird dieser Scope genützt
   # [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   # [Alias('DefaultScope')]
   # [AllowEmptyString()][String]$ProposedDefaultScope,

   # [Parameter(Mandatory, ParameterSetName = 'EnforceScope')]
   # # Das Modul wird zwingend in diesem Scope installiert, auch wenn es schon anderso installiert ist
   # [ValidateSet(IgnoreCase, 'AllUsers', 'CurrentUser')]
   # [AllowEmptyString()][String]$EnforceScope,

   # [Parameter(Mandatory, ParameterSetName = 'UpgradeInstalledModule')]
   # # Wenn das Modul schon installiert ist, wird es in diesem Scope aktualisiert
   # [Switch]$UpgradeInstalledModule,

   # # Installiere alle Module vom heruntergeladenen GitHub Repo
   # [Switch]$InstallAllModules,

   # # Liste der Modulnamen, die installiert werden sollen
   # [String[]]$InstallModuleNames,

   # # Ein bestehendes Modul wird zwingend aktualisiert
   # [Switch]$Force

Describe 'Test-Wrapper' {

   BeforeAll {

      ## Config
      $InstallModuleGitHub_ps1 = 'Install-Module-GitHub.ps1'
      $Script:DummyModuleName = 'Dummy-PS-Module'

      Enum eModuleScope { Unknown; AllUsers; CurrentUser; System; VSCode; ThirdParty }

      $ModuleScopesDir101 = @{}
      $ModuleScopesDir101.Add( [eModuleScope]::AllUsers, '1')
      $Test = 1

      Enum eModuleScope2 { Unknown; AllUsers; CurrentUser; System; VSCode; ThirdParty }
      $ModuleScopesDir2 = @{}
      $ModuleScopesDir2.Add( [eModuleScope2]::AllUsers, '1')
      $Test = 1


      Enum eModulVersion { V100; V200 }
      $Script:ModuleVersions = @{
         [eModulVersion]::V100 = @{
            VersionNr = '1.0.0'
            ModuleSubDir = $null
            ZipFile = $Null
         }
         [eModulVersion]::V200 = @{
            VersionNr = '2.0.0'
            ModuleSubDir = $null
            ZipFile      = $Null
         }
      }


      Function Get-Script-Dir() {
         If ($Script:ScriptDir) {
            $Script:ScriptDir
         } Else {
            If ($MyInvocation.MyCommand.Path) {
               $Script:ScriptDir = [IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)
            } Else {
               $Script:ScriptDir = (Get-Location).Path
            }
            $Script:ScriptDir
         }
      }


      # Zippt ein Verzeichnis
      Function Zip-Dir() {
         Param(
            [Parameter(Mandatory)][String]$Dir,
            [Parameter(Mandatory)][String]$ZielFile
         )
         Remove-Item -LiteralPath $ZielFile -Force -EA SilentlyContinue
         [System.IO.Compression.ZipFile]::CreateFromDirectory($Dir, $ZielFile)
      }

      # Liefert
      # $ScriptDir\Tests\<ModuleName>
      Function Get-DummyPsModule-RootDir() {
         Param(
            [Parameter(Mandatory)][String]$ModuleName
         )
         $ScriptDir = Get-Script-Dir
         Join-Path $ScriptDir "Tests\$($ModuleName)"
      }

      # Erzeugt aus Dummy-PS-Module-Template.psd1
      # Src\Dummy-PS-Module.psd1
      # mit der VersionInfo
      Function Create-psd1-VersionFile () {
         Param(
            [Parameter(Mandatory)][String]$ModuleName,
            # E.g. '1.2.0'
            [Parameter(Mandatory)][String]$VersionInfo
         )
         $Psd1File = 'Dummy-PS-Module.psd1'
         $Psd1TplFile = 'Dummy-PS-Module-Template.psd1'
         $Psd1TplFile = Join-Path $Script:DummyModuleRootDir $Psd1TplFile
         $Psd1File = Join-Path $Script:DummyModuleSrcDir $Psd1File
         # File lesen
         $TplData = Get-Content -LiteralPath $Psd1TplFile
         # Version setzen und File schreiben
         $TplData -replace '<ModuleVersion>', $VersionInfo | Out-File -FilePath $Psd1File -Force
      }


      # Erzeugt aus dem Dummy-PS-Module ein Zip mit einer bestimmten Version
      Function Create-Dummy-PS-ModuleZipFile() {
         Param(
            [Parameter(Mandatory)][String]$ModuleName,
            # E.g. '1.2.0'
            [Parameter(Mandatory)][String]$VersionInfo
         )

         # Erzeugt die psd1 Datei mit der richtigen Versionsinfo
         Create-psd1-VersionFile -ModuleName $ModuleName -VersionInfo $VersionInfo

         $ThisDummyModuleZip = Join-Path $Script:DummyModuleRootDir "$($DummyModuleName)-$($VersionInfo).zip"

         # Zip erzeugen
         Zip-Dir -Dir $Script:DummyModuleSrcDir -ZielFile $ThisDummyModuleZip

         Return $ThisDummyModuleZip
      }


      # Löscht ein installiertes PS Modul
      Function Delete-PSModule-Dir() {
         Param(
            [Parameter(Mandatory, ParameterSetName = 'Name&Version')]
            [String]$ModuleName,
            [Parameter(ParameterSetName = 'Name&Version')]
            # E.g. '1.2.0'
            [AllowNull()][String]$VersionInfo,
            [Parameter(Mandatory, ParameterSetName = 'ModuleSubDir')]
            [String]$ModuleVersionSubDir,
            [Switch]$DeleteAllUsers,
            [Switch]$DeleteCurrentUser
         )

         # Allenfalls das SubDir berechnen
         # <ModuleName>\<VersionInfo>
         If ([String]::IsNullOrWhiteSpace($ModuleVersionSubDir)) {
            $ModuleSubDir = Get-Module-SubDir -ModuleName $ModuleName -VersionInfo $VersionInfo
         } Else {
            $ModuleSubDir = $ModuleVersionSubDir
         }

         If ($DeleteAllUsers) {
            $ModuleDir = Join-Path $Script:ModuleScopesDir[([eModuleScope]::AllUsers)] $ModuleSubDir
            Remove-Item -Recurse -Force -EA SilentlyContinue -LiteralPath $ModuleDir
         }
         If ($DeleteCurrentUser) {
            $ModuleDir = Join-Path $Script:ModuleScopesDir[([eModuleScope]::CurrentUser)] $ModuleSubDir
            Remove-Item -Recurse -Force -EA SilentlyContinue -LiteralPath $ModuleDir
         }
      }


      # Löscht alle Versionen des installierten Moduls ModuleName
      Function Delete-PSModuleDir-AllVersions() {
         Param(
            [Parameter(Mandatory, ParameterSetName = 'Name&Version')]
            [String]$ModuleName,
            [Switch]$DeleteAllUsers,
            [Switch]$DeleteCurrentUser
         )
         Delete-PSModule-Dir -ModuleName $ModuleName -DeleteAllUsers:$DeleteAllUsers -DeleteCurrentUser:$DeleteCurrentUser
      }

      # Wenn VersionInfo definiert ist:
      #  <ModuleName>\<VersionInfo>
      # Sonst:
      #  <ModuleName>
      Function Get-Module-SubDir() {
         Param(
            [Parameter(Mandatory)][String]$ModuleName,
            # E.g. '1.2.0'
            [AllowNull()][String]$VersionInfo
         )
         If ([String]::IsNullOrWhiteSpace($VersionInfo)) {
            Return $ModuleName
         } Else {
            Return (Join-Path $ModuleName $VersionInfo)
         }
      }


      ### Prepare
      $ScriptDir = Get-Script-Dir
      # Das Script, das wir testen
      $InstallModuleGitHub_ps1 = Join-Path $ScriptDir $InstallModuleGitHub_ps1

      ## Der Pfad zum Root des Dummy-Moduls
      # Inhalt:
      #  Src\
      #  Dummy-PS-Module-1.0.0.zip
      #  Dummy-PS-Module-2.0.0.zip
      #  Dummy-PS-Module-Template.psd1
      $Script:DummyModuleRootDir = Get-DummyPsModule-RootDir -ModuleName $Script:DummyModuleName
      # Der Pfad zu Src des Dummy-Moduls
      $Script:DummyModuleSrcDir = Join-Path $DummyModuleRootDir 'Src'

      # Enum eModuleScope2 { Unknown; AllUsers; CurrentUser; System; VSCode; ThirdParty }
      # $ModuleScopesDir2 = @{}
      # $ModuleScopesDir2.Add( [eModuleScope2]::AllUsers, '1')
      # $ModuleScopesDir2
      # $ModuleScopesDir2[ [eModuleScope2]::AllUsers ]
      # $ModuleScopesDir2.Add( [eModuleScope2]::CurrentUser, '2')
      # $ModuleScopesDir2
      # $ModuleScopesDir2[ [eModuleScope2]::AllUsers ]
      # $ModuleScopesDir2[ [eModuleScope2]::CurrentUser ]

      # $ModuleScopesDir3 = @{}
      # $ModuleScopesDir3.Add( [eModuleScope]::AllUsers, '1')

      $ModuleScopesDir150 = @{}
      $ModuleScopesDir150.Add( [eModuleScope]::AllUsers, '1')
      $Test = 1


      ## Die Modul-Scopes
      $ScopeAllUsersDir = & $InstallModuleGitHub_ps1 -GetScopeAllUsers
      $ScopeCurrentUserDir = & $InstallModuleGitHub_ps1 -GetScopeCurrentUser
      $Script:ModuleScopesDir = @{}
      # $Script:ModuleScopesDir = @{
      #    # [eModuleScope]::AllUsers    = @{ ModuleDir = $ScopeAllUsersDir }
      #    # [eModuleScope]::CurrentUser = @{ ModuleDir = $ScopeCurrentUserDir }
      #    [eModuleScope]::AllUsers    = $ScopeAllUsersDir
      #    [eModuleScope]::CurrentUser = $ScopeCurrentUserDir
      # }

      # $Script:ModuleScopesDir.Add( ([eModuleScope]::AllUsers), (& $InstallModuleGitHub_ps1 -GetScopeAllUsers))
      # $Script:ModuleScopesDir.Add( ([eModuleScope]::CurrentUser), (& $InstallModuleGitHub_ps1 -GetScopeCurrentUser))

      # $Script:ModuleScopesDir.Add( [eModuleScope]::AllUsers, '1')
      # $Script:ModuleScopesDir.Add( [eModuleScope]::CurrentUser, $ScopeCurrentUserDir)


      ## Für jede Dummy Modul Version das Zip-File erzeugen
      [Enum]::Getvalues([eModulVersion]) | % {
         $ThisModuleCfg = $Script:ModuleVersions[$_]
         $ThisModuleCfg.ModuleSubDir = Join-Path $Script:DummyModuleName $ThisModuleCfg.VersionNr
         $ThisModuleCfg.ZipFile = Create-Dummy-PS-ModuleZipFile -ModuleName $Script:DummyModuleName -VersionInfo $ThisModuleCfg.VersionNr
      }

   }


   Describe 'Test Config' {
      It 'Assert $Scope…Dir' {
         # Sicherstellen, dass die Pfade definiert sind
         $Script:ModuleScopesDir[([eModuleScope]::AllUsers)] | Should -Not -BeNullOrEmpty
         $Script:ModuleScopesDir[([eModuleScope]::CurrentUser)] | Should -Not -BeNullOrEmpty
      }
   }


   Describe 'Test Install-Module-GitHub.ps1' {

      BeforeEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser
      }

      It 'Modul ist nicht installiert, Setup in AllUsers Scope' {

         $InstallVersion = [eModulVersion]::V100
         $ZielScope = [eModuleScope]::AllUsers

         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         # Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser

         # [Enum]::Getvalues([eModulVersion]) | % {
         #    $ThisModuleCfg = $Script:ModuleVersions[$_]
         #    Delete-PSModule-Dir -ModuleSubDir $ThisModuleCfg.ModuleSubDir -DeleteAllUsers -DeleteCurrentUser
         # }

         $V1ZipFile = $Script:ModuleVersions[($InstallVersion)].ZipFile
         $Res = & $InstallModuleGitHub_ps1 -InstallZip $V1ZipFile `
                                 -ProposedDefaultScope AllUsers `
                                 -InstallAllModules

         # Wurde das Modul installiert?
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
      }

       AfterEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser
       }

   }

}


