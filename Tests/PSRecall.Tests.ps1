BeforeAll { Import-Module (Join-Path $PSScriptRoot '..\PSRecall.psd1') -Force }
Describe 'PSRecall module' {
    It 'exports public commands' { Get-Command -Module PSRecall | Select-Object -ExpandProperty Name | Should -Contain 'Get-PSRecall' }
    It 'rejects invalid ranges' { { Get-PSRecall -FromId 10 -ToId 5 } | Should -Throw }
    It 'exports output comments only when requested' {
        $path = Join-Path $TestDrive 'output.ps1'
        $entry = [pscustomobject]@{ Id=1; ExecutionStatus='Completed'; CommandLine='Get-Date'; Output='Simulated output' }
        $result = $entry | Export-PSRecall -Path $path -IncludeOutput
        (Get-Content $path -Raw) | Should -Match 'Output for Get-Date with history ID 1'
        $result.OutputEntryCount | Should -Be 1
    }
    It 'escapes a comment terminator in captured output' {
        $path = Join-Path $TestDrive 'safe-output.ps1'
        [pscustomobject]@{ Id=2; ExecutionStatus='Completed'; CommandLine='Get-Date'; Output='unsafe #> text' } |
            Export-PSRecall -Path $path -IncludeOutput | Out-Null
        (Get-Content $path -Raw) | Should -Match '# >'
    }
    It 'preserves output on pipeline conversion' {
        InModuleScope PSRecall {
            $entry = [pscustomobject]@{ Id=3; ExecutionStatus='Completed'; CommandLine='Get-Date'; Output='value' }
            ($entry | ConvertTo-PSRecallEntry).Output | Should -Be 'value'
        }
    }
}
AfterAll { Remove-Module PSRecall -Force -ErrorAction SilentlyContinue }
