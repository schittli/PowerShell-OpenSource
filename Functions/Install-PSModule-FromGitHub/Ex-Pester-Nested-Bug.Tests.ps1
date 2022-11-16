
# Example Code for a Pester Bug:
# If a BeforeAll Block defines a HashTable with enum as Key
# Then a nested Describe Block can not access the HashTable by using the enum

Describe 'Ex But HashTable with Enum as Key' {

   BeforeAll {

      # Define the Enum
      Enum eModuleScope { Unknown; AllUsers; CurrentUser }

      # Define a Hashtable with Enum as Key
      $Config = @{
         [eModuleScope]::AllUsers    = 'AllUsers Value'
         [eModuleScope]::CurrentUser = 'CurrentUser Value'
      }

      $Config2 = @{
         ([Int][eModuleScope]::AllUsers)    = 'AllUsers Value'
         ([Int][eModuleScope]::CurrentUser) = 'CurrentUser Value'
      }

      Function GetHastTable($eEnum) {
         Write-Host $eEnum.GetType()
         $Config[($eEnum)]
      }


      # Save the Value of Config -> AllUsers into a Variable
      $ConfigAllUsersValue = $Config[([eModuleScope]::AllUsers)]

      # Print $ConfigAllUsersValue
      Write-Host "BeforeAll: `$ConfigAllUsersValue   : '$($ConfigAllUsersValue)'"
      # Print the Value for Config -> AllUsers
      Write-Host "BeforeAll: HashTable direct access: '$($Config[([eModuleScope]::AllUsers)])'"
      Write-Host "BeforeAll: HashTable direct access• '$($Config2[([Int][eModuleScope]::AllUsers)])'"

      Write-Host "BeforeAll: HashTable Function access: '$( GetHastTable ([eModuleScope]::AllUsers) )'"
   }

   Describe 'Describe #1' {
      It 'Test It #1-1' {

         # OK: Access the 'Global' / BeforeAll Variable
         Write-Host "Nested Describe: `$ConfigAllUsersValue   : '$($ConfigAllUsersValue)'"
         # Fails: Access the 'Global' / BeforeAll HashTable
         Write-Host "Nested Describe: HashTable direct access: '$($Config[([eModuleScope]::AllUsers)])'"
         Write-Host "Nested Describe• HashTable direct access: '$($Config2[([Int][eModuleScope]::AllUsers)])'"
         # Fails:
         Write-Host "Nested Describe: HashTable direct access: '$($Config[('AllUsers')])'"

         Write-Host "BeforeAll: HashTable Function access: '$( GetHastTable ([eModuleScope]::AllUsers) )'"

         $True | Should -Be $True
      }
   }
}


