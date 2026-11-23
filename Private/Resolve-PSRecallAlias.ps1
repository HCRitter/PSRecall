function Resolve-PSRecallAlias {
    [CmdletBinding()]
    param ([Parameter(Mandatory)][string]$CommandLine)

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $CommandLine,
        [ref]$tokens,
        [ref]$parseErrors
    )

    if ($parseErrors.Count -gt 0) {
        return [pscustomobject]@{
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

        $target = Get-Command -Name $alias.ResolvedCommandName -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandType -in @('Cmdlet', 'Function', 'Filter') } |
            Select-Object -First 1
        if (-not $target) {
            $warnings.Add("Alias '$commandName' could not be resolved safely.")
            continue
        }

        $extent = $commandAst.CommandElements[0].Extent
        $replacements.Add([pscustomobject]@{
            Start  = $extent.StartOffset
            Length = $extent.EndOffset - $extent.StartOffset
            Value  = $target.Name
        })
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
        CommandLine        = $resolvedCommandLine
        ResolvedAliasCount = $replacements.Count
        ParseErrorCount    = 0
        Warnings           = @($warnings)
    }
}
