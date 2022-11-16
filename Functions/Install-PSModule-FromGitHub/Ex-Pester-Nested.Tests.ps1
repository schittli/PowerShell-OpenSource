

Describe 'Test Install-Module-GitHub.ps1' {

   BeforeAll {
      $ScopeDescribeBeforeAll = 1

      Enum eModuleScope { Unknown; AllUsers; CurrentUser }

      $Config = @{
         [eModuleScope]::AllUsers    = 'Test AllUsers'
         [eModuleScope]::CurrentUser = 'Test CurrentUser'
      }

      $ConfigItem1 = $Config[([eModuleScope]::AllUsers)]

      Write-Host "Describe - BeforeAll: `$ScopeDescribeBeforeAll: $ScopeDescribeBeforeAll"

      Write-Host "Describe - BeforeAll: `$ConfigItem1: $ConfigItem1"
      Write-Host "Describe - BeforeAll: `$ConfigItem1: $($Config[([eModuleScope]::AllUsers)])"
   }

   Describe 'Describe #1' {
      # Write-Host "Describe - Describe #1: `$ScopeDescribeBeforeAll: $ScopeDescribeBeforeAll"

      It 'Test It #1-1' {
         Write-Host "Describe - Describe #1 - It #1: `$ScopeDescribeBeforeAll: $ScopeDescribeBeforeAll"

         Write-Host "Describe - Describe #1 - It #1: `$ConfigItem1: $ConfigItem1"
         Write-Host "Describe - Describe #1 - It #1: `$ConfigItem1: $($Config[([eModuleScope]::AllUsers)])"

         $True | Should -Be $True
      }
   }

   Describe 'Describe #2' {
      # Write-Host "Describe - Describe #2: `$ScopeDescribeBeforeAll: $ScopeDescribeBeforeAll"

      BeforeEach {
         $ScopeDescribeDescribe2BeforeEach = 1
         Write-Host "Describe - Describe #2 - BeforeEach: `$ScopeDescribeDescribe2BeforeEach: $ScopeDescribeDescribe2BeforeEach"
      }

      It 'Test It #2-1' {
         Write-Host "Describe - Describe #2 - It #1: `$ScopeDescribeBeforeAll: $ScopeDescribeBeforeAll"
         Write-Host "Describe - Describe #2 - It #1: `$ScopeDescribeDescribe2BeforeEach: $ScopeDescribeDescribe2BeforeEach"
         $True | Should -Be $True
      }
   }

}


