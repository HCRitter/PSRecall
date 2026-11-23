function Show-PSRecallHistoryDialog {
    [CmdletBinding()]
    param ([Parameter(Mandatory)][object[]]$History)

    $dialogScript = {
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase

        $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PSRecall - Select session commands"
        Width="1300" Height="720" MinWidth="900" MinHeight="500"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0" Margin="0,0,0,10"
                   Text="Select one or more commands. Output is available only when Get-PSRecall was called with -IncludeOutput."
                   TextWrapping="Wrap" />
        <DataGrid x:Name="HistoryGrid" Grid.Row="1" AutoGenerateColumns="False"
                  CanUserAddRows="False" CanUserDeleteRows="False" IsReadOnly="True"
                  SelectionMode="Extended" SelectionUnit="FullRow" HeadersVisibility="Column"
                  GridLinesVisibility="Horizontal" AlternatingRowBackground="#FFF3F3F3" RowHeaderWidth="0">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ID" Binding="{Binding Id}" Width="65" />
                <DataGridTextColumn Header="Status" Binding="{Binding ExecutionStatus}" Width="105" />
                <DataGridTextColumn Header="Started" Binding="{Binding StartExecution, StringFormat={}{0:yyyy-MM-dd HH:mm:ss}}" Width="155" />
                <DataGridTextColumn Header="Command" Binding="{Binding CommandLine}" Width="2*">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextWrapping" Value="Wrap" /><Setter Property="ToolTip" Value="{Binding CommandLine}" /></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Output" Binding="{Binding Output}" Width="3*">
                    <DataGridTextColumn.ElementStyle><Style TargetType="TextBlock"><Setter Property="TextWrapping" Value="Wrap" /><Setter Property="MaxHeight" Value="140" /><Setter Property="ToolTip" Value="{Binding Output}" /></Style></DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>
        <Grid Grid.Row="2" Margin="0,10,0,0">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto" /><ColumnDefinition Width="Auto" /><ColumnDefinition Width="*" /><ColumnDefinition Width="Auto" /><ColumnDefinition Width="Auto" /></Grid.ColumnDefinitions>
            <Button x:Name="SelectAllButton" Grid.Column="0" Width="105" Height="30" Margin="0,0,8,0" Content="Select All" />
            <Button x:Name="ClearButton" Grid.Column="1" Width="105" Height="30" Content="Clear" />
            <Button x:Name="CancelButton" Grid.Column="3" Width="105" Height="30" Margin="0,0,8,0" IsCancel="True" Content="Cancel" />
            <Button x:Name="UseSelectionButton" Grid.Column="4" Width="125" Height="30" IsDefault="True" Content="Use Selection" />
        </Grid>
    </Grid>
</Window>
'@
        $reader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
        try { $window = [Windows.Markup.XamlReader]::Load($reader) } finally { $reader.Dispose() }
        $grid = $window.FindName('HistoryGrid'); $grid.ItemsSource = @($GuiHistory)
        $window.FindName('SelectAllButton').Add_Click({ $grid.SelectAll() })
        $window.FindName('ClearButton').Add_Click({ $grid.UnselectAll() })
        $window.FindName('CancelButton').Add_Click({ $window.DialogResult = $false; $window.Close() })
        $window.FindName('UseSelectionButton').Add_Click({
            if ($grid.SelectedItems.Count -eq 0) { [void][System.Windows.MessageBox]::Show('Select at least one command.'); return }
            $window.DialogResult = $true; $window.Close()
        })
        if ($window.ShowDialog()) { @($grid.SelectedItems | ForEach-Object { [long]$_.Id } | Sort-Object) }
    }
    @(Invoke-PSRecallStaRunspace -ScriptBlock $dialogScript -Variables @{ GuiHistory = $History })
}
