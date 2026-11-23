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
    $historyEntries = @($AllHistory | Sort-Object -Property Id)
    $markers = [System.Collections.Generic.List[object]]::new()
    $matchedHistoryIds = [System.Collections.Generic.HashSet[long]]::new()
    $searchStart = 0

    foreach ($entry in $historyEntries) {
        $commandLines = @(
            ([string]$entry.CommandLine -split "`r?`n") |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ }
        )

        if ($commandLines.Count -eq 0) {
            continue
        }

        $commandStart = -1
        for ($lineIndex = $searchStart; $lineIndex -lt $bufferLines.Count; $lineIndex++) {
            if ($bufferLines[$lineIndex].IndexOf($commandLines[0], [StringComparison]::Ordinal) -ge 0) {
                $commandStart = $lineIndex
                break
            }
        }

        if ($commandStart -lt 0) {
            continue
        }

        $commandEnd = $commandStart
        $continuationSearchStart = $commandStart + 1
        $completeCommandFound = $true

        for ($commandLineIndex = 1; $commandLineIndex -lt $commandLines.Count; $commandLineIndex++) {
            $continuationMatch = -1
            for ($lineIndex = $continuationSearchStart; $lineIndex -lt $bufferLines.Count; $lineIndex++) {
                if ($bufferLines[$lineIndex].IndexOf($commandLines[$commandLineIndex], [StringComparison]::Ordinal) -ge 0) {
                    $continuationMatch = $lineIndex
                    break
                }
            }

            if ($continuationMatch -lt 0) {
                $completeCommandFound = $false
                break
            }

            $commandEnd = $continuationMatch
            $continuationSearchStart = $continuationMatch + 1
        }

        if (-not $completeCommandFound) {
            continue
        }

        $markers.Add([pscustomobject]@{
            Id           = [long]$entry.Id
            CommandStart = $commandStart
            CommandEnd   = $commandEnd
            OutputStart  = $commandEnd + 1
        })
        [void]$matchedHistoryIds.Add([long]$entry.Id)
        $searchStart = $commandEnd + 1
    }

    $invocationBoundary = $bufferLines.Count
    $invocationLines = @(
        ($CurrentInvocation -split "`r?`n") |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
    )

    if ($invocationLines.Count -gt 0) {
        for ($lineIndex = $bufferLines.Count - 1; $lineIndex -ge 0; $lineIndex--) {
            if ($bufferLines[$lineIndex].IndexOf($invocationLines[0], [StringComparison]::Ordinal) -ge 0) {
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

    # Windows Terminal can expose less scrollback through RawUI than the terminal itself displays.
    # A large command such as Get-ChildItem can therefore leave its output in the buffer while its
    # prompt line has already fallen outside the readable RawUI range. If exactly one unmatched
    # history entry immediately precedes the first matched command, attribute the leading buffer
    # content to that entry. Multiple missing commands remain ambiguous and are deliberately left
    # unresolved rather than guessing which command produced which output.
    if ($markers.Count -gt 0 -and $markers[0].CommandStart -gt 0) {
        $firstMatchedId = [long]$markers[0].Id
        $precedingUnmatchedEntries = @(
            $historyEntries |
                Where-Object {
                    $_.Id -lt $firstMatchedId -and
                    -not $matchedHistoryIds.Contains([long]$_.Id)
                }
        )

        if ($precedingUnmatchedEntries.Count -eq 1) {
            $leadingOutputEnd = $markers[0].CommandStart - 1
            $leadingLines = @($bufferLines[0..$leadingOutputEnd])

            while ($leadingLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($leadingLines[0])) {
                $leadingLines = @($leadingLines | Select-Object -Skip 1)
            }
            while ($leadingLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($leadingLines[-1])) {
                $leadingLines = @($leadingLines | Select-Object -First ($leadingLines.Count - 1))
            }

            if ($leadingLines.Count -gt 0) {
                $outputById[[long]$precedingUnmatchedEntries[0].Id] = $leadingLines -join [Environment]::NewLine
            }
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
