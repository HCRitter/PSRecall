function ConvertTo-PSRecallScript {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [object[]]$History,

        [Parameter(Mandatory)]
        [string]$SelectionDescription,

        [Parameter()]
        [switch]$IncludeSensitiveMetadata
    )

    $orderedHistory = @($History | Sort-Object -Property Id)
    $firstId = $orderedHistory[0].Id
    $lastId = $orderedHistory[-1].Id
    $generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss K'

    $header = [System.Collections.Generic.List[string]]::new()
    $header.Add('#requires -Version 5.1')
    $header.Add('')
    $header.Add('<#')
    $header.Add('.SYNOPSIS')
    $header.Add('    Reconstructed PowerShell commands exported from the current session by PSRecall.')
    $header.Add('')
    $header.Add('.NOTES')
    $header.Add("    Generated: $generatedAt")
    $header.Add("    PowerShell: $($PSVersionTable.PSVersion)")
    $header.Add("    Edition: $($PSVersionTable.PSEdition)")
    $header.Add("    Selection: $SelectionDescription")
    $header.Add("    History IDs: $firstId-$lastId")
    $header.Add("    Exported entries: $($orderedHistory.Count)")

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
    foreach ($entry in $orderedHistory) {
        $body.Add("# History ID: $($entry.Id) | Status: $($entry.ExecutionStatus)")
        $body.Add(([string]$entry.CommandLine).TrimEnd())
        $body.Add('')
    }

    return (@($header) + @($body)) -join [Environment]::NewLine
}
