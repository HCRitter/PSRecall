function ConvertTo-PSRecallText {
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
    $lines.Add($Title)
    $lines.Add('=' * $Title.Length)
    $lines.Add('')
    $lines.Add("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')")
    $lines.Add("PowerShell: $($PSVersionTable.PSVersion) $($PSVersionTable.PSEdition)")
    $lines.Add("Selection: $SelectionDescription")
    $lines.Add("Commands: $($Entries.Count)")
    $lines.Add('')

    foreach ($entry in $Entries) {
        $lines.Add('-' * 79)
        $lines.Add("History ID: $($entry.Id)")
        $lines.Add("Status: $($entry.ExecutionStatus)")
        $lines.Add('')
        $lines.Add('Command:')
        $lines.Add($entry.CommandLine)
        if ($IncludeOutput -and -not [string]::IsNullOrWhiteSpace([string]$entry.Output)) {
            $outputEntryCount++
            $lines.Add('')
            $lines.Add('Output:')
            $lines.Add([string]$entry.Output)
        }
        $lines.Add('')
    }

    [pscustomobject]@{
        Content          = $lines -join [Environment]::NewLine
        OutputEntryCount = $outputEntryCount
    }
}
