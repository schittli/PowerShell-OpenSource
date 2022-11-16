# Tests für Install-Module-GitHub.ps1
#
#
#
# 001, 221114, Tom@jig.ch

# ✅
# 🟩


$Script:Block0Failed = $False

Describe 'Test Install-Module-GitHub.ps1' {

   BeforeAll {
      ## Config
      $InstallModuleGitHub_ps1 = 'Install-Module-GitHub.ps1'
      $Script:DummyModuleName = 'Dummy-PS-Module'

      Enum eModuleScope { Unknown; AllUsers; CurrentUser; System; VSCode; ThirdParty }

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
         $Psd1File = "$($ModuleName).psd1"
         $Psd1TplFile = "$($ModuleName)-Template.psd1"
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
            $ModuleDir = Join-Path $ModuleScopesDirAllUsers $ModuleSubDir
            Remove-Item -Recurse -Force -EA SilentlyContinue -LiteralPath $ModuleDir
         }
         If ($DeleteCurrentUser) {
            $ModuleDir = Join-Path $ModuleScopesDirCurrentUser $ModuleSubDir
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

      ## Die PS Modul-Scopes
      $Script:ModuleScopesDir = @{
         [eModuleScope]::AllUsers    = (& $InstallModuleGitHub_ps1 -GetScopeAllUsers)
         [eModuleScope]::CurrentUser = (& $InstallModuleGitHub_ps1 -GetScopeCurrentUser)
      }

      ## Pester bug:
      # Nested Pester Blocks können die HastTable Werte per Enum nicht auslesen
      $ModuleScopesDirAllUsers = $ModuleScopesDir[([eModuleScope]::AllUsers)]
      $ModuleScopesDirCurrentUser = $ModuleScopesDir[([eModuleScope]::CurrentUser)]


      ## Für jede DummyModul-Version das Zip-File erzeugen
      [Enum]::Getvalues([eModulVersion]) | % {
         $ThisModuleCfg = $Script:ModuleVersions[$_]
         $ThisModuleCfg.ModuleSubDir = Join-Path $Script:DummyModuleName $ThisModuleCfg.VersionNr
         $ThisModuleCfg.ZipFile = Create-Dummy-PS-ModuleZipFile -ModuleName $Script:DummyModuleName -VersionInfo $ThisModuleCfg.VersionNr
      }

   }


   Describe 'Test #0: Config' {
      BeforeAll {
         # SkipRemainingOnFailure
         # Block - Skip all remaining tests in current block (including child blocks and tests) after a failed test.
         # Container - Skip all remainng tests in the container (file or scriptblock) after a failed test.
         # Run - Skip all tests across all containers in a run after a failed test.
         # None - Default, keep original behaviour.
         # $Configuration.Run.SkipRemainingOnFailure = 'Block'
         # $Configuration.SkipRemainingOnFailure = 'Block'
         # $PesterPreference.Run.SkipRemainingOnFailure = 'Block'
         # $PesterPreference = [PesterConfiguration]::Default
         # $PesterPreference.Run.SkipRemainingOnFailure = 'Run'
      }

      It 'Assert $ScriptDir' {
         # Sicherstellen, dass die Pfade definiert sind
         $ScriptDir | Should -Not -BeNullOrEmpty
         $InstallModuleGitHub_ps1 | Should -Not -BeNullOrEmpty
      }

      It 'Assert $Scope…Dir' {
         # Sicherstellen, dass die Pfade definiert sind
         $ModuleScopesDirAllUsers | Should -Not -BeNullOrEmpty
         $ModuleScopesDirCurrentUser | Should -Not -BeNullOrEmpty
      }

   }


   Describe 'Test-Set #10: PS Modul nicht installiert' {

      BeforeEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser
      }


      It '#11 Setup in AllUsers Scope' {

         $InstallVersion = [eModulVersion]::V100
         $ZielScope = [eModuleScope]::AllUsers

         # [Enum]::Getvalues([eModulVersion]) | % {
         #    $ThisModuleCfg = $ModuleVersions[$_]
         #    Delete-PSModule-Dir -ModuleSubDir $ThisModuleCfg.ModuleSubDir -DeleteAllUsers -DeleteCurrentUser
         # }

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
                                 -ProposedDefaultScope $ZielScope `
                                 -InstallAllModules

         # Wurde das Modul installiert?
         ## Pester Bug
         # Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
         If ($ZielScope -eq [eModuleScope]::AllUsers) {
            $ModuleRootDir = $ModuleScopesDirAllUsers
         } Else {
            $ModuleRootDir = $ModuleScopesDirCurrentUser
         }
         Test-Path -LiteralPath (Join-Path $ModuleRootDir $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
      }


      It '#12 Setup in CurrentUser Scope' {

         $InstallVersion = [eModulVersion]::V100
         $ZielScope = [eModuleScope]::CurrentUser

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
                                 -ProposedDefaultScope $ZielScope `
                                 -InstallAllModules

         # Wurde das Modul installiert?
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
      }


      AfterEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser
      }

   }

   Describe 'Test-Set #20: PS Modul in Scope AllUsers installiert' {

      BeforeEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser

         # PS Modul in Scope Allusers installieren
         $Set20InitInstallVersion = [eModulVersion]::V100
         $Set20InitZielScope = [eModuleScope]::AllUsers

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($Set20InitInstallVersion)].ZipFile `
            -ProposedDefaultScope $Set20InitZielScope `
            -InstallAllModules
      }


      It '#21a Same Scope & Version, Force Neuinstallation' {
         $InstallVersion = $Set20InitInstallVersion
         $ZielScope = $Set20InitZielScope

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime
         Start-Sleep -Milliseconds 1500

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
                                 -ProposedDefaultScope $ZielScope `
                                 -InstallAllModules `
                                 -Force

         # Timestamp der aktuellen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Ist das Verzeichnis des neu installierten Moduln neuer?
         $NewInstallTimestamp -gt $OriInstallTimestamp | Should -Be $True
      }


      It '#21b Same Scope & Version, Using -UpgradeInstalledModule' {
         $InstallVersion = $Set20InitInstallVersion

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime
         Start-Sleep -Milliseconds 1500

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
                                 -InstallAllModules `
                                 -UpgradeInstalledModule

         # Timestamp der aktuellen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Mit der gleichen Modul-Version ohne -Force tut -UpgradeInstalledModule nichts
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#21c Same Scope & Version, Using -UpgradeInstalledModule using -Force' {
         $ZielScope = $Set20InitZielScope
         $InstallVersion = $Set20InitInstallVersion

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime
         Start-Sleep -Milliseconds 1500

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
                                 -InstallAllModules `
                                 -UpgradeInstalledModule `
                                 -Force

         # Timestamp der aktuellen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Mit der gleichen Modul-Version ohne -Force tut -UpgradeInstalledModule nichts
         $NewInstallTimestamp -gt $OriInstallTimestamp | Should -Be $True
      }


      It '#22 Same Scope, new Version, Using -UpgradeInstalledModule' {
         $ZielScope = $Set20InitZielScope
         $InstallVersion = [eModulVersion]::V200

         # Name des Versionsverzeichnisses
         $OriInstallVersionDirName = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
                                 -InstallAllModules `
                                 -UpgradeInstalledModule

         # Alte Version deinstalliert?
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Name des Versionsverzeichnisses
         $NewInstallVersionDirName = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         # Die neue Version ist neuer
         [Version]$NewInstallVersionDirName -gt [Version]$OriInstallVersionDirName | Should -Be $True
      }


      It '#23a Other Scope proposed (nicht enforced), same Version' {
         $InstallVersion = $Set20InitInstallVersion
         $ZielScope = [eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope $ZielScope

         # Im proposed Scope ist nichts installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Timestamp der aktuellen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#23b Other Scope proposed (nicht enforced), same Version, using -Force' {
         $InstallVersion = $Set20InitInstallVersion
         $ZielScope = [eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope $ZielScope `
            -Force

         # Im proposed Scope ist nichts installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Timestamp der aktuellen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das insallierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -gt $OriInstallTimestamp | Should -Be $True
      }


      It '#23c Other Scope enforced, same Version' {
         $InstallVersion = $Set20InitInstallVersion
         $ZielScope = [eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -EnforceScope $ZielScope

         # Im proposed Scope ist das Modul auch installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $True

         # Timestamp der ursprünglichen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#24a Other Scope proposed (nicht enforced), new Version, ohne -Force' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope $ZielScope

         # Das Modul wurde nicht Im proposed Scope installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Timestamp der ursprünglichen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#24b Other Scope proposed (nicht enforced), new Version, using -Force' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope $ZielScope `
            -Force

         # Die ursprüngliche Version existiert nicht mehr
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Die neue Version wurde installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
      }


      It '#24c Other Scope proposed (nicht enforced), new Version, using -UpgradeInstalledModule' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope $ZielScope `
            -UpgradeInstalledModule

         # Die ursprüngliche Version existiert nicht mehr
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Die neue Version wurde installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
      }


      It '#24d Other Scope enforced, same Version' {
         $InstallVersion = $Set20InitInstallVersion
         $ZielScope = [eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -EnforceScope $ZielScope

         # Im proposed Scope ist das Modul auch installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Timestamp der ursprünglichen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#24e Other Scope enforced, new Version, using -force' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
                                             -InstallAllModules `
                                             -EnforceScope $ZielScope `
                                             -Force

         # Im proposed Scope ist das Modul nun auch installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Die ursprüngliche Version wurde nicht aktualisiert
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#24f Other Scope enforced, new Version, using -UpgradeInstalledModule' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser

         # Version der aktuellen Modul-Installation
         $OriInstallVersionDirName = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
                                             -InstallAllModules `
                                             -EnforceScope $ZielScope `
                                             -UpgradeInstalledModule

         # Die ursprüngliche Version existiert nicht mehr
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Die ursprüngliche Version wurde aktualisiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Name des aktualisierten Versionsverzeichnisses
         $NewInstallVersionDirName = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         # Im proposed Scope ist das Modul nun auch installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Die neue Version ist neuer
         [Version]$NewInstallVersionDirName -gt [Version]$OriInstallVersionDirName | Should -Be $True
      }

      AfterEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser
      }

   }

   Describe 'Test-Set #30: PS Modul in allen Scopes installiert' {

      BeforeEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser

         # PS Modul in Scope Allusers installieren
         $Set30InitInstallVersion = [eModulVersion]::V100
         $Set30ZielScope1 = [eModuleScope]::CurrentUser
         $Set30ZielScope2 = [eModuleScope]::AllUsers

         ## In den Scopes installieren
         $Set30ZielScope1, $Set30ZielScope2 | % {
            $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($Set30InitInstallVersion)].ZipFile `
               -EnforceScope $_ `
               -InstallAllModules
         }
      }


      It '#31a -ProposedDefaultScope (nicht enforced), new Version, ohne -UpgradeInstalledModule und ohne -force' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser

         # Das Modulist in beiden Scopes installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope $ZielScope

         # Die ursprüngliche Version existiert immer noch
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
      }


      It '#31b -ProposedDefaultScope (nicht enforced), new Version, mit -force, ohne -UpgradeInstalledModule' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser
         $NotZielScope = [eModuleScope]::AllUsers

         # Version der aktuellen Modul-Installation
         # $OriInstallVersionDir1Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name
         # $OriInstallVersionDir2Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         # Das Modulist in beiden Scopes installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope $ZielScope `
            -Force

         ## Beide Versionen wurden aktualisiert,
         # weil der proposed (nicht enforced) Scope für beide bereits installieren Scopes
         # $IsInRightScope = $true gesetzt wird

         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($NotZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Die alte Version des aktualsierten Moduls existiert nicht mehr
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($NotZielScope)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $False
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $False
      }


      It '#31c -EnforceScope, new Version, mit -force, ohne -UpgradeInstalledModule' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser
         $NotZielScope = [eModuleScope]::AllUsers

         # Version der aktuellen Modul-Installation
         # $OriInstallVersionDir1Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name
         # $OriInstallVersionDir2Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         # Das Modulist in beiden Scopes installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -EnforceScope $ZielScope `
            -Force

         # Die Version, die nicht im -EnforceScope ist, wurde nicht aktualisiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($NotZielScope)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         # Die Version im -EnforceScope wurde aktualisiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Die alte Version im -EnforceScope wurde gelöscht
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $False
      }


      It '#31d -EnforceScope, new Version, mit -force und -UpgradeInstalledModule' {
         $InstallVersion = [eModulVersion]::V200
         $ZielScope = [eModuleScope]::CurrentUser
         $NotZielScope = [eModuleScope]::AllUsers

         # Version der aktuellen Modul-Installation
         # $OriInstallVersionDir1Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name
         # $OriInstallVersionDir2Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         # Das Modulist in beiden Scopes installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         $Null = & $InstallModuleGitHub_ps1 -InstallZip $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -EnforceScope $ZielScope `
            -UpgradeInstalledModule `
            -Force

         ## Beide Versionen wurden aktualisiert,
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($NotZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Die alte Version des aktualsierten Moduls existiert nicht mehr
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($NotZielScope)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $False
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $False
      }


      AfterEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser
      }


   }

}


