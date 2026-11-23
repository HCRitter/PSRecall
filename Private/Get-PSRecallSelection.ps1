function Get-PSRecallSelection {
    [CmdletBinding(DefaultParameterSetName = 'Last')]
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

        [switch]$SuccessfulOnly
    )

    if ($PSCmdlet.ParameterSetName -eq 'IdRange' -and $FromId -gt $ToId) {
        throw "FromId '$FromId' must be less than or equal to ToId '$ToId'."
    }

    $history = @(Get-History -ErrorAction Stop | Sort-Object -Property Id)
    $selection = switch ($PSCmdlet.ParameterSetName) {
        'All' { $history }
        'IdRange' { @($history | Where-Object { $_.Id -ge $FromId -and $_.Id -le $ToId }) }
        default { @($history | Select-Object -Last $Last) }
    }

    if ($SuccessfulOnly) {
        $selection = @($selection | Where-Object ExecutionStatus -eq 'Completed')
    }

    $selection
}
