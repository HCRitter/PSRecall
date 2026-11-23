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
