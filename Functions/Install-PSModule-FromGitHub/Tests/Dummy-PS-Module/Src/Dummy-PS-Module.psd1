@{
    RootModule = 'Dummy-PS-Module.psm1';
    ModuleVersion = '2.0.0';
    GUID = '695769e7-a4f4-4483-9796-d1f208aecbca';
    Author = 'Thomas Schittli';
    CompanyName = 'Thomas Schittli';
    Copyright = '(c) 2016 Thomas Schittli. All rights reserved.';
    Description = 'Test Dummy PS Module';
    PowerShellVersion = '4.0';
    FunctionsToExport = @('Install-Dummy-PS-Module');
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell','GitHub','Repository','Install','Development','Module','DSC')
            LicenseUri = 'https://raw.githubusercontent.com/iainbrighton/Dummy-PS-Module/master/LICENSE';
            ProjectUri = 'https://github.com/iainbrighton/Dummy-PS-Module';
            # IconUri = '';
        } # End of PSData hashtable
    } # End of PrivateData hashtable
}
