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

    foreach ($entry in $SelectedHistory) {
        $convertedEntry = $entry | ConvertTo-PSRecallEntry
        if ($outputById.ContainsKey([long]$entry.Id)) {
            $convertedEntry.Output = $outputById[[long]$entry.Id]
        }
        $convertedEntry
    }
}
