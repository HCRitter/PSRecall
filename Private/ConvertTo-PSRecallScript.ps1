function ConvertTo-PSRecallScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][object[]]$History,
        [Parameter(Mandatory)][string]$SelectionDescription,
        [switch]$IncludeSensitiveMetadata,
        [switch]$ResolveAliases,
        [switch]$IncludeOutput
    )

    $orderedHistory = @($History | Sort-Object Id)
    $resolvedAliasCount = 0
    $parseErrorCount = 0
    $outputEntryCount = 0
    $warnings = [System.Collections.Generic.List[string]]::new()
    $body = [System.Collections.Generic.List[string]]::new()

    foreach ($entry in $orderedHistory) {
        $commandLine = [string]$entry.CommandLine
        if ($ResolveAliases) {
            $resolution = Resolve-PSRecallAlias -CommandLine $commandLine
            $commandLine = $resolution.CommandLine
            $resolvedAliasCount += $resolution.ResolvedAliasCount
            $parseErrorCount += $resolution.ParseErrorCount
            foreach ($warning in $resolution.Warnings) { $warnings.Add("History ID $($entry.Id): $warning") }
        }

        $body.Add("# History ID: $($entry.Id) | Status: $($entry.ExecutionStatus)")
        $body.Add($commandLine.TrimEnd())
        $body.Add('')

        if ($IncludeOutput -and -not [string]::IsNullOrWhiteSpace([string]$entry.Output)) {
            $outputEntryCount++
            $safeOutput = ([string]$entry.Output).Replace('#>', '# >')
            $body.Add('<#')
            $body.Add("    Output for $commandLine with history ID $($entry.Id):")
            $body.Add('    -------------------------------------------')
            foreach ($outputLine in ($safeOutput -split "`r?`n")) {
                $body.Add("    $outputLine")
            }
            $body.Add('#>')
            $body.Add('')
        }
    }

    $header = [System.Collections.Generic.List[string]]::new()
    $header.Add('#requires -Version 5.1'); $header.Add(''); $header.Add('<#'); $header.Add('.SYNOPSIS')
    $header.Add('    Reconstructed PowerShell commands exported from the current session by PSRecall.')
    $header.Add(''); $header.Add('.NOTES')
    $header.Add("    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
    $header.Add("    PowerShell: $($PSVersionTable.PSVersion)"); $header.Add("    Edition: $($PSVersionTable.PSEdition)")
    $header.Add("    Selection: $SelectionDescription"); $header.Add("    History IDs: $($orderedHistory[0].Id)-$($orderedHistory[-1].Id)")
    $header.Add("    Exported entries: $($orderedHistory.Count)"); $header.Add("    Aliases resolved: $resolvedAliasCount")
    $header.Add("    Output blocks exported: $outputEntryCount")
    if ($IncludeSensitiveMetadata) {
        $header.Add("    Computer: $env:COMPUTERNAME"); $header.Add("    User: $([Environment]::UserName)")
        $header.Add("    Working directory: $((Get-Location).Path)")
    }
    $header.Add(''); $header.Add('    Review the generated script before execution and sharing.')
    $header.Add('#>'); $header.Add(''); $header.Add('Set-StrictMode -Version Latest')
    $header.Add("`$ErrorActionPreference = 'Stop'"); $header.Add('')

    [pscustomobject]@{
        Content = (@($header) + @($body)) -join [Environment]::NewLine
        ResolvedAliasCount = $resolvedAliasCount; ParseErrorCount = $parseErrorCount
        OutputEntryCount = $outputEntryCount; Warnings = @($warnings)
    }
}
