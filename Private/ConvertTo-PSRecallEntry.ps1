function ConvertTo-PSRecallEntry {
    [CmdletBinding()]
    [OutputType('PSRecall.HistoryEntry')]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    process {
        $requiredProperties = @('Id', 'ExecutionStatus', 'CommandLine')
        foreach ($propertyName in $requiredProperties) {
            if ($null -eq $InputObject.PSObject.Properties[$propertyName]) {
                throw "Pipeline input must contain an '$propertyName' property."
            }
        }

        if ([string]::IsNullOrWhiteSpace([string]$InputObject.CommandLine)) {
            throw 'Pipeline input contains an empty CommandLine value.'
        }

        $startExecution = $null
        $endExecution = $null
        $duration = $null

        if ($null -ne $InputObject.PSObject.Properties['StartExecution']) {
            $startExecution = $InputObject.StartExecution
        }
        elseif ($null -ne $InputObject.PSObject.Properties['StartExecutionTime']) {
            $startExecution = $InputObject.StartExecutionTime
        }

        if ($null -ne $InputObject.PSObject.Properties['EndExecution']) {
            $endExecution = $InputObject.EndExecution
        }
        elseif ($null -ne $InputObject.PSObject.Properties['EndExecutionTime']) {
            $endExecution = $InputObject.EndExecutionTime
        }

        if ($startExecution -and $endExecution) {
            $duration = $endExecution - $startExecution
        }

        [pscustomobject]@{
            PSTypeName      = 'PSRecall.HistoryEntry'
            Id              = [long]$InputObject.Id
            ExecutionStatus = [string]$InputObject.ExecutionStatus
            StartExecution  = $startExecution
            EndExecution    = $endExecution
            Duration        = $duration
            CommandLine     = [string]$InputObject.CommandLine
        }
    }
}
