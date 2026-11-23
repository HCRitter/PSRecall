function Export-PSRecall {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Pipeline')]
    param (
        [Parameter(ValueFromPipeline, ParameterSetName = 'Pipeline')]
        [object]$InputObject,

        [string]$Path,

        [ValidateSet('PowerShell', 'Text', 'Markdown')]
        [string]$Format = 'PowerShell',

        [string]$Title = 'PSRecall Session Export',
        [switch]$ResolveAliases,
        [switch]$IncludeOutput,
        [switch]$IncludeSensitiveMetadata,
        [switch]$Force
    )

    begin {
        $items = [System.Collections.Generic.List[object]]::new()
        $explicitParameters = @{}
        foreach ($parameterName in $PSBoundParameters.Keys) {
            $explicitParameters[$parameterName] = $true
        }
    }

    process {
        if ($null -ne $InputObject) {
            $items.Add(($InputObject | ConvertTo-PSRecallEntry))
        }
    }

    end {
        if ($items.Count -eq 0) {
            throw 'No history entries supplied.'
        }

        $selection = @($items | Sort-Object -Property Id -Unique)
        $guiOptions = @(
            $selection |
                Where-Object { $null -ne $_.ExportOptions } |
                Select-Object -ExpandProperty ExportOptions -First 1
        )

        if ($guiOptions.Count -gt 0) {
            $options = $guiOptions[0]

            if (-not $explicitParameters.ContainsKey('Format') -and $options.Format) {
                $Format = [string]$options.Format
            }
            if (-not $explicitParameters.ContainsKey('Title') -and $options.Title) {
                $Title = [string]$options.Title
            }
            if (-not $explicitParameters.ContainsKey('IncludeOutput')) {
                $IncludeOutput = [bool]$options.IncludeOutput
            }
            if (-not $explicitParameters.ContainsKey('ResolveAliases')) {
                $ResolveAliases = [bool]$options.ResolveAliases
            }
            if (-not $explicitParameters.ContainsKey('IncludeSensitiveMetadata')) {
                $IncludeSensitiveMetadata = [bool]$options.IncludeSensitiveMetadata
            }
        }

        $formats = @{
            PowerShell = @{
                Extension = '.ps1'
                File      = 'RecoveredSession.ps1'
                Filter    = 'PowerShell script (*.ps1)|*.ps1'
            }
            Text = @{
                Extension = '.txt'
                File      = 'PSRecall-Session.txt'
                Filter    = 'Text file (*.txt)|*.txt'
            }
            Markdown = @{
                Extension = '.md'
                File      = 'PSRecall-Session.md'
                Filter    = 'Markdown file (*.md)|*.md'
            }
        }
        $specification = $formats[$Format]

        if (-not $Path) {
            $saveDialogParameters = @{
                SuggestedFileName = $specification.File
                Filter            = $specification.Filter
                DefaultExtension  = $specification.Extension
            }
            $Path = Show-PSRecallSaveDialog @saveDialogParameters
            if (-not $Path) {
                return
            }
        }

        $extension = [IO.Path]::GetExtension($Path)
        if (-not $extension) {
            $Path += $specification.Extension
        }
        elseif ($extension -ne $specification.Extension) {
            throw "Format '$Format' requires '$($specification.Extension)'."
        }

        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        if ((Test-Path -LiteralPath $resolvedPath) -and -not $Force) {
            throw "File exists: $resolvedPath. Use -Force."
        }

        $data = ConvertTo-PSRecallExportData -History $selection -ResolveAliases:$ResolveAliases
        foreach ($warning in $data.Warnings) {
            Write-Warning $warning
        }

        $presentationParameters = @{
            Entries                  = $data.Entries
            SelectionDescription     = 'Entries received through the pipeline'
            IncludeSensitiveMetadata = $IncludeSensitiveMetadata
            IncludeOutput            = $IncludeOutput
            Title                    = $Title
        }

        $presentation = switch ($Format) {
            'Text' {
                ConvertTo-PSRecallText @presentationParameters
            }
            'Markdown' {
                ConvertTo-PSRecallMarkdown @presentationParameters
            }
            default {
                [void]$presentationParameters.Remove('Title')
                ConvertTo-PSRecallScript @presentationParameters
            }
        }

        if ($PSCmdlet.ShouldProcess($resolvedPath, "Export as $Format")) {
            $encoding = if ($PSVersionTable.PSVersion.Major -ge 6) {
                'utf8NoBOM'
            }
            else {
                'utf8'
            }

            $setContentParameters = @{
                LiteralPath = $resolvedPath
                Value       = $presentation.Content
                Encoding    = $encoding
                Force       = $true
                ErrorAction = 'Stop'
            }
            Set-Content @setContentParameters

            [pscustomobject]@{
                PSTypeName         = 'PSRecall.ExportResult'
                Path               = $resolvedPath
                Format             = $Format
                EntryCount         = $selection.Count
                ResolvedAliasCount = $data.ResolvedAliasCount
                ParseErrorCount    = $data.ParseErrorCount
                OutputEntryCount   = $presentation.OutputEntryCount
            }
        }
    }
}
