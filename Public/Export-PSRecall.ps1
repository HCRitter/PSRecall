function Export-PSRecall {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low', DefaultParameterSetName = 'DirectLast')]
    param (
        [Parameter(ValueFromPipeline, ParameterSetName = 'Pipeline')][object]$InputObject,
        [string]$Path,
        [Parameter(ParameterSetName = 'DirectLast')][ValidateRange(1, [int]::MaxValue)][int]$Last = 20,
        [Parameter(Mandatory, ParameterSetName = 'DirectAll')][switch]$All,
        [Parameter(Mandatory, ParameterSetName = 'DirectIdRange')][long]$FromId,
        [Parameter(Mandatory, ParameterSetName = 'DirectIdRange')][long]$ToId,
        [Parameter(ParameterSetName = 'DirectLast')][Parameter(ParameterSetName = 'DirectAll')][Parameter(ParameterSetName = 'DirectIdRange')][switch]$SuccessfulOnly,
        [switch]$ResolveAliases,
        [switch]$IncludeOutput,
        [switch]$IncludeSensitiveMetadata,
        [switch]$Force
    )

    begin { $pipelineEntries = [System.Collections.Generic.List[object]]::new() }
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline') { $pipelineEntries.Add(($InputObject | ConvertTo-PSRecallEntry)) }
    }
    end {
        if ($PSCmdlet.ParameterSetName -eq 'Pipeline') {
            $selection = @($pipelineEntries | Sort-Object Id -Unique)
            $description = 'Entries received through the pipeline'
        }
        else {
            $parameters = @{ SuccessfulOnly = $SuccessfulOnly }
            switch ($PSCmdlet.ParameterSetName) {
                'DirectAll' { $parameters.All = $true; $description = 'All available history entries' }
                'DirectIdRange' { $parameters.FromId = $FromId; $parameters.ToId = $ToId; $description = "Inclusive history ID range $FromId-$ToId" }
                default { $parameters.Last = $Last; $description = "Last $Last history entries" }
            }
            $selection = @(Get-PSRecallSelection @parameters | ConvertTo-PSRecallEntry)
        }
        if (-not $selection.Count) { throw 'No history entries were supplied or matched.' }
        if (-not $Path) { $Path = Show-PSRecallSaveDialog; if (-not $Path) { return } }
        $extension = [IO.Path]::GetExtension($Path)
        if ($extension -and $extension -ne '.ps1') { throw 'Path must use the .ps1 extension.' }
        if (-not $extension) { $Path = "$Path.ps1" }
        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $parentPath = Split-Path $resolvedPath -Parent
        if (-not (Test-Path $parentPath -PathType Container)) { throw "Directory does not exist: $parentPath" }
        if ((Test-Path $resolvedPath) -and -not $Force) { throw "File exists: $resolvedPath. Use -Force." }

        $scriptParameters = @{
            History = $selection; SelectionDescription = $description
            IncludeSensitiveMetadata = $IncludeSensitiveMetadata
            ResolveAliases = $ResolveAliases; IncludeOutput = $IncludeOutput
        }
        $result = ConvertTo-PSRecallScript @scriptParameters
        foreach ($warning in $result.Warnings) { Write-Warning $warning }

        if ($PSCmdlet.ShouldProcess($resolvedPath, "Export $($selection.Count) history entries")) {
            $encoding = if ($PSVersionTable.PSVersion.Major -ge 6) { 'utf8NoBOM' } else { 'utf8' }
            Set-Content -LiteralPath $resolvedPath -Value $result.Content -Encoding $encoding -Force
            [pscustomobject]@{
                PSTypeName = 'PSRecall.ExportResult'; Path = $resolvedPath; EntryCount = $selection.Count
                FirstHistoryId = $selection[0].Id; LastHistoryId = $selection[-1].Id
                ResolvedAliasCount = $result.ResolvedAliasCount; ParseErrorCount = $result.ParseErrorCount
                OutputEntryCount = $result.OutputEntryCount; ExportedAt = Get-Date
            }
        }
    }
}
