function Resolve-PSRecallAlias {
    [CmdletBinding()]
    param ([Parameter(Mandatory)][string]$CommandLine)

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($CommandLine, [ref]$tokens, [ref]$parseErrors)

    if ($parseErrors.Count -gt 0) {
        return [pscustomobject]@{
            CommandLine = $CommandLine; ResolvedAliasCount = 0
            ParseErrorCount = $parseErrors.Count; Warnings = @($parseErrors.Message)
        }
    }

    $replacements = [System.Collections.Generic.List[object]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $commandAsts = $ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.CommandAst] }, $true)

    foreach ($commandAst in $commandAsts) {
        $commandName = $commandAst.GetCommandName()
        if ([string]::IsNullOrWhiteSpace($commandName)) { continue }
        $alias = Get-Command -Name $commandName -CommandType Alias -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $alias) { continue }

        $visited = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        $resolvedName = $commandName
        for ($depth = 0; $depth -lt 10; $depth++) {
            if (-not $visited.Add($resolvedName)) { $warnings.Add("Alias cycle detected for '$commandName'."); break }
            $currentAlias = Get-Command -Name $resolvedName -CommandType Alias -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $currentAlias) { break }
            $resolvedName = $currentAlias.ResolvedCommandName
            if ([string]::IsNullOrWhiteSpace($resolvedName)) { break }
        }

        $target = Get-Command -Name $resolvedName -ErrorAction SilentlyContinue |
            Where-Object CommandType -In Cmdlet, Function, Filter |
            Select-Object -First 1
        if (-not $target) { $warnings.Add("Alias '$commandName' could not be resolved safely."); continue }

        $extent = $commandAst.CommandElements[0].Extent
        $replacements.Add([pscustomobject]@{
            Start = $extent.StartOffset; Length = $extent.EndOffset - $extent.StartOffset; Value = $target.Name
        })
    }

    $resolved = $CommandLine
    foreach ($replacement in @($replacements | Sort-Object Start -Descending)) {
        $resolved = $resolved.Remove($replacement.Start, $replacement.Length).Insert($replacement.Start, $replacement.Value)
    }

    [pscustomobject]@{
        CommandLine = $resolved; ResolvedAliasCount = $replacements.Count
        ParseErrorCount = 0; Warnings = @($warnings)
    }
}
