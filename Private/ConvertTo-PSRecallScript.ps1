function ConvertTo-PSRecallScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][object[]]$Entries,
        [Parameter(Mandatory)][string]$SelectionDescription,
        [switch]$IncludeSensitiveMetadata,
        [switch]$IncludeOutput
    )

    $outputEntryCount = 0
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('#requires -Version 5.1')
    $lines.Add('')
    $lines.Add('<#')
    $lines.Add('.SYNOPSIS')
    $lines.Add('    Reconstructed PowerShell commands exported by PSRecall.')
    $lines.Add('')
    $lines.Add('.NOTES')
    $lines.Add("    Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
    $lines.Add("    PowerShell: $($PSVersionTable.PSVersion)")
    $lines.Add("    Edition: $($PSVersionTable.PSEdition)")
    $lines.Add("    Selection: $SelectionDescription")
    $lines.Add("    History IDs: $($Entries[0].Id)-$($Entries[-1].Id)")
    $lines.Add("    Exported entries: $($Entries.Count)")

    if ($IncludeSensitiveMetadata) {
        $lines.Add("    Computer: $env:COMPUTERNAME")
        $lines.Add("    User: $([Environment]::UserName)")
        $lines.Add("    Working directory: $((Get-Location).Path)")
    }

    $lines.Add('')
    $lines.Add('    Review the generated script before execution and sharing.')
    $lines.Add('#>')
    $lines.Add('')
    $lines.Add('Set-StrictMode -Version Latest')
    $lines.Add("`$ErrorActionPreference = 'Stop'")
    $lines.Add('')

    foreach ($entry in $Entries) {
        $lines.Add("# History ID: $($entry.Id) | Status: $($entry.ExecutionStatus)")
        $lines.Add(([string]$entry.CommandLine).TrimEnd())
        $lines.Add('')

        if ($IncludeOutput -and -not [string]::IsNullOrWhiteSpace([string]$entry.Output)) {
            $outputEntryCount++
            $safeOutput = ([string]$entry.Output).Replace('#>', '# >')
            $lines.Add('<#')
            $lines.Add("    Output for $($entry.CommandLine) with history ID $($entry.Id):")
            $lines.Add('    -------------------------------------------')
            foreach ($outputLine in ($safeOutput -split "`r?`n")) {
                $lines.Add("    $outputLine")
            }
            $lines.Add('#>')
            $lines.Add('')
        }
    }

    [pscustomobject]@{
        Content          = $lines -join [Environment]::NewLine
        OutputEntryCount = $outputEntryCount
    }
}
