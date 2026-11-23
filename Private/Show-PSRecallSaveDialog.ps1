function Show-PSRecallSaveDialog {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter()]
        [string]$SuggestedFileName = 'RecoveredSession.ps1'
    )

    $dialogScript = {
        Add-Type -AssemblyName PresentationFramework

        $dialog = [Microsoft.Win32.SaveFileDialog]::new()
        $dialog.Title = 'Export PSRecall script'
        $dialog.Filter = 'PowerShell script (*.ps1)|*.ps1'
        $dialog.DefaultExt = '.ps1'
        $dialog.AddExtension = $true
        $dialog.OverwritePrompt = $true
        $dialog.FileName = $GuiSuggestedFileName

        if ($dialog.ShowDialog()) {
            $dialog.FileName
        }
    }

    $runspaceParameters = @{
        ScriptBlock = $dialogScript
        Variables   = @{ GuiSuggestedFileName = $SuggestedFileName }
    }
    $result = @(Invoke-PSRecallStaRunspace @runspaceParameters)
    if ($result.Count -gt 0) {
        return [string]$result[0]
    }
}
