# GUI-controlled export

The WPF selector can now either return selected recall entries or export them directly.

```powershell
Get-PSRecall -All -IncludeOutput -Gui
```

The dialog provides:

- output format: PowerShell, Text, or Markdown;
- title for Text and Markdown exports;
- include-output control;
- AST-based alias resolution;
- optional sensitive metadata;
- **Use Selection** and **Export** actions.

When **Export** is selected, `Get-PSRecall` calls `Export-PSRecall` with the options selected in the GUI and returns the structured export result. The format-aware save dialog opens after the selection dialog closes.

When **Use Selection** is selected, recall objects are returned with an `ExportOptions` property. If those objects are piped to `Export-PSRecall`, GUI options are used only for parameters that were not explicitly supplied to `Export-PSRecall`.

Explicit export parameters always take precedence:

```powershell
Get-PSRecall -All -IncludeOutput -Gui |
    Export-PSRecall -Format Markdown -Title 'Explicit title'
```
