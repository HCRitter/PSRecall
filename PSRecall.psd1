@{
    RootModule        = 'PSRecall.psm1'
    ModuleVersion     = '0.6.4'
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
            ReleaseNotes = 'Rebuilds all module files as readable PowerShell and fixes parser regressions while retaining output recovery, WPF selection, alias resolution, and all export formats.'
        }
    }
}
