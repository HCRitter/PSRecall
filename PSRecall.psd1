@{
    RootModule        = 'PSRecall.psm1'
    ModuleVersion     = '1.0.1'
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
            ReleaseNotes = 'Improves WPF dark-mode styling, adds a themed ComboBox and primary Export action, and recovers leading output when a large command has scrolled its prompt line outside the readable RawUI buffer.'
        }
    }
}
