function Get-PSRecall {
    <#
    .SYNOPSIS
        Selects commands from the current PowerShell session history.

    .DESCRIPTION
        Returns structured history entries from the current PowerShell process. Multiline input is
        retained as one history entry through the CommandLine property supplied by Get-History.

        Use Gui on Windows to select rows in a native multi-select dialog. The selected entries are
        returned to the pipeline and can be passed directly to Export-PSRecall.

        SuccessfulOnly means ExecutionStatus is Completed. It does not prove that a native process
        returned exit code zero and does not exclude every possible non-terminating error.

    .EXAMPLE
        Get-PSRecall -Gui | Export-PSRecall

    .EXAMPLE
        Get-PSRecall -All | Export-PSRecall -Path .\RecoveredSession.ps1

    .EXAMPLE
        Get-PSRecall -FromId 42 -ToId 68 -SuccessfulOnly
    #>
    [CmdletBinding(DefaultParameterSetName = 'Last')]
    [OutputType('PSRecall.HistoryEntry')]
    param (
        [Parameter(ParameterSetName = 'Last')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Last = 20,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        [Parameter(Mandatory, ParameterSetName = 'IdRange')]
        [ValidateRange(1, [long]::MaxValue)]
        [long]$FromId,

        [Parameter(Mandatory, ParameterSetName = 'IdRange')]
        [ValidateRange(1, [long]::MaxValue)]
        [long]$ToId,

        [Parameter()]
        [switch]$SuccessfulOnly,

        [Parameter()]
        [switch]$Gui
    )

    $selectionParameters = @{ SuccessfulOnly = $SuccessfulOnly }

    switch ($PSCmdlet.ParameterSetName) {
        'All' {
            $selectionParameters.All = $true
        }
        'IdRange' {
            $selectionParameters.FromId = $FromId
            $selectionParameters.ToId = $ToId
        }
        default {
            $selectionParameters.Last = $Last
        }
    }

    $selection = @(Get-PSRecallSelection @selectionParameters | ConvertTo-PSRecallEntry)
    if ($selection.Count -eq 0) {
        return
    }

    if ($Gui) {
        $selectedIds = @(Show-PSRecallHistoryDialog -History $selection)
        if ($selectedIds.Count -eq 0) {
            return
        }

        $selectedIdLookup = @{}
        foreach ($id in $selectedIds) {
            $selectedIdLookup[[long]$id] = $true
        }

        $selection = @($selection | Where-Object { $selectedIdLookup.ContainsKey([long]$_.Id) })
    }

    $selection
}
