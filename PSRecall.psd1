@{
    RootModule        = 'PSRecall.psm1'
    ModuleVersion     = '0.3.0'
    GUID              = 'd3985247-ef18-4b71-8fcc-9545e812633b'
    Author            = 'Christian Ritter'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 Christian Ritter. All rights reserved.'
    Description       = 'Reconstruct reusable PowerShell scripts from the current session history, optionally using a WPF visual selector.'
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
            Tags       = @('PowerShell', 'History', 'Recovery', 'Session', 'Script', 'GUI')
            ProjectUri = 'https://github.com/HCRitter/PSRecall'
            LicenseUri = 'https://github.com/HCRitter/PSRecall/blob/main/LICENSE'
            ReleaseNotes = 'Replaces the Windows Forms selector with WPF and retains SaveFileDialog and pipeline export support.'
        }
    }
}
