function ConvertTo-PSRecallExportData {
    [CmdletBinding()]
    param ([Parameter(Mandatory)][object[]]$History, [switch]$ResolveAliases)

    $resolvedAliasCount = 0
    $parseErrorCount = 0
    $warnings = [System.Collections.Generic.List[string]]::new()

    $entries = foreach ($entry in @($History | Sort-Object -Property Id)) {
        $commandLine = [string]$entry.CommandLine
        if ($ResolveAliases) {
            $resolution = Resolve-PSRecallAlias -CommandLine $commandLine
            $commandLine = $resolution.CommandLine
            $resolvedAliasCount += $resolution.ResolvedAliasCount
            $parseErrorCount += $resolution.ParseErrorCount
            foreach ($warning in $resolution.Warnings) {
                $warnings.Add("History ID $($entry.Id): $warning")
            }
        }

        [pscustomobject]@{
            Id              = $entry.Id
            ExecutionStatus = $entry.ExecutionStatus
            StartExecution  = $entry.StartExecution
            EndExecution    = $entry.EndExecution
            Duration        = $entry.Duration
            CommandLine     = $commandLine
            Output          = $entry.Output
        }
    }

    [pscustomobject]@{
        Entries            = @($entries)
        ResolvedAliasCount = $resolvedAliasCount
        ParseErrorCount    = $parseErrorCount
        Warnings           = @($warnings)
    }
}
