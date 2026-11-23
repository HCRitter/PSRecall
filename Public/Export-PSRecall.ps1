function Export-PSRecall {
    <#
    .SYNOPSIS
        Exports PSRecall history entries to a PowerShell script file.

    .DESCRIPTION
        Accepts entries from Get-PSRecall through the pipeline. If Path is omitted on Windows, a
        native Save File dialog is displayed. On macOS and Linux, Path is required.

        Export-PSRecall can still select directly from Get-History when no pipeline input is used.

    .EXAMPLE
        Get-PSRecall -Gui | Export-PSRecall

    .EXAMPLE
        Get-PSRecall -All | Export-PSRecall -Path .\RecoveredSession.ps1

    .EXAMPLE
        Export-PSRecall -Last 20 -SuccessfulOnly -Path .\WorkingCommands.ps1
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low', DefaultParameterSetName = 'DirectLast')]
    [OutputType('PSRecall.ExportResult')]
    param (
        [Parameter(ValueFromPipeline, ParameterSetName = 'Pipeline')]
        [ValidateNotNull()]
        [object]$InputObject,

        [Parameter(Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(ParameterSetName = 'DirectLast')]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Last = 20,

        [Parameter(Mandatory, ParameterSetName = 'DirectAll')]
        [switch]$All,

        [Parameter(Mandatory, ParameterSetName = 'DirectIdRange')]
        [ValidateRange(1, [long]::MaxValue)]
        [long]$FromId,

        [Parameter(Mandatory, ParameterSetName = 'DirectIdRange')]
        [ValidateRange(1, [long]::MaxValue)]
        [long]$ToId,

        [Parameter(ParameterSetName = 'DirectLast')]
        [Parameter(ParameterSetName = 'DirectAll')]
        [Parameter(ParameterSetName = 'DirectIdRange')]
        [switch]$SuccessfulOnly,

        [Parameter()]
        [switch]$IncludeSensitiveMetadata,

        [Parameter()]
        [switch]$Force
    )

    begin {
        $pipelineEntries = [System.Collections.Generic.List[object]]::new()
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline') {
            $entry = $InputObject | ConvertTo-PSRecallEntry
            $pipelineEntries.Add($entry)
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline') {
            $selection = @($pipelineEntries | Sort-Object -Property Id -Unique)
            $selectionDescription = 'Entries received through the pipeline'
        }
        else {
            $selectionParameters = @{ SuccessfulOnly = $SuccessfulOnly }
            switch ($PSCmdlet.ParameterSetName) {
                'DirectAll' {
                    $selectionParameters.All = $true
                    $selectionDescription = 'All available history entries'
                }
                'DirectIdRange' {
                    $selectionParameters.FromId = $FromId
                    $selectionParameters.ToId = $ToId
                    $selectionDescription = "Inclusive history ID range $FromId-$ToId"
                }
                default {
                    $selectionParameters.Last = $Last
                    $selectionDescription = "Last $Last history entries"
                }
            }

            if ($SuccessfulOnly) {
                $selectionDescription += ', completed entries only'
            }

            $selection = @(Get-PSRecallSelection @selectionParameters | ConvertTo-PSRecallEntry)
        }

        if ($selection.Count -eq 0) {
            throw 'No history entries were supplied or matched the requested selection.'
        }

        if (-not $Path) {
            $Path = Show-PSRecallSaveDialog -SuggestedFileName 'RecoveredSession.ps1'
            if (-not $Path) {
                Write-Verbose 'The export was cancelled.'
                return
            }
        }

        $extension = [System.IO.Path]::GetExtension($Path)
        if ($extension -and $extension -ne '.ps1') {
            throw "Path must target a PowerShell script file with the '.ps1' extension. Received: '$Path'."
        }

        if (-not $extension) {
            $Path = "$Path.ps1"
        }

        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $parentPath = Split-Path -Path $resolvedPath -Parent

        if (-not (Test-Path -LiteralPath $parentPath -PathType Container)) {
            throw "The destination directory does not exist: '$parentPath'."
        }

        if ((Test-Path -LiteralPath $resolvedPath -PathType Leaf) -and -not $Force) {
            throw "The destination file already exists: '$resolvedPath'. Use -Force to overwrite it."
        }

        $scriptParameters = @{
            History                  = $selection
            SelectionDescription     = $selectionDescription
            IncludeSensitiveMetadata = $IncludeSensitiveMetadata
        }
        $content = ConvertTo-PSRecallScript @scriptParameters

        if ($PSCmdlet.ShouldProcess($resolvedPath, "Export $($selection.Count) history entries")) {
            $encoding = if ($PSVersionTable.PSVersion.Major -ge 6) { 'utf8NoBOM' } else { 'utf8' }
            $setContentParameters = @{
                LiteralPath = $resolvedPath
                Value       = $content
                Encoding    = $encoding
                Force       = $true
                ErrorAction = 'Stop'
            }
            Set-Content @setContentParameters

            $file = Get-Item -LiteralPath $resolvedPath -ErrorAction Stop
            [pscustomobject]@{
                PSTypeName     = 'PSRecall.ExportResult'
                Path           = $file.FullName
                EntryCount     = $selection.Count
                FirstHistoryId = $selection[0].Id
                LastHistoryId  = $selection[-1].Id
                ExportedAt     = Get-Date
            }
        }
    }
}
