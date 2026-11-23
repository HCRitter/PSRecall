@{
    RootModule        = 'PSRecall.psm1'
    ModuleVersion     = '0.4.0'
    GUID              = 'd3985247-ef18-4b71-8fcc-9545e812633b'
    Author            = 'Christian Ritter'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 Christian Ritter. All rights reserved.'
    Description       = 'Reconstruct reusable PowerShell scripts from the current session history, with optional WPF selection and AST-based alias resolution.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Export-PSRecall'
        'Get-PSRecall'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('PowerShell', 'History', 'Recovery', 'Session', 'Script', 'WPF', 'AST')
            ProjectUri   = 'https://github.com/HCRitter/PSRecall'
            LicenseUri   = 'https://github.com/HCRitter/PSRecall/blob/main/LICENSE'
            ReleaseNotes = 'Adds optional AST-based alias resolution during script export while retaining the existing WPF GUI and pipeline workflows.'
        }
    }
}
