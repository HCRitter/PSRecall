# PSRecall

PSRecall reconstructs reusable PowerShell scripts and technical documentation from the current session history.

## Selection

```powershell
Get-PSRecall -All -IncludeOutput -Gui
```

Output reconstruction reads the current host `RawUI` buffer, correlates history chronologically, and uses the active recall invocation only as the final output boundary. Commands are never rerun.

## Export formats

```powershell
Get-PSRecall -All | Export-PSRecall -Path .\RecoveredSession.ps1
Get-PSRecall -All -IncludeOutput | Export-PSRecall -Format Text -Path .\Session.txt -IncludeOutput
Get-PSRecall -All -IncludeOutput | Export-PSRecall -Format Markdown -Path .\Troubleshooting.md -Title 'Customer Troubleshooting' -IncludeOutput
```

Supported formats are PowerShell (`.ps1`), Text (`.txt`), and Markdown (`.md`). `-ResolveAliases` uses the PowerShell AST before rendering. Review output before sharing because terminal history can contain sensitive customer data.
