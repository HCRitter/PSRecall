$publicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$privatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'

$privateScripts = Get-ChildItem -Path $privatePath -Filter '*.ps1' -File -ErrorAction Stop
$publicScripts = Get-ChildItem -Path $publicPath -Filter '*.ps1' -File -ErrorAction Stop

foreach ($script in @($privateScripts) + @($publicScripts)) {
    try {
        . $script.FullName
    }
    catch {
        throw "Failed to import PSRecall script '$($script.FullName)': $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @('Export-PSRecall', 'Get-PSRecall')
