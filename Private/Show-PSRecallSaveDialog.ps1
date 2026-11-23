function Show-PSRecallSaveDialog {
    [CmdletBinding()]param([string]$SuggestedFileName='RecoveredSession.ps1')
    $script={Add-Type -AssemblyName PresentationFramework;$dialog=[Microsoft.Win32.SaveFileDialog]::new();$dialog.Filter='PowerShell script (*.ps1)|*.ps1';$dialog.FileName=$GuiSuggestedFileName;$dialog.AddExtension=$true;if($dialog.ShowDialog()){$dialog.FileName}}
    @(Invoke-PSRecallStaRunspace -ScriptBlock $script -Variables @{GuiSuggestedFileName=$SuggestedFileName}) | Select-Object -First 1
}
