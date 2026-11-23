BeforeAll {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\PSRecall.psd1'
    Import-Module -Name $modulePath -Force
}

Describe 'PSRecall module' {
    It 'exports the expected public commands' {
        $commands = @(Get-Command -Module PSRecall | Select-Object -ExpandProperty Name)
        $commands | Should -Contain 'Get-PSRecall'
        $commands | Should -Contain 'Export-PSRecall'
    }

    It 'requires a valid ID range' {
        { Get-PSRecall -FromId 10 -ToId 5 } | Should -Throw
    }

    It 'rejects a non-ps1 export extension' {
        { Export-PSRecall -Last 1 -Path (Join-Path $TestDrive 'Recall.txt') } | Should -Throw
    }

    It 'accepts PSRecall entries through the pipeline' {
        $path = Join-Path $TestDrive 'PipelineRecall.ps1'
        $entry = [pscustomobject]@{
            Id              = 7
            ExecutionStatus = 'Completed'
            StartExecution  = Get-Date
            EndExecution    = Get-Date
            CommandLine     = 'Get-Date'
        }

        $result = $entry | Export-PSRecall -Path $path

        $result.EntryCount | Should -Be 1
        $result.FirstHistoryId | Should -Be 7
        Get-Content -LiteralPath $path -Raw | Should -Match 'Get-Date'
    }

    It 'does not overwrite an existing file unless Force is used' {
        $path = Join-Path $TestDrive 'Recall.ps1'
        Set-Content -LiteralPath $path -Value '# Existing'
        $entry = [pscustomobject]@{
            Id = 1
            ExecutionStatus = 'Completed'
            CommandLine = 'Get-Process'
        }

        { $entry | Export-PSRecall -Path $path } | Should -Throw
        { $entry | Export-PSRecall -Path $path -Force } | Should -Not -Throw
    }
}

AfterAll {
    Remove-Module -Name PSRecall -Force -ErrorAction SilentlyContinue
}
