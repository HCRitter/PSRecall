# PSRecall

PSRecall reconstructs a reusable PowerShell script from the history of the current PowerShell process after an interactive troubleshooting session has already happened.

It is intentionally not a transcript or background recorder. Think of it as the post-session recovery step: select the useful commands, export them, review the result, and continue with a clean script.

## Compatibility

- Windows PowerShell 5.1
- PowerShell 7+
- Native WPF GUI on Windows
- Non-GUI selection and export on Windows, macOS, and Linux
- No external runtime dependencies
- Pester 5 or newer is recommended for running the included tests

## Installation

Copy the `PSRecall` directory into a directory listed in `$env:PSModulePath`, or import the manifest directly:

```powershell
Import-Module .\PSRecall\PSRecall.psd1 -Force
```

## Visual selection and export

The selector is a native WPF `DataGrid` and does not depend on `Out-GridView`. It runs in a dedicated STA runspace on Windows.

```powershell
Get-PSRecall -All -Gui | Export-PSRecall
```

1. Select rows with Ctrl or Shift.
2. Choose **Use Selection**.
3. Select the destination `.ps1` file in the Save File dialog.

You can restrict the rows shown before opening the GUI:

```powershell
Get-PSRecall -Last 50 -SuccessfulOnly -Gui | Export-PSRecall
Get-PSRecall -FromId 42 -ToId 68 -Gui | Export-PSRecall
```

## Pipeline export

```powershell
Get-PSRecall -All | Export-PSRecall -Path .\RecoveredSession.ps1
Get-PSRecall -Last 20 -SuccessfulOnly | Export-PSRecall -Path .\WorkingCommands.ps1
```

When `-Path` is omitted on Windows, `Export-PSRecall` opens a Save File dialog:

```powershell
Get-PSRecall -All | Export-PSRecall
```

On macOS and Linux, provide `-Path` because the native WPF GUI is Windows-only.

## Direct export

The direct export workflow remains available:

```powershell
Export-PSRecall -Last 20 -Path .\RecoveredSession.ps1
Export-PSRecall -All -Path .\RecoveredSession.ps1
Export-PSRecall -FromId 42 -ToId 68 -Path .\RecoveredSession.ps1
```

## Alias resolution

Interactive PowerShell sessions often use aliases for speed, while reusable scripts benefit from explicit command names. `Export-PSRecall -ResolveAliases` uses the PowerShell Abstract Syntax Tree (AST) to inspect command positions and resolve aliases without performing blind text replacement.

```powershell
Get-PSRecall -All -Gui | Export-PSRecall -ResolveAliases
Get-PSRecall -All | Export-PSRecall -Path .\RecoveredSession.ps1 -ResolveAliases
```

For example, an interactive command such as:

```powershell
gci C:\Temp -File | ? Length -gt 1MB | % FullName
```

is exported using the corresponding command names:

```powershell
Get-ChildItem C:\Temp -File | Where-Object Length -gt 1MB | ForEach-Object FullName
```

Alias resolution deliberately changes only statically identifiable command names. It does not rewrite strings, comments, property names, parameter names, external applications, or dynamic invocations. Aliases are resolved to cmdlets, functions, or filters available in the current session.

If an individual history entry cannot be parsed safely, PSRecall keeps the original command, emits a warning containing the history ID, and continues the export. The export result reports `ResolvedAliasCount` and `ParseErrorCount`.

`-ResolveAliases` is an export transformation. `Get-PSRecall` always returns the original history content.

## Selection semantics

`-Last 20` means the last 20 history entries, not 20 visual console lines. A multiline loop, function, hashtable, or splatted command remains one history entry because PSRecall uses `HistoryInfo.CommandLine` from `Get-History`.

`-FromId` and `-ToId` are inclusive.

## Meaning of SuccessfulOnly

`-SuccessfulOnly` keeps entries whose `ExecutionStatus` is `Completed`. This is the status exposed by PowerShell history. It does not provide a perfect success guarantee:

- a native executable can return a non-zero exit code while the history entry is still completed;
- a cmdlet can emit a non-terminating error;
- a command can complete but still produce an undesired business result.

The generated script must therefore be reviewed before execution.

## Export metadata

The generated header contains:

- generation time;
- PowerShell version and edition;
- the history selection description;
- the exported history ID range;
- the number of exported entries;
- the number of aliases resolved when alias resolution is enabled.

Computer name, user name, and working directory are added only with `-IncludeSensitiveMetadata`.

The structured export result contains the output path, entry count, first and last history ID, resolved alias count, parse error count, and export timestamp.

## Security considerations

PowerShell history may contain:

- access tokens or credentials typed as command arguments;
- customer names, tenant IDs, device IDs, paths, or server names;
- destructive or environment-specific commands;
- commands that depend on variables or state not represented in history.

PSRecall does not attempt to redact or reinterpret arbitrary command content because doing so could silently change behavior. `-ResolveAliases` is intentionally limited to AST-identified command names. Review and sanitize the generated `.ps1` file before storing, sharing, or running it.

## Tests

```powershell
Invoke-Pester .\Tests\PSRecall.Tests.ps1
```

Tests cover the public commands, ID-range validation, pipeline export, file overwrite behavior, AST alias resolution, protection of strings and comments, and parse-failure fallback. The interactive WPF GUI is intentionally excluded from automated Linux test execution.

## Current limitations

- Only the current process history returned by `Get-History` is available.
- Console output is not exported. PSRecall reconstructs invoked commands, not output stream data.
- Commands can depend on variables, functions, modules, credentials, current location, or other session state.
- `ExecutionStatus = Completed` is not equivalent to complete semantic success.
- Alias resolution reflects aliases and commands available in the exporting session.
- The WPF GUI is Windows-only.
