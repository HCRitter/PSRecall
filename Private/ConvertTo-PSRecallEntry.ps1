function ConvertTo-PSRecallEntry {
    [CmdletBinding()]
    param([Parameter(Mandatory,ValueFromPipeline)][object]$InputObject)
    process {
        foreach ($name in 'Id','ExecutionStatus','CommandLine') {
            if ($null -eq $InputObject.PSObject.Properties[$name]) { throw "Pipeline input must contain '$name'." }
        }
        if ([string]::IsNullOrWhiteSpace([string]$InputObject.CommandLine)) { throw 'CommandLine must not be empty.' }
        $start = if ($InputObject.PSObject.Properties['StartExecution']) { $InputObject.StartExecution } else { $InputObject.StartExecutionTime }
        $end = if ($InputObject.PSObject.Properties['EndExecution']) { $InputObject.EndExecution } else { $InputObject.EndExecutionTime }
        [pscustomobject]@{
            PSTypeName='PSRecall.HistoryEntry'; Id=[long]$InputObject.Id
            ExecutionStatus=[string]$InputObject.ExecutionStatus
            StartExecution=$start; EndExecution=$end
            Duration=if ($start -and $end) { $end-$start } else { $null }
            CommandLine=[string]$InputObject.CommandLine
        }
    }
}
