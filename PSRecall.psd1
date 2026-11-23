@{
    RootModule        = 'PSRecall.psm1'
    ModuleVersion     = '0.5.2'
    GUID              = 'd3985247-ef18-4b71-8fcc-9545e812633b'
    Author            = 'Christian Ritter'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 Christian Ritter. All rights reserved.'
    Description       = 'Reconstruct reusable PowerShell scripts from session history with optional output recovery, WPF selection, and AST-based alias resolution.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @('Export-PSRecall', 'Get-PSRecall')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('PowerShell', 'History', 'Recovery', 'Session', 'Script', 'WPF', 'AST')
            ProjectUri   = 'https://github.com/HCRitter/PSRecall'
            LicenseUri   = 'https://github.com/HCRitter/PSRecall/blob/main/LICENSE'
            ReleaseNotes = 'Uses the latest active Get-PSRecall invocation as the output boundary to avoid matching older recall commands in terminal scrollback.'
        }
    }
}
