function Get-PSRecall {
    [CmdletBinding(DefaultParameterSetName = 'Last')]
    param (
        [Parameter(ParameterSetName = 'Last')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Last = 20,

        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        [Parameter(Mandatory, ParameterSetName = 'IdRange')]
        [long]$FromId,

        [Parameter(Mandatory, ParameterSetName = 'IdRange')]
        [long]$ToId,

        [switch]$SuccessfulOnly,
        [switch]$IncludeOutput,
        [switch]$Gui
    )

    $selectionParameters = @{
        SuccessfulOnly = $SuccessfulOnly
    }

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

    $selection = @(Get-PSRecallSelection @selectionParameters)

    if ($IncludeOutput -and $selection.Count -gt 0) {
        $outputParameters = @{
            AllHistory        = @(Get-History | Sort-Object -Property Id)
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

    if (-not $Gui -or $selection.Count -eq 0) {
        $selection
        return
    }

    $guiResult = Show-PSRecallHistoryDialog -History $selection -DefaultIncludeOutput:$IncludeOutput
    if ($null -eq $guiResult -or $guiResult.Action -eq 'Cancel') {
        return
    }

    $selectedEntries = @(
        $selection | Where-Object { $_.Id -in $guiResult.SelectedIds }
    )

    $exportOptions = [pscustomobject]@{
        PSTypeName               = 'PSRecall.ExportOptions'
        Format                   = $guiResult.Format
        Title                    = $guiResult.Title
        IncludeOutput            = $guiResult.IncludeOutput
        ResolveAliases           = $guiResult.ResolveAliases
        IncludeSensitiveMetadata = $guiResult.IncludeSensitiveMetadata
    }

    foreach ($entry in $selectedEntries) {
        $entry.ExportOptions = $exportOptions
    }

    if ($guiResult.Action -eq 'Export') {
        $exportParameters = @{
            Format                   = $exportOptions.Format
            Title                    = $exportOptions.Title
            IncludeOutput            = $exportOptions.IncludeOutput
            ResolveAliases           = $exportOptions.ResolveAliases
            IncludeSensitiveMetadata = $exportOptions.IncludeSensitiveMetadata
        }

        $selectedEntries |
            Export-PSRecall @exportParameters
        return
    }

    $selectedEntries
}
