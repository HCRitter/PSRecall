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
        Width="1300"
        Height="720"
        MinWidth="900"
        MinHeight="500"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>
        <TextBlock Grid.Row="0"
                   Margin="0,0,0,10"
                   Text="Select one or more commands. Output is available only with -IncludeOutput." />
        <DataGrid x:Name="HistoryGrid"
                  Grid.Row="1"
                  AutoGenerateColumns="False"
                  CanUserAddRows="False"
                  CanUserDeleteRows="False"
                  IsReadOnly="True"
                  SelectionMode="Extended"
                  SelectionUnit="FullRow"
                  HeadersVisibility="Column">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ID" Binding="{Binding Id}" Width="65" />
                <DataGridTextColumn Header="Status" Binding="{Binding ExecutionStatus}" Width="105" />
                <DataGridTextColumn Header="Started" Binding="{Binding StartExecution}" Width="155" />
                <DataGridTextColumn Header="Command" Binding="{Binding CommandLine}" Width="2*" />
                <DataGridTextColumn Header="Output" Binding="{Binding Output}" Width="3*" />
            </DataGrid.Columns>
        </DataGrid>
        <StackPanel Grid.Row="2"
                    Orientation="Horizontal"
                    HorizontalAlignment="Right"
                    Margin="0,10,0,0">
            <Button x:Name="CancelButton"
                    Content="Cancel"
                    Width="105"
                    Margin="0,0,8,0"
                    IsCancel="True" />
            <Button x:Name="UseSelectionButton"
                    Content="Use Selection"
                    Width="125"
                    IsDefault="True" />
        </StackPanel>
    </Grid>
</Window>
'@

        $xmlReader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
        try {
            $window = [Windows.Markup.XamlReader]::Load($xmlReader)
        }
        finally {
            $xmlReader.Dispose()
        }

        $grid = $window.FindName('HistoryGrid')
        $grid.ItemsSource = @($GuiHistory)
        $window.FindName('UseSelectionButton').Add_Click({
            if ($grid.SelectedItems.Count -eq 0) {
                [void][System.Windows.MessageBox]::Show('Select at least one command.')
                return
            }
            $window.DialogResult = $true
            $window.Close()
        })

        if ($window.ShowDialog()) {
            @($grid.SelectedItems | ForEach-Object { [long]$_.Id } | Sort-Object)
        }
    }

    Invoke-PSRecallStaRunspace -ScriptBlock $dialogScript -Variables @{ GuiHistory = $History }
}
