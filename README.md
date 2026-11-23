# PSRecall

**Export what worked.**

PSRecall is a PowerShell module for reconstructing useful scripts and troubleshooting documentation from the current interactive session after the work is already done.

It is deliberately not a transcript recorder. PSRecall uses `Get-History` to recover the commands from the current session, lets you select the relevant entries, can reconstruct terminal output on a best-effort basis, and exports the result as a PowerShell script, plain text report, or Markdown documentation.

This is useful when you have been troubleshooting interactively on a customer system and want to turn the successful parts of that session into something reusable afterwards.

## Features

- Select the last _n_ history entries, all entries, or an inclusive history ID range.
- Filter for completed commands with `-SuccessfulOnly`.
- Keep multiline PowerShell commands together as a single history entry.
- Select commands visually with the Windows WPF interface through `-Gui`.
- Pass recall entries through the PowerShell pipeline.
- Resolve PowerShell aliases during export with AST-based `-ResolveAliases`.
- Reconstruct visible terminal output with `-IncludeOutput` on a best-effort basis.
- Export to PowerShell (`.ps1`), plain text (`.txt`), or Markdown (`.md`).
- Add a custom title to documentation exports.
- Preserve the original history unless an export transformation is explicitly requested.

## Compatibility

| Capability | Windows PowerShell 5.1 | PowerShell 7 on Windows | PowerShell 7 on Linux/macOS |
|---|---:|---:|---:|
| History selection | Yes | Yes | Yes |
| Pipeline export | Yes | Yes | Yes |
| PowerShell/Text/Markdown export | Yes | Yes | Yes |
| Alias resolution | Yes | Yes | Yes |
| WPF GUI | Yes | Yes | No |
| Output reconstruction | Host dependent | Host dependent | Host dependent |

The WPF selector is Windows-only. Output reconstruction additionally depends on the current PowerShell host exposing a readable `RawUI` buffer.

## Installation

Import the module directly from its manifest:

```powershell
$importParameters = @{
    Name        = '.\PSRecall\PSRecall.psd1'
    Force       = $true
    ErrorAction = 'Stop'
}

Import-Module @importParameters
```

## Basic usage

### Show the last 20 commands

```powershell
Get-PSRecall -Last 20
```

### Show all available history entries

```powershell
Get-PSRecall -All
```

### Select a history ID range

`-FromId` and `-ToId` are inclusive.

```powershell
Get-PSRecall -FromId 42 -ToId 68
```

### Return only completed commands

```powershell
Get-PSRecall -All -SuccessfulOnly
```

`-SuccessfulOnly` evaluates the `ExecutionStatus` reported by PowerShell history. A status of `Completed` does not guarantee that a native executable returned exit code `0`, that no non-terminating error occurred, or that the command produced the desired business result.

## Visual selection

On Windows, `-Gui` opens a WPF selector for the recall entries.

```powershell
Get-PSRecall -All -Gui
```

Multiple rows can be selected before returning the selected entries to the pipeline.

A complete visual selection and export workflow looks like this:

```powershell
Get-PSRecall -All -Gui |
    Export-PSRecall -Path .\RecoveredSession.ps1
```

## Pipeline support

PSRecall entries are structured PowerShell objects and can be inspected, filtered, or passed directly to `Export-PSRecall`.

```powershell
Get-PSRecall -All |
    Where-Object ExecutionStatus -eq 'Completed' |
    Export-PSRecall -Path .\RecoveredSession.ps1
```

This keeps selection and presentation separate: `Get-PSRecall` retrieves recall data, while `Export-PSRecall` decides how that data is rendered.

## Alias resolution

Interactive PowerShell sessions often use aliases for speed. Reusable scripts are generally easier to read and maintain when full command names are used.

Use `-ResolveAliases` during export:

```powershell
Get-PSRecall -All |
    Export-PSRecall -Path .\RecoveredSession.ps1 -ResolveAliases
```

For example, a recorded command such as:

```powershell
gci C:\Temp -File | ? Length -gt 1MB | % FullName
```

can be exported as:

```powershell
Get-ChildItem C:\Temp -File | Where-Object Length -gt 1MB | ForEach-Object FullName
```

Alias resolution uses the PowerShell Abstract Syntax Tree (AST). It operates on command positions rather than performing global text replacement, so alias-like text in strings and comments is not intentionally rewritten.

`-ResolveAliases` is an export transformation. `Get-PSRecall` continues to represent the original session history.

## Output reconstruction

`Get-History` stores commands, not the output those commands produced. PSRecall can optionally attempt to reconstruct output that is still available in the current terminal buffer.

```powershell
Get-PSRecall -All -IncludeOutput
```

When output is available, each recalled entry receives an `Output` property in addition to information such as `Id`, `ExecutionStatus`, `Duration`, and `CommandLine`.

You can also inspect command and output together in the WPF interface:

```powershell
Get-PSRecall -All -IncludeOutput -Gui
```

### How output reconstruction works

PSRecall reads the current host's `RawUI` buffer and correlates visible commands chronologically with the entries returned by `Get-History`.

After a command is matched, the next search starts after that command. This is important when the same command was executed more than once. The currently running `Get-PSRecall` invocation is used only as the upper boundary of the final recalled command so that the recall command itself does not become part of the preceding output.

PSRecall never reruns a command to obtain its output.

### Output reconstruction limitations

Output reconstruction is intentionally best effort. Output can be incomplete or unavailable when:

- the current host does not implement `RawUI.GetBufferContents()`;
- terminal scrollback is maintained outside the PowerShell host buffer;
- the screen was cleared;
- older output has already left the available buffer;
- command lines were wrapped or rendered differently from the history representation;
- remoting, nested prompts, full-screen applications, or alternate terminal hosts affect the buffer;
- terminal rendering contains glyphs or characters that cannot be reproduced cleanly.

Do not treat the reconstructed output as a guaranteed transcript.

## Export formats

PSRecall supports three presentation formats.

| Format | Extension | Intended use |
|---|---|---|
| `PowerShell` | `.ps1` | Reusable PowerShell script |
| `Text` | `.txt` | Portable plain-text troubleshooting report |
| `Markdown` | `.md` | Structured technical documentation, GitHub content, or AI context |

`PowerShell` is the default format.

### PowerShell

```powershell
Get-PSRecall -All |
    Export-PSRecall -Path .\RecoveredSession.ps1
```

With aliases resolved and captured output embedded as comments:

```powershell
$getParameters = @{
    All           = $true
    IncludeOutput = $true
}

$exportParameters = @{
    Path           = '.\RecoveredSession.ps1'
    ResolveAliases = $true
    IncludeOutput  = $true
}

Get-PSRecall @getParameters |
    Export-PSRecall @exportParameters
```

A PowerShell export with output can contain sections such as:

```powershell
# History ID: 2 | Status: Completed
Get-ChildItem

<#
    Output for Get-ChildItem with history ID 2:
    -------------------------------------------
    Directory: C:\Users\example

    Mode   LastWriteTime   Length Name
    ----   -------------   ------ ----
    d----  2026-11-23             Documents
#>
```

### Plain text

```powershell
Get-PSRecall -All -IncludeOutput |
    Export-PSRecall -Format Text -Path .\Session.txt -IncludeOutput
```

The text renderer creates a simple report without PowerShell-specific comment syntax or Markdown formatting.

### Markdown

Markdown export is intended for troubleshooting documentation, GitHub issues, knowledge articles, handovers, and providing structured context to an AI assistant.

```powershell
$exportParameters = @{
    Format         = 'Markdown'
    Path           = '.\Troubleshooting.md'
    Title          = 'Customer Troubleshooting'
    IncludeOutput  = $true
    ResolveAliases = $true
}

Get-PSRecall -All -IncludeOutput |
    Export-PSRecall @exportParameters
```

The Markdown renderer uses semantic Markdown elements rather than simply changing the file extension. Session information is represented separately from individual history entries, commands use PowerShell code fences, and captured output uses text code fences.

A generated document follows this general structure:

````markdown
# Customer Troubleshooting

> Session reconstructed from PowerShell history by PSRecall.

## Session information

| Property | Value |
|---|---|
| PowerShell | 7.x Core |
| Commands | 3 |

---

## History ID 2

**Status:** Completed

### Command

```powershell
Get-ChildItem
```

### Output

```text
Directory: C:\Users\example
```
````

## File extensions

When a path is supplied without an extension, PSRecall adds the extension appropriate for the selected format.

```powershell
Get-PSRecall -All |
    Export-PSRecall -Format Markdown -Path .\Troubleshooting
```

The resulting file is `Troubleshooting.md`.

A path whose extension conflicts with the selected format is rejected instead of silently writing one format under another extension.

## Working with output independently

Capturing output and exporting output are separate decisions.

You can use output to make a selection in the GUI but still create a clean script without embedding the output:

```powershell
Get-PSRecall -All -IncludeOutput -Gui |
    Export-PSRecall -Path .\RecoveredSession.ps1
```

Or include that output in the export:

```powershell
Get-PSRecall -All -IncludeOutput -Gui |
    Export-PSRecall -Path .\DocumentedSession.ps1 -IncludeOutput
```

## Security considerations

PowerShell history and terminal output can contain sensitive information, including:

- customer names and system names;
- tenant, user, device, or application identifiers;
- file system and network paths;
- access tokens, credentials, or command arguments containing secrets;
- REST error payloads and diagnostic information;
- destructive or environment-specific commands.

Review and sanitize recalled content before storing it permanently, committing it to source control, sharing it with another person, or submitting it to an AI service.

`-IncludeOutput` can substantially increase the amount of customer-specific information contained in an export.

## Current limitations

- PSRecall operates on the history of the current PowerShell process.
- Output reconstruction is host and buffer dependent and is not a replacement for transcription or logging.
- History entries can depend on variables, functions, modules, credentials, location, and other state that is not represented by the command text alone.
- `ExecutionStatus = Completed` is not equivalent to semantic success.
- Alias resolution reflects aliases and commands available in the exporting session.
- The WPF selector is available on Windows only.

## Tests

Run the included Pester tests with:

```powershell
Invoke-Pester .\Tests\PSRecall.Tests.ps1
```

## Project philosophy

PSRecall is designed for the moment after an interactive troubleshooting session: recover what happened, keep what was useful, and turn it into something reusable.

**EXPORT WHAT WORKED.**
