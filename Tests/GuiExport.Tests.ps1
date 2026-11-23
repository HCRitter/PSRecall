BeforeAll {
    Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..\PSRecall.psd1') -Force
}

Describe 'GUI export option propagation' {
    It 'preserves ExportOptions while converting pipeline entries' {
        InModuleScope PSRecall {
            $options = [pscustomobject]@{
                Format                   = 'Markdown'
                Title                    = 'Customer Troubleshooting'
                IncludeOutput            = $true
                ResolveAliases           = $true
                IncludeSensitiveMetadata = $false
            }
            $entry = [pscustomobject]@{
                Id              = 1
                ExecutionStatus = 'Completed'
                CommandLine     = 'Get-Date'
                Output          = 'Sunday'
                ExportOptions   = $options
            }

            $converted = $entry | ConvertTo-PSRecallEntry
            $converted.ExportOptions.Format | Should -Be 'Markdown'
            $converted.ExportOptions.Title | Should -Be 'Customer Troubleshooting'
        }
    }

    It 'uses GUI options when export parameters were not explicitly supplied' {
        $path = Join-Path -Path $TestDrive -ChildPath 'Recall.md'
        $entry = [pscustomobject]@{
            Id              = 1
            ExecutionStatus = 'Completed'
            CommandLine     = 'Get-Date'
            Output          = 'Sunday'
            ExportOptions   = [pscustomobject]@{
                Format                   = 'Markdown'
                Title                    = 'GUI Title'
                IncludeOutput            = $true
                ResolveAliases           = $false
                IncludeSensitiveMetadata = $false
            }
        }

        $result = $entry | Export-PSRecall -Path $path
        $result.Format | Should -Be 'Markdown'
        (Get-Content -LiteralPath $path -Raw) | Should -Match '# GUI Title'
        (Get-Content -LiteralPath $path -Raw) | Should -Match 'Sunday'
    }

    It 'gives explicit export parameters precedence over GUI options' {
        $path = Join-Path -Path $TestDrive -ChildPath 'Recall.txt'
        $entry = [pscustomobject]@{
            Id              = 1
            ExecutionStatus = 'Completed'
            CommandLine     = 'Get-Date'
            Output          = 'Sunday'
            ExportOptions   = [pscustomobject]@{
                Format                   = 'Markdown'
                Title                    = 'GUI Title'
                IncludeOutput            = $true
                ResolveAliases           = $false
                IncludeSensitiveMetadata = $false
            }
        }

        $result = $entry | Export-PSRecall -Path $path -Format Text -IncludeOutput:$false
        $result.Format | Should -Be 'Text'
        (Get-Content -LiteralPath $path -Raw) | Should -Not -Match 'Sunday'
    }
}

AfterAll {
    Remove-Module -Name PSRecall -Force -ErrorAction SilentlyContinue
}
