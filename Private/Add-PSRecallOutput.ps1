function Add-PSRecallOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object[]]$AllHistory,

        [Parameter(Mandatory)]
        [object[]]$SelectedHistory,

        [Parameter()]
        [string]$CurrentInvocation
    )

    $bufferLines = @(Get-PSRecallBufferLines)
    $allEntries = @($AllHistory | Sort-Object -Property Id)
    $markers = [System.Collections.Generic.List[object]]::new()
    $searchStart = 0

    foreach ($entry in $allEntries) {
        $commandLines = @(
            ([string]$entry.CommandLine -split "`r?`n") |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ }
        )

        if ($commandLines.Count -eq 0) {
            continue
        }

        $firstCommandLine = $commandLines[0]
        $matchIndex = -1

        for ($lineIndex = $searchStart; $lineIndex -lt $bufferLines.Count; $lineIndex++) {
            if ($bufferLines[$lineIndex].IndexOf($firstCommandLine, [StringComparison]::Ordinal) -ge 0) {
                $matchIndex = $lineIndex
                break
            }
        }

        if ($matchIndex -lt 0) {
            continue
        }

        $commandEndIndex = $matchIndex
        $nextSearchIndex = $matchIndex + 1

        for ($commandLineIndex = 1; $commandLineIndex -lt $commandLines.Count; $commandLineIndex++) {
            $continuation = $commandLines[$commandLineIndex]
            for ($lineIndex = $nextSearchIndex; $lineIndex -lt $bufferLines.Count; $lineIndex++) {
                if ($bufferLines[$lineIndex].IndexOf($continuation, [StringComparison]::Ordinal) -ge 0) {
                    $commandEndIndex = $lineIndex
                    $nextSearchIndex = $lineIndex + 1
                    break
                }
            }
        }

        $markers.Add([pscustomobject]@{
            Id           = [long]$entry.Id
            CommandStart = $matchIndex
            OutputStart  = $commandEndIndex + 1
        })
        $searchStart = $commandEndIndex + 1
    }

    # The active Get-PSRecall command is already present in the terminal buffer, but it is not yet
    # part of Get-History. Locate the LAST occurrence of that invocation. Searching backwards avoids
    # matching an older identical Get-PSRecall command that is already present in the scrollback.
    $invocationBoundary = $bufferLines.Count
    $invocationLines = @(
        ($CurrentInvocation -split "`r?`n") |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )

    if ($invocationLines.Count -gt 0) {
        $firstInvocationLine = $invocationLines[0]
        for ($lineIndex = $bufferLines.Count - 1; $lineIndex -ge 0; $lineIndex--) {
            if ($bufferLines[$lineIndex].IndexOf($firstInvocationLine, [StringComparison]::Ordinal) -ge 0) {
                $invocationBoundary = $lineIndex
                break
            }
        }
    }

    $outputById = @{}
    for ($markerIndex = 0; $markerIndex -lt $markers.Count; $markerIndex++) {
        $marker = $markers[$markerIndex]
        $outputEnd = if ($markerIndex -lt ($markers.Count - 1)) {
            $markers[$markerIndex + 1].CommandStart - 1
        }
        else {
            $invocationBoundary - 1
        }

        if ($outputEnd -lt $marker.OutputStart) {
            $outputById[$marker.Id] = $null
            continue
        }

        $capturedLines = @($bufferLines[$marker.OutputStart..$outputEnd])
        while ($capturedLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($capturedLines[0])) {
            $capturedLines = @($capturedLines | Select-Object -Skip 1)
        }
        while ($capturedLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($capturedLines[-1])) {
            $capturedLines = @($capturedLines | Select-Object -First ($capturedLines.Count - 1))
        }

        $outputById[$marker.Id] = if ($capturedLines.Count -gt 0) {
            $capturedLines -join [Environment]::NewLine
        }
        else {
            $null
        }
    }

    foreach ($entry in $SelectedHistory) {
        $convertedEntry = $entry | ConvertTo-PSRecallEntry
        if ($outputById.ContainsKey([long]$entry.Id)) {
            $convertedEntry.Output = $outputById[[long]$entry.Id]
        }
        $convertedEntry
    }
}
