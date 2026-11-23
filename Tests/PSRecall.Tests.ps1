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
