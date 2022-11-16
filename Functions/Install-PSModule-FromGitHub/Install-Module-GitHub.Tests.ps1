# Tests für Install-Module-GitHub.ps1
#
# Ausführen der Tests
#  ## Variante 1
#  # In VS Code Projekt öffnen: Install-Module-GitHub.code-workspace
#  # Das Register Testing öffnen
#  # Die Tests ausführen lassen
#
#
#  ## Variante 2
#  ## Variante 2
#  # cd ins Verzeichnis, dann:
#  Invoke-Pester .\Install-Module-GitHub.Tests.ps1 -Output Diagnostic
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

      ## Pester Bug: HashTable könnten in nested Pester Blocks nicht voa Enum adressiert werden
      ## Workaround klappt: Cast Key to [Int]
      Enum eModulVersion { V100; V200 }
      $Script:ModuleVersions = @{
         ([Int][eModulVersion]::V100) = @{
            VersionNr = '1.0.0'
            ModuleSubDir = $null
            ZipFile = $Null
         }
         ([Int][eModulVersion]::V200) = @{
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
            $ModuleDir = Join-Path $ModuleScopesDir[([Int][eModuleScope]::AllUsers)] $ModuleSubDir
            Remove-Item -Recurse -Force -EA SilentlyContinue -LiteralPath $ModuleDir
         }
         If ($DeleteCurrentUser) {
            $ModuleDir = Join-Path $ModuleScopesDir[([Int][eModuleScope]::CurrentUser)] $ModuleSubDir
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

      ### Die PS Modul-Scopes
      ## Pester Bug: HashTable könnten in nested Pester Blocks nicht voa Enum adressiert werden
      ## Workaround klappt: Cast Key to [Int]
      $Script:ModuleScopesDir = @{
         ([Int][eModuleScope]::AllUsers)    = (& $InstallModuleGitHub_ps1 -GetScopeAllUsers)
         ([Int][eModuleScope]::CurrentUser) = (& $InstallModuleGitHub_ps1 -GetScopeCurrentUser)
      }


      ## Für jede DummyModul-Version das Zip-File erzeugen
      [Enum]::Getvalues([eModulVersion]) | % {
         $ThisModuleCfg = $Script:ModuleVersions[([Int]$_)]
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
         $ModuleScopesDir[([Int][eModuleScope]::AllUsers)] | Should -Not -BeNullOrEmpty
         $ModuleScopesDir[([Int][eModuleScope]::CurrentUser)] | Should -Not -BeNullOrEmpty
      }

   }


   Describe 'Test-Set #10: PS Modul nicht installiert' {

      BeforeEach {
         # Allenfalls alle Versionen des installierten Dummy Modules löschen
         Delete-PSModuleDir-AllVersions -ModuleName $Script:DummyModuleName -DeleteAllUsers -DeleteCurrentUser
      }


      It '#11 Setup in AllUsers Scope' {

         $InstallVersion = [Int][eModulVersion]::V100
         $ZielScope = [Int][eModuleScope]::AllUsers

         # [Enum]::Getvalues([eModulVersion]) | % {
         #    $ThisModuleCfg = $ModuleVersions[([Int]$_)]
         #    Delete-PSModule-Dir -ModuleSubDir $ThisModuleCfg.ModuleSubDir -DeleteAllUsers -DeleteCurrentUser
         # }

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
                                 -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
                                 -InstallAllModules

         # Wurde das Modul installiert?
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
      }


      It '#12 Setup in CurrentUser Scope' {

         $InstallVersion = [Int][eModulVersion]::V100
         $ZielScope = [Int][eModuleScope]::CurrentUser

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
                                 -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
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
         $Set20InitInstallVersion = [Int][eModulVersion]::V100
         $Set20InitZielScope = [Int][eModuleScope]::AllUsers

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($Set20InitInstallVersion)].ZipFile `
            -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $Set20InitZielScope)) `
            -InstallAllModules
      }


      It '#21a Same Scope & Version, Force Neuinstallation' {
         $InstallVersion = $Set20InitInstallVersion
         $ZielScope = $Set20InitZielScope

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime
         Start-Sleep -Milliseconds 1500

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
                                 -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
                                 -InstallAllModules `
                                 -Force

         # Timestamp der aktuellen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Ist das Verzeichnis des neu installierten Moduln neuer?
         $NewInstallTimestamp -gt $OriInstallTimestamp | Should -Be $True
      }


      It '#21b Same Scope & Version, Using -UpgradeInstalledModule' {
         # Nur ein Upgrade aller bereits installierter Module
         $InstallVersion = $Set20InitInstallVersion

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime
         Start-Sleep -Milliseconds 1500

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
                                 -InstallAllModules `
                                 -UpgradeInstalledModule

         # Timestamp der aktuellen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Mit der gleichen Modul-Version ohne -Force tut -UpgradeInstalledModule nichts
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#21c Same Scope & Version, Using -UpgradeInstalledModule using -Force' {
         $InstallVersion = $Set20InitInstallVersion

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime
         Start-Sleep -Milliseconds 1500

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
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
         $InstallVersion = [Int][eModulVersion]::V200

         # Name des Versionsverzeichnisses
         $OriInstallVersionDirName = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
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
         $ZielScope = [Int][eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope))

         # Im proposed Scope ist nichts installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Timestamp der aktuellen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#23b Other Scope proposed (nicht enforced), same Version, using -Force' {
         $InstallVersion = $Set20InitInstallVersion
         $ZielScope = [Int][eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
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
         $ZielScope = [Int][eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -EnforceScope ([Enum]::ToObject([eModuleScope], $ZielScope))

         # Im proposed Scope ist das Modul auch installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $True

         # Timestamp der ursprünglichen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#24a Other Scope proposed (nicht enforced), new Version, ohne -Force' {
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope))

         # Das Modul wurde nicht Im proposed Scope installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Timestamp der ursprünglichen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#24b Other Scope proposed (nicht enforced), new Version, using -Force' {
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
            -Force

         # Die ursprüngliche Version existiert nicht mehr
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Die neue Version wurde installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
      }


      It '#24c Other Scope proposed (nicht enforced), new Version, using -UpgradeInstalledModule' {
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
            -UpgradeInstalledModule

         # Die ursprüngliche Version existiert nicht mehr
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | Should -Be $False

         # Die neue Version wurde installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True
      }


      It '#24d Other Scope enforced, same Version' {
         $InstallVersion = $Set20InitInstallVersion
         $ZielScope = [Int][eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -EnforceScope ([Enum]::ToObject([eModuleScope], $ZielScope))

         # Im proposed Scope ist das Modul auch installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Timestamp der ursprünglichen Modul-Installation
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#24e Other Scope enforced, new Version, using -force' {
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser

         # Timestamp der aktuellen Modul-Installation
         $OriInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
                                             -InstallAllModules `
                                             -EnforceScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
                                             -Force

         # Im proposed Scope ist das Modul nun auch installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Die ursprüngliche Version wurde nicht aktualisiert
         $NewInstallTimestamp = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty LastWriteTime

         # Das installierte Modul wurde nicht aktualisiert
         $NewInstallTimestamp -eq $OriInstallTimestamp | Should -Be $True
      }


      It '#24f Other Scope enforced, new Version, using -UpgradeInstalledModule' {
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser

         # Version der aktuellen Modul-Installation
         $OriInstallVersionDirName = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set20InitZielScope)] $ModuleVersions[($Set20InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
                                             -InstallAllModules `
                                             -EnforceScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
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
         $Set30InitInstallVersion = [Int][eModulVersion]::V100
         $Set30ZielScope1 = [Int][eModuleScope]::CurrentUser
         $Set30ZielScope2 = [Int][eModuleScope]::AllUsers

         ## In den Scopes installieren
         $Set30ZielScope1, $Set30ZielScope2 | % {
            $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($Set30InitInstallVersion)].ZipFile `
               -EnforceScope ([Enum]::ToObject([eModuleScope], $_)) `
               -InstallAllModules
         }
      }


      It -Tag '#31a' -Name '#31a -ProposedDefaultScope (nicht enforced), new Version, ohne -UpgradeInstalledModule und ohne -force' {
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser

         # Das Modulist in beiden Scopes installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope))

         # Die ursprüngliche Version existiert immer noch
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
      }


      It '#31b -ProposedDefaultScope (nicht enforced), new Version, mit -force, ohne -UpgradeInstalledModule' {
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser
         $NotZielScope = [Int][eModuleScope]::AllUsers

         # Version der aktuellen Modul-Installation
         # $OriInstallVersionDir1Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name
         # $OriInstallVersionDir2Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         # Das Modulist in beiden Scopes installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -ProposedDefaultScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
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
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser
         $NotZielScope = [Int][eModuleScope]::AllUsers

         # Version der aktuellen Modul-Installation
         # $OriInstallVersionDir1Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name
         # $OriInstallVersionDir2Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         # Das Modulist in beiden Scopes installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -EnforceScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
            -Force

         # Die Version, die nicht im -EnforceScope ist, wurde nicht aktualisiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($NotZielScope)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         # Die Version im -EnforceScope wurde aktualisiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($InstallVersion)].ModuleSubDir) | Should -Be $True

         # Die alte Version im -EnforceScope wurde gelöscht
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($ZielScope)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $False
      }


      It '#31d -EnforceScope, new Version, mit -force und -UpgradeInstalledModule' {
         $InstallVersion = [Int][eModulVersion]::V200
         $ZielScope = [Int][eModuleScope]::CurrentUser
         $NotZielScope = [Int][eModuleScope]::AllUsers

         # Version der aktuellen Modul-Installation
         # $OriInstallVersionDir1Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name
         # $OriInstallVersionDir2Name = Get-Item -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | select -ExpandProperty Name

         # Das Modulist in beiden Scopes installiert
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope1)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True
         Test-Path -LiteralPath (Join-Path $ModuleScopesDir[($Set30ZielScope2)] $ModuleVersions[($Set30InitInstallVersion)].ModuleSubDir) | Should -Be $True

         $Null = & $InstallModuleGitHub_ps1 -RepositoryZipFile $ModuleVersions[($InstallVersion)].ZipFile `
            -InstallAllModules `
            -EnforceScope ([Enum]::ToObject([eModuleScope], $ZielScope)) `
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


   Describe 'Test-Set #50: Test GitHub Download' {

      BeforeEach {
         # Vor jedem einzelnen Test...
      }


      ## -GitHubRepoUrl
      It -Name '#51a -GitHubRepoUrl aufs GitHub Hauptprojekt' {

         $TestUrl = 'https://github.com/rtCamp/login-with-google'

         # Download starten
         $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubRepoUrl $TestUrl `
                                             -PesterTestGithubDownloadOnly

         # Zip-File muss existieren
         Test-Path -LiteralPath $DownloadedZipFileName | Should -Be $True

         # File löschen
         Remove-Item -Force -EA SilentlyContinue -LiteralPath $DownloadedZipFileName
      }

      It -Name '#51b -GitHubRepoUrl auf einen GitHub Branch' {

         $TestUrl = 'https://github.com/rtCamp/login-with-google/tree/develop'

         # Download starten
         $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubRepoUrl $TestUrl `
                                             -PesterTestGithubDownloadOnly

         # Zip-File muss existieren
         Test-Path -LiteralPath $DownloadedZipFileName | Should -Be $True

         # File löschen
         Remove-Item -Force -EA SilentlyContinue -LiteralPath $DownloadedZipFileName
      }

      It -Name '#51c -GitHubRepoUrl auf ein GitHub Tag' {

         $TestUrl = 'https://github.com/rtCamp/login-with-google/releases/tag/1.3.1'

         # Download starten
         $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubRepoUrl $TestUrl `
                                             -PesterTestGithubDownloadOnly

         # Zip-File muss existieren
         Test-Path -LiteralPath $DownloadedZipFileName | Should -Be $True

         # File löschen
         Remove-Item -Force -EA SilentlyContinue -LiteralPath $DownloadedZipFileName
      }


      ## -GitHubRepoUrl
      It -Name '#51d -GitHubRepoUrl ungültig' {

         $TestUrl = 'https://github.com/22111601059/login-with-google'

         # Download starten
         Try {
            $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubRepoUrl $TestUrl `
                                                -PesterTestGithubDownloadOnly
         } Catch {
            # $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
            $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
            # Wir erhalten: The remote server returned an error: (404) Not Found.
            $ErrorMessage | Should -Match '(404)'
         }

         # Kein Zip-File name
         $DownloadedZipFileName | Should -Be $Null
      }


      It -Name '#52a -GitHubZipUrl aufs GitHub Hauptprojekt' {

         $TestUrl = 'https://github.com/rtCamp/login-with-google/archive/refs/heads/develop.zip'

         # Download starten
         $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubZipUrl $TestUrl `
                                             -PesterTestGithubDownloadOnly

         # Zip-File muss existieren
         Test-Path -LiteralPath $DownloadedZipFileName | Should -Be $True

         # File löschen
         Remove-Item -Force -EA SilentlyContinue -LiteralPath $DownloadedZipFileName
      }

      It -Name '#52b -GitHubZipUrl ungültig' {

         $TestUrl = 'https://github.com/221116101858/login-with-google/archive/refs/heads/develop.zip'

         # Download starten
         Try {
            $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubZipUrl $TestUrl `
                                                -PesterTestGithubDownloadOnly
         } Catch {
            # $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
            $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
            # Wir erhalten: The remote server returned an error: (404) Not Found.
            $ErrorMessage | Should -Match '(404)'
         }

         # Kein Zip-File name
         $DownloadedZipFileName | Should -Be $Null
      }


      ## -GitHubOwnerName mit RepoName & Branch
      It -Name '#53a -GitHubOwnerName mit RepoName & Branch' {
         $GitHubOwnerName = 'rtCamp'
         $GitHubRepoName = 'login-with-google'
         $GitHubBranchName = 'master'

         # Download starten
         $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubOwnerName $GitHubOwnerName `
            -GitHubRepoName $GitHubRepoName -GitHubBranchName $GitHubBranchName `
            -PesterTestGithubDownloadOnly

         # Zip-File muss existieren
         Test-Path -LiteralPath $DownloadedZipFileName | Should -Be $True

         # File löschen
         Remove-Item -Force -EA SilentlyContinue -LiteralPath $DownloadedZipFileName
      }

      It -Name '#53b -GitHubOwnerName mit ungültigem $GitHubOwnerName' {
         $GitHubOwnerName = '221116102811'
         $GitHubRepoName = 'login-with-google'
         $GitHubBranchName = 'master'

         # Download starten
         Try {
            # Download starten
            $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubOwnerName $GitHubOwnerName `
               -GitHubRepoName $GitHubRepoName -GitHubBranchName $GitHubBranchName `
               -PesterTestGithubDownloadOnly
         }
         Catch {
            # $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
            $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
            # Wir erhalten: The remote server returned an error: (404) Not Found.
            $ErrorMessage | Should -Match '(404)'
         }

         # Kein Zip-File name
         $DownloadedZipFileName | Should -Be $Null
      }

      It -Name '#53c -GitHubOwnerName mit ungültigem $GitHubRepoName' {
         $GitHubOwnerName = 'rtCamp'
         $GitHubRepoName = '221116102811'
         $GitHubBranchName = 'master'

         # Download starten
         Try {
            # Download starten
            $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubOwnerName $GitHubOwnerName `
               -GitHubRepoName $GitHubRepoName -GitHubBranchName $GitHubBranchName `
               -PesterTestGithubDownloadOnly
         }
         Catch {
            # $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
            $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
            # Wir erhalten: The remote server returned an error: (404) Not Found.
            $ErrorMessage | Should -Match '(404)'
         }

         # Kein Zip-File name
         $DownloadedZipFileName | Should -Be $Null
      }

      It -Name '#53d -GitHubOwnerName mit ungültigem $GitHubBranchName' {
         $GitHubOwnerName = 'rtCamp'
         $GitHubRepoName = 'login-with-google'
         $GitHubBranchName = '221116102811'

         # Download starten
         Try {
            # Download starten
            $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubOwnerName $GitHubOwnerName `
               -GitHubRepoName $GitHubRepoName -GitHubBranchName $GitHubBranchName `
               -PesterTestGithubDownloadOnly
         }
         Catch {
            # $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
            $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
            # Wir erhalten: The remote server returned an error: (404) Not Found.
            $ErrorMessage | Should -Match '(404)'
         }

         # Kein Zip-File name
         $DownloadedZipFileName | Should -Be $Null
      }


      ## -GitHubOwnerName mit RepoName & Tag
      It -Name '#54a -GitHubOwnerName mit RepoName & Tag' {
         $GitHubOwnerName = 'rtCamp'
         $GitHubRepoName = 'login-with-google'
         $GitHubTag = '1.3.1'

         # Download starten
         $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubOwnerName $GitHubOwnerName `
            -GitHubRepoName $GitHubRepoName -GitHubTag $GitHubTag `
            -PesterTestGithubDownloadOnly

         # Zip-File muss existieren
         Test-Path -LiteralPath $DownloadedZipFileName | Should -Be $True

         # File löschen
         Remove-Item -Force -EA SilentlyContinue -LiteralPath $DownloadedZipFileName
      }

      It -Name '#54b -GitHubOwnerName mit ungültigem $GitHubTag' {
         $GitHubOwnerName = 'rtCamp'
         $GitHubRepoName = 'login-with-google'
         $GitHubTag = '221116103050'

         # Download starten
         Try {
            # Download starten
            $DownloadedZipFileName = & $InstallModuleGitHub_ps1 -GitHubOwnerName $GitHubOwnerName `
               -GitHubRepoName $GitHubRepoName -GitHubTag $GitHubTag `
               -PesterTestGithubDownloadOnly
         }
         Catch {
            # $MessageId = ('{0:x}' -f $_.Exception.HResult).Trim([char]0)
            $ErrorMessage = ($_.Exception.Message).Trim([char]0) # The network path was not found.
            # Wir erhalten: The remote server returned an error: (404) Not Found.
            $ErrorMessage | Should -Match '(404)'
         }

         # Kein Zip-File name
         $DownloadedZipFileName | Should -Be $Null
      }


      AfterEach {
         # Nach jedem einzelnen Test...
      }

   }

}


