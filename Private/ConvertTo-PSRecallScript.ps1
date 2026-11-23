function ConvertTo-PSRecallScript {
    [CmdletBinding()]
    [OutputType('PSRecall.ScriptConversionResult')]
    param (
        [Parameter(Mandatory)]
        [object[]]$History,

        [Parameter(Mandatory)]
        [string]$SelectionDescription,

        [Parameter()]
        [switch]$IncludeSensitiveMetadata,

        [Parameter()]
        [switch]$ResolveAliases
    )

    $orderedHistory = @($History | Sort-Object -Property Id)
    $resolvedAliasCount = 0
    $parseErrorCount = 0
    $warnings = [System.Collections.Generic.List[string]]::new()

    $commands = foreach ($entry in $orderedHistory) {
        $commandLine = [string]$entry.CommandLine

        if ($ResolveAliases) {
            $resolution = Resolve-PSRecallAlias -CommandLine $commandLine
            $commandLine = $resolution.CommandLine
            $resolvedAliasCount += $resolution.ResolvedAliasCount
            $parseErrorCount += $resolution.ParseErrorCount

            foreach ($warning in $resolution.Warnings) {
                $warnings.Add("History ID $($entry.Id): $warning")
            }
        }

        [pscustomobject]@{
            Entry       = $entry
            CommandLine = $commandLine
        }
    }

    $header = [System.Collections.Generic.List[string]]::new()
    $header.Add('#requires -Version 5.1')
    $header.Add('')
    $header.Add('<#')
    $header.Add('.SYNOPSIS')
    $header.Add('    Reconstructed PowerShell commands exported from the current session by PSRecall.')
    $header.Add('')
    $header.Add('.NOTES')
    $header.Add("    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
    $header.Add("    PowerShell: $($PSVersionTable.PSVersion)")
    $header.Add("    Edition: $($PSVersionTable.PSEdition)")
    $header.Add("    Selection: $SelectionDescription")
    $header.Add("    History IDs: $($orderedHistory[0].Id)-$($orderedHistory[-1].Id)")
    $header.Add("    Exported entries: $($orderedHistory.Count)")
    $header.Add("    Aliases resolved: $resolvedAliasCount")

    if ($IncludeSensitiveMetadata) {
        $header.Add("    Computer: $env:COMPUTERNAME")
        $header.Add("    User: $([System.Environment]::UserName)")
        $header.Add("    Working directory: $((Get-Location).Path)")
    }

    $header.Add('')
    $header.Add('    Review the generated script before execution. History commands may contain')
    $header.Add('    customer-specific names, paths, identifiers, credentials, or destructive actions.')
    $header.Add('#>')
    $header.Add('')
    $header.Add('Set-StrictMode -Version Latest')
    $header.Add("`$ErrorActionPreference = 'Stop'")
    $header.Add('')

    $body = [System.Collections.Generic.List[string]]::new()
    foreach ($item in $commands) {
        $body.Add("# History ID: $($item.Entry.Id) | Status: $($item.Entry.ExecutionStatus)")
        $body.Add($item.CommandLine.TrimEnd())
        $body.Add('')
    }

    [pscustomobject]@{
        PSTypeName         = 'PSRecall.ScriptConversionResult'
        Content            = (@($header) + @($body)) -join [Environment]::NewLine
        ResolvedAliasCount = $resolvedAliasCount
        ParseErrorCount    = $parseErrorCount
        Warnings           = @($warnings)
    }
}
