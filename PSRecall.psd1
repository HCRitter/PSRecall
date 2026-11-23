@{
    RootModule        = 'PSRecall.psm1'
    ModuleVersion     = '0.7.2'
    GUID              = 'd3985247-ef18-4b71-8fcc-9545e812633b'
    Author            = 'Christian Ritter'
    CompanyName       = 'Community'
    Copyright         = '(c) 2026 Christian Ritter. All rights reserved.'
    Description       = 'Reconstruct reusable scripts and documentation from PowerShell session history.'
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
            Tags = @(
                'PowerShell'
                'History'
                'Recovery'
                'Session'
                'Script'
                'WPF'
                'AST'
                'Markdown'
            )
            ProjectUri   = 'https://github.com/HCRitter/PSRecall'
            LicenseUri   = 'https://github.com/HCRitter/PSRecall/blob/main/LICENSE'
            ReleaseNotes = 'Fixes WPF DataGrid loading by using the default automatic row sizing instead of the invalid RowHeight Auto value, while preserving multiline output rendering and GUI-controlled export.'
        }
    }
}
