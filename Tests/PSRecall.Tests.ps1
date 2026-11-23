BeforeAll { Import-Module (Join-Path $PSScriptRoot '..\PSRecall.psd1') -Force }
Describe 'PSRecall regression checks' {
    It 'contains readable valid foreach syntax' {
        $content = Get-Content (Join-Path $PSScriptRoot '..\Private\ConvertTo-PSRecallEntry.ps1') -Raw
        $content | Should -Match 'foreach \(\$propertyName in @\('
    }
    It 'declares the XAML x namespace' {
        $content = Get-Content (Join-Path $PSScriptRoot '..\Private\Show-PSRecallHistoryDialog.ps1') -Raw
        $content | Should -Match 'xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"'
    }
    It 'keeps valid UserName interpolation' {
        $content = Get-Content (Join-Path $PSScriptRoot '..\Private\ConvertTo-PSRecallScript.ps1') -Raw
        $content | Should -Match '\$\(\[Environment\]::UserName\)'
    }
}
AfterAll { Remove-Module PSRecall -Force -ErrorAction SilentlyContinue }

Describe 'PSRecall 0.7.1 GUI output regression checks' {
    It 'keeps multiline output bound to the Output property' {
        $dialogPath = Join-Path $PSScriptRoot '..\Private\Show-PSRecallHistoryDialog.ps1'
        $content = Get-Content -LiteralPath $dialogPath -Raw

        $content | Should -Match 'Header="Output" Binding="\{Binding Output\}"'
        $content | Should -Match 'Property="TextWrapping" Value="Wrap"'
        $content | Should -Match 'Property="ToolTip" Value="\{Binding Output\}"'
    }

    It 'keeps chronological output reconstruction unchanged' {
        $outputPath = Join-Path $PSScriptRoot '..\Private\Add-PSRecallOutput.ps1'
        $content = Get-Content -LiteralPath $outputPath -Raw

        $content | Should -Match '\$searchStart = 0'
        $content | Should -Match '\$searchStart = \$commandEnd \+ 1'
        $content | Should -Match '\$invocationBoundary - 1'
    }
}

Describe 'PSRecall 0.7.2 WPF loading regression check' {
    It 'does not assign the invalid Auto value to DataGrid RowHeight' {
        $dialogPath = Join-Path $PSScriptRoot '..\Private\Show-PSRecallHistoryDialog.ps1'
        $content = Get-Content -LiteralPath $dialogPath -Raw

        $content | Should -Not -Match 'RowHeight="Auto"'
        $content | Should -Match 'Property="TextWrapping" Value="Wrap"'
        $content | Should -Match 'Property="ToolTip" Value="\{Binding Output\}"'
    }
}


Describe 'PSRecall 1.0 theme regression checks' {
    BeforeAll {
        $dialogPath = Join-Path $PSScriptRoot '..\Private\Show-PSRecallHistoryDialog.ps1'
        $script:dialogContent = Get-Content -LiteralPath $dialogPath -Raw
    }
    It 'provides System Light and Dark theme choices' {
        $dialogContent | Should -Match '<ComboBoxItem Content="System"'
        $dialogContent | Should -Match '<ComboBoxItem Content="Light"'
        $dialogContent | Should -Match '<ComboBoxItem Content="Dark"'
    }
    It 'defines dynamic theme resources and system detection' {
        $dialogContent | Should -Match 'x:Key="WindowBackgroundBrush"'
        $dialogContent | Should -Match 'x:Key="SelectionBrush"'
        $dialogContent | Should -Match 'DynamicResource ForegroundBrush'
        $dialogContent | Should -Match 'AppsUseLightTheme'
    }
    It 'does not restore the invalid automatic RowHeight assignment' {
        $dialogContent | Should -Not -Match 'RowHeight="Auto"'
    }
}

Describe 'PSRecall 1.0.1 output and styling regression checks' {
    It 'recovers leading output when exactly one preceding history command has scrolled out of RawUI' {
        InModuleScope PSRecall {
            Mock Get-PSRecallBufferLines {
                @(
                    'Directory: C:\Users\example'
                    'Mode   LastWriteTime   Length Name'
                    'd----  2026-11-23             Documents'
                    'PS> get-date'
                    'Monday, 23 November 2026 14:57:42'
                    'PS> Get-PSRecall -All -IncludeOutput'
                )
            }

            $history = @(
                [pscustomobject]@{ Id = 1; ExecutionStatus = 'Completed'; CommandLine = 'gci' }
                [pscustomobject]@{ Id = 2; ExecutionStatus = 'Completed'; CommandLine = 'get-date' }
            )

            $result = @(
                Add-PSRecallOutput -AllHistory $history -SelectedHistory $history -CurrentInvocation 'Get-PSRecall -All -IncludeOutput'
            )

            $result[0].Output | Should -Match 'Directory: C:\Users\example'
            $result[0].Output | Should -Match 'Documents'
            $result[1].Output | Should -Be 'Monday, 23 November 2026 14:57:42'
        }
    }

    It 'does not guess leading output when multiple history commands are missing from RawUI' {
        InModuleScope PSRecall {
            Mock Get-PSRecallBufferLines {
                @(
                    'unattributed output'
                    'PS> get-date'
                    'Monday'
                    'PS> Get-PSRecall -All -IncludeOutput'
                )
            }

            $history = @(
                [pscustomobject]@{ Id = 1; ExecutionStatus = 'Completed'; CommandLine = 'gci' }
                [pscustomobject]@{ Id = 2; ExecutionStatus = 'Completed'; CommandLine = 'Get-Process' }
                [pscustomobject]@{ Id = 3; ExecutionStatus = 'Completed'; CommandLine = 'get-date' }
            )

            $result = @(
                Add-PSRecallOutput -AllHistory $history -SelectedHistory $history -CurrentInvocation 'Get-PSRecall -All -IncludeOutput'
            )

            $result[0].Output | Should -BeNullOrEmpty
            $result[1].Output | Should -BeNullOrEmpty
            $result[2].Output | Should -Be 'Monday'
        }
    }

    It 'uses a custom themed ComboBox template and primary Export button' {
        $dialogPath = Join-Path $PSScriptRoot '..\Private\Show-PSRecallHistoryDialog.ps1'
        $content = Get-Content -LiteralPath $dialogPath -Raw

        $content | Should -Match '<ControlTemplate TargetType="ComboBox">'
        $content | Should -Match 'DynamicResource AccentBrush'
        $content | Should -Match 'PrimaryButtonStyle'
        $content | Should -Match 'AccentForegroundBrush'
    }
}
