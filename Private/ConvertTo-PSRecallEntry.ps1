function ConvertTo-PSRecallEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject
    )

    process {
        foreach ($propertyName in @('Id', 'ExecutionStatus', 'CommandLine')) {
            if ($null -eq $InputObject.PSObject.Properties[$propertyName]) {
                throw "Pipeline input must contain an '$propertyName' property."
            }
        }

        $startExecution = if ($null -ne $InputObject.PSObject.Properties['StartExecution']) {
            $InputObject.StartExecution
        }
        else {
            $InputObject.StartExecutionTime
        }

        $endExecution = if ($null -ne $InputObject.PSObject.Properties['EndExecution']) {
            $InputObject.EndExecution
        }
        else {
            $InputObject.EndExecutionTime
        }

        $output = if ($null -ne $InputObject.PSObject.Properties['Output']) {
            [string]$InputObject.Output
        }
        else {
            $null
        }

        [pscustomobject]@{
            PSTypeName      = 'PSRecall.HistoryEntry'
            Id              = [long]$InputObject.Id
            ExecutionStatus = [string]$InputObject.ExecutionStatus
            StartExecution  = $startExecution
            EndExecution    = $endExecution
            Duration        = if ($startExecution -and $endExecution) {
                $endExecution - $startExecution
            }
            else {
                $null
            }
            CommandLine     = [string]$InputObject.CommandLine
            Output          = $output
        }
    }
}
