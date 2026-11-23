# PSRecall

PSRecall reconstructs reusable PowerShell scripts from the current session history after interactive troubleshooting. It is intentionally not a transcript or background recorder.

## Compatibility

- Windows PowerShell 5.1
- PowerShell 7+
- Native WPF GUI on Windows
- Non-GUI selection and export on Windows, macOS, and Linux
- No runtime dependency on `Out-GridView`

## Installation

```powershell
Import-Module .\PSRecall\PSRecall.psd1 -Force
```

## Selection and pipeline export

```powershell
Get-PSRecall -All
Get-PSRecall -Last 20 -SuccessfulOnly
Get-PSRecall -FromId 42 -ToId 68
Get-PSRecall -All | Export-PSRecall -Path .\RecoveredSession.ps1
```

## WPF selection

```powershell
Get-PSRecall -All -Gui | Export-PSRecall
```

## Alias resolution

```powershell
Get-PSRecall -All | Export-PSRecall -Path .\RecoveredSession.ps1 -ResolveAliases
```

`-ResolveAliases` uses the PowerShell AST and changes only statically identifiable command names. Strings, comments, external programs, and dynamic invocations are preserved.

## Best-effort output reconstruction

Output is not stored by `Get-History`. `Get-PSRecall -IncludeOutput` reads the content still exposed through the current host's `RawUI` terminal buffer and correlates commands and output sequentially.

```powershell
$entries = Get-PSRecall -All -IncludeOutput
$entries | Select-Object Id, CommandLine, Output
```

The WPF selector shows `Output` as an additional column when the property has been populated.

To include captured output as block comments in the generated script, use `-IncludeOutput` on both commands:

```powershell
Get-PSRecall -All -IncludeOutput -Gui |
    Export-PSRecall -Path .\RecoveredSession.ps1 -IncludeOutput -ResolveAliases
```

Output recovery is intentionally best effort. It can be incomplete or unavailable when:

- the host does not implement `RawUI.GetBufferContents()`;
- the terminal emulator keeps scrollback outside the PowerShell host buffer;
- output has scrolled beyond the available buffer or the screen was cleared;
- command text was wrapped, reformatted, or rendered differently;
- identical command text makes correlation ambiguous;
- remoting, VS Code, nested prompts, native full-screen programs, or alternate hosts change buffer behavior.

A failed buffer read emits a warning and returns normal history entries with `Output = $null`. The module never reruns commands to obtain output. The latest occurrence of the active `Get-PSRecall` invocation is used as the upper buffer boundary. Searching backwards from the current cursor prevents older identical recall commands in the scrollback from truncating the output of later commands.

## Exported output format

```powershell
# History ID: 2 | Status: Completed
Get-ChildItem

<#
    Output for Get-ChildItem with history ID 2:
    -------------------------------------------
    Mode   LastWriteTime   Length Name
    ----   -------------   ------ ----
    d----  23/11/2026             Documents
#>
```

Captured output is converted to plain text and `#>` sequences are neutralized before being embedded in a block comment.

## Security

History and terminal output can contain customer names, tenant identifiers, paths, tokens, credentials, error payloads, and other sensitive data. Review and sanitize files before storing, sharing, or sending them to an AI service.

## Tests

```powershell
Invoke-Pester .\Tests\PSRecall.Tests.ps1
```
