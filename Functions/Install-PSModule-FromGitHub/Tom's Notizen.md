

# Konzept

. zip File herunterladne
. in $temp entpacken
. alle .psd1 Files suchen
   . für jedes psd1 File
      Modulname = psd1 FileName
      Soll das Modul installiert werden?
         Ja: Ist das Modul bereits installiert?
            System-weit?
            User-Spezifisch?
            Ja: Welche Version?
               Entscheiden, ob Installation

                  Installation
                     Verzeichnisinhalt kopieren
                        Blacklist von Files & Ordnern

   CleanUp



# Grundlagen

- Modulename
   - Das Verzeichnis muss wie das Mudul heissen
   - Die PSD1-Datei muss wie das Mudul heissen

# Verzeichnisstruktur
   Modules

      # !Ex https://github.com/RamblingCookieMonster/PSStackExchange/tree/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange
      \MyNewModule
         \en-us
            about_MyNewModule.help.txt

         \lib
            Some.Library.dll

         \bin
            SomeDependency.exe

         \Private
         \Public

         # Sint normalerweise parallel zum Modul-Verzeichnis selber und nicht im Module drin
         # !Ex http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
         \Tests
            \Private
            \Public

         Readme.md
         License.md

         # Module Manifest
         # !Ex https://github.com/RamblingCookieMonster/PSStackExchange/blob/db1277453374cb16684b35cf93a8f5c97288c41f/PSStackExchange/PSStackExchange.psd1
         MyNewModule.psd1

         # Root Module
         MyNewModule.psm1

         #
         PSStackExchange.Format.ps1xml

         # Siehe: https://xainey.github.io/2017/powershell-module-pipeline/
         PSHitchhiker.build.ps1
         PSHitchhiker.settings.ps1



   MyNewModule.psm1
      $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
      $Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

      foreach($import in @($Public + $Private))
      {
         try
         {
            . $import.fullname
         }
         catch
         {
            Write-Error -Message "Failed to import function $($import.fullname): $_"
         }
      }

      Export-ModuleMember -Function $Public.Basename


- Pfade für die Installation von Modulen
   $env:PSModulePath -split ';'

      ## Default Verzeichnisse
      # System-Module / von PS selber
      C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules

      # Systemweit installierte Module
      C:\Program Files\WindowsPowerShell\Modules

      # User-Spezifische Module
      C:\Users\schittli\Documents\WindowsPowerShell\Modules

      ## Zugefügte Modulverzeichnisse
      D:\Portable\cmder\vendor\psmodules\
      C:\Program Files\Intel\Wired Networking\


   ## Modulpfad anpassen
   # Für User-Module
   $CurrentValue = [Environment]::GetEnvironmentVariable('PSModulePath', 'User')
   [Environment]::SetEnvironmentVariable('PSModulePath', $CurrentValue + ';C:\ImproveScripting\Modules', 'User')

   # Für System-Module
   $CurrentValue = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
   [Environment]::SetEnvironmentVariable('PSModulePath', $CurrentValue + ';C:\ImproveScripting\Modules', 'Machine')
