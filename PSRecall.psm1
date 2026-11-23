$privatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'
$publicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'

$importParameters = @{
    Filter      = '*.ps1'
    File        = $true
    ErrorAction = 'Stop'
}

$privateScripts = @(Get-ChildItem -Path $privatePath @importParameters | Sort-Object -Property Name)
$publicScripts = @(Get-ChildItem -Path $publicPath @importParameters | Sort-Object -Property Name)

foreach ($script in @($privateScripts) + @($publicScripts)) {
    try {
        . $script.FullName
    }
    catch {
        throw "Failed to import PSRecall script '$($script.FullName)': $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @(
    'Export-PSRecall'
    'Get-PSRecall'
)
