function Get-PSRecall {
    [CmdletBinding(DefaultParameterSetName='Last')]
    param([Parameter(ParameterSetName='Last')][ValidateRange(1,[int]::MaxValue)][int]$Last=20,[Parameter(Mandatory,ParameterSetName='All')][switch]$All,[Parameter(Mandatory,ParameterSetName='Range')][long]$FromId,[Parameter(Mandatory,ParameterSetName='Range')][long]$ToId,[switch]$SuccessfulOnly,[switch]$Gui)
    $parameters=@{SuccessfulOnly=$SuccessfulOnly}
    switch($PSCmdlet.ParameterSetName){'All'{$parameters.All=$true}'Range'{$parameters.FromId=$FromId;$parameters.ToId=$ToId}default{$parameters.Last=$Last}}
    $selection=@(Get-PSRecallSelection @parameters|ConvertTo-PSRecallEntry)
    if($Gui -and $selection.Count){$ids=@(Show-PSRecallHistoryDialog -History $selection);$selection=@($selection|Where-Object Id -in $ids)}
    $selection
}
