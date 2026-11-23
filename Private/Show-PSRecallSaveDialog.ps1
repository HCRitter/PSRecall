function Show-PSRecallSaveDialog {
    [CmdletBinding()]
    param (
        [string]$SuggestedFileName = 'RecoveredSession.ps1',
        [string]$Filter = 'PowerShell script (*.ps1)|*.ps1',
        [string]$DefaultExtension = '.ps1'
    )

    $dialogScript = {
        Add-Type -AssemblyName PresentationFramework
        $dialog = [Microsoft.Win32.SaveFileDialog]::new()
        $dialog.Filter = $GuiFilter
        $dialog.DefaultExt = $GuiExtension
        $dialog.FileName = $GuiFileName
        $dialog.AddExtension = $true
        if ($dialog.ShowDialog()) {
            $dialog.FileName
        }
    }

    $variables = @{
        GuiFileName  = $SuggestedFileName
        GuiFilter    = $Filter
        GuiExtension = $DefaultExtension
    }
    @(Invoke-PSRecallStaRunspace -ScriptBlock $dialogScript -Variables $variables) |
        Select-Object -First 1
}
