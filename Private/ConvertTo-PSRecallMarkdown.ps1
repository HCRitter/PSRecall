function ConvertTo-PSRecallMarkdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][object[]]$Entries,
        [Parameter(Mandatory)][string]$SelectionDescription,
        [switch]$IncludeSensitiveMetadata,
        [switch]$IncludeOutput,
        [string]$Title = 'PSRecall Session Export'
    )

    $outputEntryCount = 0
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add("# $Title")
    $lines.Add('')
    $lines.Add('> Session reconstructed from PowerShell history by PSRecall.')
    $lines.Add('')
    $lines.Add('## Session information')
    $lines.Add('')
    $lines.Add('| Property | Value |')
    $lines.Add('|---|---|')
    $lines.Add("| Exported | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K') |")
    $lines.Add("| PowerShell | $($PSVersionTable.PSVersion) $($PSVersionTable.PSEdition) |")
    $lines.Add("| Commands | $($Entries.Count) |")
    $lines.Add('')

    foreach ($entry in $Entries) {
        $lines.Add('---')
        $lines.Add('')
        $lines.Add("## History ID $($entry.Id)")
        $lines.Add('')
        $lines.Add("**Status:** $($entry.ExecutionStatus)  ")
        $lines.Add('')
        $lines.Add('### Command')
        $lines.Add('')
        $lines.Add('```powershell')
        $lines.Add($entry.CommandLine.Replace('```', '` ` `'))
        $lines.Add('```')

        if ($IncludeOutput -and -not [string]::IsNullOrWhiteSpace([string]$entry.Output)) {
            $outputEntryCount++
            $lines.Add('')
            $lines.Add('### Output')
            $lines.Add('')
            $lines.Add('```text')
            $lines.Add(([string]$entry.Output).Replace('```', '` ` `'))
            $lines.Add('```')
        }
        $lines.Add('')
    }

    [pscustomobject]@{
        Content          = $lines -join [Environment]::NewLine
        OutputEntryCount = $outputEntryCount
    }
}
