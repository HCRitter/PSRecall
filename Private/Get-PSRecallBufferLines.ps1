function Get-PSRecallBufferLines {
    [CmdletBinding()]
    [OutputType([string[]])]
    param ()

    try {
        $rawUi = $Host.UI.RawUI
        $bufferSize = $rawUi.BufferSize
        $cursorPosition = $rawUi.CursorPosition

        if ($bufferSize.Width -le 0 -or $bufferSize.Height -le 0) {
            throw 'The current host reported an invalid buffer size.'
        }

        $bottom = [Math]::Min($cursorPosition.Y, $bufferSize.Height - 1)
        $rectangle = [System.Management.Automation.Host.Rectangle]::new(
            0,
            0,
            $bufferSize.Width - 1,
            $bottom
        )
        $cells = $rawUi.GetBufferContents($rectangle)
        $lines = [System.Collections.Generic.List[string]]::new()

        for ($row = 0; $row -lt $cells.GetLength(0); $row++) {
            $characters = [char[]]::new($cells.GetLength(1))
            for ($column = 0; $column -lt $cells.GetLength(1); $column++) {
                $characters[$column] = $cells[$row, $column].Character
            }
            $lines.Add((-join $characters).TrimEnd())
        }

        @($lines)
    }
    catch {
        throw "The current PowerShell host does not expose a readable RawUI terminal buffer: $($_.Exception.Message)"
    }
}
