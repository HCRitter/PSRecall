function Invoke-PSRecallStaRunspace {
    [CmdletBinding()]
    param ([Parameter(Mandatory)][scriptblock]$ScriptBlock, [hashtable]$Variables = @{})

    if ($PSVersionTable.PSVersion.Major -ge 6 -and -not $IsWindows) {
        throw 'The PSRecall GUI is supported on Windows only.'
    }

    $state = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    foreach ($name in $Variables.Keys) {
        $state.Variables.Add([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new($name, $Variables[$name], $name))
    }
    $runspace = [runspacefactory]::CreateRunspace($state)
    $runspace.ApartmentState = 'STA'
    $runspace.ThreadOptions = 'ReuseThread'
    $powerShell = [powershell]::Create()
    try {
        $runspace.Open(); $powerShell.Runspace = $runspace; [void]$powerShell.AddScript($ScriptBlock)
        $result = @($powerShell.Invoke())
        if ($powerShell.HadErrors) { throw (($powerShell.Streams.Error | ForEach-Object ToString) -join [Environment]::NewLine) }
        $result
    }
    finally { $powerShell.Dispose(); $runspace.Dispose() }
}
