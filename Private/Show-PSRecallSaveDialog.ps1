function Show-PSRecallSaveDialog {
    [CmdletBinding()]
    param ([string]$SuggestedFileName = 'RecoveredSession.ps1')

    $dialogScript = {
        Add-Type -AssemblyName PresentationFramework
        $dialog = [Microsoft.Win32.SaveFileDialog]::new()
        $dialog.Title = 'Export PSRecall script'; $dialog.Filter = 'PowerShell script (*.ps1)|*.ps1'
        $dialog.DefaultExt = '.ps1'; $dialog.AddExtension = $true; $dialog.OverwritePrompt = $true
        $dialog.FileName = $GuiSuggestedFileName
        if ($dialog.ShowDialog()) { $dialog.FileName }
    }
    @(Invoke-PSRecallStaRunspace -ScriptBlock $dialogScript -Variables @{ GuiSuggestedFileName = $SuggestedFileName }) |
        Select-Object -First 1
}
