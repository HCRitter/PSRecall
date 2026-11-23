# PSRecall

PSRecall reconstructs a reusable PowerShell script from the history of the current PowerShell process after an interactive troubleshooting session has already happened.

It is intentionally not a transcript or background recorder. It is the post-session recovery step: select the useful commands, export them, review the result, and continue with a clean script.

## Compatibility

- Windows PowerShell 5.1
- PowerShell 7+
- Native GUI on Windows through WPF
- Non-GUI selection and export on Windows, macOS, and Linux
- No external runtime dependencies

## Import

```powershell
Import-Module .\PSRecall\PSRecall.psd1 -Force
```

## Visual selection and export

The selector is a native WPF `DataGrid` and does not depend on `Out-GridView`. It runs in a dedicated STA runspace for Windows PowerShell 5.1 and PowerShell 7 on Windows.

```powershell
Get-PSRecall -Gui | Export-PSRecall
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

On macOS and Linux, provide `-Path` because the native GUI is Windows-only.

## Direct export

The original direct export remains available:

```powershell
Export-PSRecall -Last 20 -Path .\RecoveredSession.ps1
Export-PSRecall -All -Path .\RecoveredSession.ps1
Export-PSRecall -FromId 42 -ToId 68 -Path .\RecoveredSession.ps1
```

## Selection semantics

`-Last 20` means the last 20 history entries, not 20 visual console lines. A multiline loop, function, hashtable, or splatted command remains one history entry because PSRecall uses `HistoryInfo.CommandLine` from `Get-History`.

`-FromId` and `-ToId` are inclusive.

## Meaning of SuccessfulOnly

`-SuccessfulOnly` keeps entries whose `ExecutionStatus` is `Completed`. It does not guarantee that native applications returned exit code zero, that no non-terminating errors occurred, or that the business result was correct.

## Security considerations

PowerShell history can contain access tokens, credentials, customer names, tenant IDs, device IDs, paths, server names, and destructive commands. PSRecall deliberately does not rewrite or redact commands because that could silently change behavior. Review and sanitize every generated script before storing, sharing, or running it.

## Tests

```powershell
Invoke-Pester .\Tests\PSRecall.Tests.ps1
```

The interactive WPF GUI itself is intentionally excluded from automated tests. Pipeline conversion and export behavior are covered without requiring an interactive desktop.
