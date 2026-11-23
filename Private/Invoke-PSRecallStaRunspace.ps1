function Invoke-PSRecallStaRunspace {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [hashtable]$Variables = @{}
    )

    if (-not $IsWindows -and $PSVersionTable.PSVersion.Major -ge 6) {
        throw 'The PSRecall GUI is currently supported on Windows only. Use the non-GUI pipeline with -Path on macOS or Linux.'
    }

    $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    foreach ($name in $Variables.Keys) {
        $entry = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new(
            $name,
            $Variables[$name],
            "PSRecall GUI variable: $name"
        )
        $initialSessionState.Variables.Add($entry)
    }

    $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($initialSessionState)
    $runspace.ApartmentState = [System.Threading.ApartmentState]::STA
    $runspace.ThreadOptions = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread

    $powerShell = [System.Management.Automation.PowerShell]::Create()

    try {
        $runspace.Open()
        $powerShell.Runspace = $runspace
        [void]$powerShell.AddScript($ScriptBlock)
        $result = @($powerShell.Invoke())

        if ($powerShell.HadErrors) {
            $messages = @($powerShell.Streams.Error | ForEach-Object { $_.ToString() })
            throw ($messages -join [Environment]::NewLine)
        }

        return $result
    }
    finally {
        $powerShell.Dispose()
        $runspace.Dispose()
    }
}
