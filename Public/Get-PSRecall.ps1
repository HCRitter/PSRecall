function Get-PSRecall {
    [CmdletBinding(DefaultParameterSetName = 'Last')]
    param (
        [Parameter(ParameterSetName = 'Last')][ValidateRange(1, [int]::MaxValue)][int]$Last = 20,
        [Parameter(Mandatory, ParameterSetName = 'All')][switch]$All,
        [Parameter(Mandatory, ParameterSetName = 'IdRange')][long]$FromId,
        [Parameter(Mandatory, ParameterSetName = 'IdRange')][long]$ToId,
        [switch]$SuccessfulOnly,
        [switch]$IncludeOutput,
        [switch]$Gui
    )

    $selectionParameters = @{ SuccessfulOnly = $SuccessfulOnly }
    switch ($PSCmdlet.ParameterSetName) {
        'All' { $selectionParameters.All = $true }
        'IdRange' { $selectionParameters.FromId = $FromId; $selectionParameters.ToId = $ToId }
        default { $selectionParameters.Last = $Last }
    }

    $selection = @(Get-PSRecallSelection @selectionParameters)
    if ($IncludeOutput -and $selection.Count -gt 0) {
        $outputParameters = @{
            AllHistory        = @(Get-History | Sort-Object Id)
            SelectedHistory   = $selection
            CurrentInvocation = $MyInvocation.Line
        }
        try {
            $selection = @(Add-PSRecallOutput @outputParameters)
        }
        catch {
            Write-Warning $_.Exception.Message
            $selection = @($selection | ConvertTo-PSRecallEntry)
        }
    }
    else {
        $selection = @($selection | ConvertTo-PSRecallEntry)
    }

    if ($Gui -and $selection.Count -gt 0) {
        $selectedIds = @(Show-PSRecallHistoryDialog -History $selection)
        $selection = @($selection | Where-Object { $_.Id -in $selectedIds })
    }

    $selection
}
