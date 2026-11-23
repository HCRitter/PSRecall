function Resolve-PSRecallAlias {
    [CmdletBinding()]
    [OutputType('PSRecall.AliasResolutionResult')]
    param (
        [Parameter(Mandatory)]
        [string]$CommandLine
    )

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $CommandLine,
        [ref]$tokens,
        [ref]$parseErrors
    )

    if ($parseErrors.Count -gt 0) {
        return [pscustomobject]@{
            PSTypeName         = 'PSRecall.AliasResolutionResult'
            CommandLine        = $CommandLine
            ResolvedAliasCount = 0
            ParseErrorCount    = $parseErrors.Count
            Warnings           = @($parseErrors.Message)
        }
    }

    $replacements = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $commandAsts = $ast.FindAll(
        { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
        $true
    )

    foreach ($commandAst in $commandAsts) {
        $commandName = $commandAst.GetCommandName()
        if ([string]::IsNullOrWhiteSpace($commandName)) {
            continue
        }

        $alias = Get-Command -Name $commandName -CommandType Alias -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if (-not $alias) {
            continue
        }

        $visitedAliases = [System.Collections.Generic.HashSet[string]]::new(
            [System.StringComparer]::OrdinalIgnoreCase
        )
        $resolvedName = $commandName
        $targetCommand = $null

        for ($depth = 0; $depth -lt 10; $depth++) {
            if (-not $visitedAliases.Add($resolvedName)) {
                $warnings.Add("Alias cycle detected for '$commandName'.")
                break
            }

            $currentAlias = Get-Command -Name $resolvedName -CommandType Alias -ErrorAction SilentlyContinue |
                Select-Object -First 1
            if (-not $currentAlias) {
                break
            }

            $resolvedName = $currentAlias.ResolvedCommandName
            if ([string]::IsNullOrWhiteSpace($resolvedName)) {
                break
            }
        }

        if (-not [string]::IsNullOrWhiteSpace($resolvedName)) {
            $targetCommand = Get-Command -Name $resolvedName -ErrorAction SilentlyContinue |
                Where-Object CommandType -In Cmdlet, Function, Filter |
                Select-Object -First 1
        }

        if (-not $targetCommand) {
            $warnings.Add("Alias '$commandName' could not be resolved to a cmdlet, function, or filter.")
            continue
        }

        $commandExtent = $commandAst.CommandElements[0].Extent
        $replacements.Add(
            [pscustomobject]@{
                Start  = $commandExtent.StartOffset
                Length = $commandExtent.EndOffset - $commandExtent.StartOffset
                Value  = $targetCommand.Name
            }
        )
    }

    $resolvedCommandLine = $CommandLine
    foreach ($replacement in @($replacements | Sort-Object -Property Start -Descending)) {
        $resolvedCommandLine = $resolvedCommandLine.Remove(
            $replacement.Start,
            $replacement.Length
        ).Insert(
            $replacement.Start,
            $replacement.Value
        )
    }

    [pscustomobject]@{
        PSTypeName         = 'PSRecall.AliasResolutionResult'
        CommandLine        = $resolvedCommandLine
        ResolvedAliasCount = $replacements.Count
        ParseErrorCount    = 0
        Warnings           = @($warnings)
    }
}
