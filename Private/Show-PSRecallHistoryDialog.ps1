function Show-PSRecallHistoryDialog {
    [CmdletBinding()]
    [OutputType([long[]])]
    param (
        [Parameter(Mandatory)]
        [object[]]$History
    )

    $dialogScript = {
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase

        $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PSRecall - Select session commands"
        Width="1150"
        Height="700"
        MinWidth="850"
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
                   Text="Select one or more commands. Use Ctrl or Shift for multi-selection, then choose Use Selection."
                   TextWrapping="Wrap" />

        <DataGrid x:Name="HistoryGrid"
                  Grid.Row="1"
                  AutoGenerateColumns="False"
                  CanUserAddRows="False"
                  CanUserDeleteRows="False"
                  CanUserReorderColumns="True"
                  CanUserResizeColumns="True"
                  CanUserSortColumns="True"
                  IsReadOnly="True"
                  SelectionMode="Extended"
                  SelectionUnit="FullRow"
                  HeadersVisibility="Column"
                  GridLinesVisibility="Horizontal"
                  AlternatingRowBackground="#FFF3F3F3"
                  RowHeaderWidth="0">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ID"
                                    Binding="{Binding Id}"
                                    Width="70" />
                <DataGridTextColumn Header="Status"
                                    Binding="{Binding ExecutionStatus}"
                                    Width="110" />
                <DataGridTextColumn Header="Started"
                                    Binding="{Binding StartExecution, StringFormat={}{0:yyyy-MM-dd HH:mm:ss}}"
                                    Width="155" />
                <DataGridTextColumn Header="Command"
                                    Binding="{Binding CommandLine}"
                                    Width="*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="TextWrapping" Value="Wrap" />
                            <Setter Property="ToolTip" Value="{Binding CommandLine}" />
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>

        <Grid Grid.Row="2" Margin="0,10,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="Auto" />
            </Grid.ColumnDefinitions>

            <Button x:Name="SelectAllButton"
                    Grid.Column="0"
                    Width="105"
                    Height="30"
                    Margin="0,0,8,0"
                    Content="Select All" />
            <Button x:Name="ClearButton"
                    Grid.Column="1"
                    Width="105"
                    Height="30"
                    Content="Clear" />
            <Button x:Name="CancelButton"
                    Grid.Column="3"
                    Width="105"
                    Height="30"
                    Margin="0,0,8,0"
                    IsCancel="True"
                    Content="Cancel" />
            <Button x:Name="UseSelectionButton"
                    Grid.Column="4"
                    Width="125"
                    Height="30"
                    IsDefault="True"
                    Content="Use Selection" />
        </Grid>
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

        $historyGrid = $window.FindName('HistoryGrid')
        $selectAllButton = $window.FindName('SelectAllButton')
        $clearButton = $window.FindName('ClearButton')
        $cancelButton = $window.FindName('CancelButton')
        $useSelectionButton = $window.FindName('UseSelectionButton')

        $historyGrid.ItemsSource = @($GuiHistory)
        $selectAllButton.Add_Click({ $historyGrid.SelectAll() })
        $clearButton.Add_Click({ $historyGrid.UnselectAll() })
        $cancelButton.Add_Click({
            $window.DialogResult = $false
            $window.Close()
        })
        $useSelectionButton.Add_Click({
            if ($historyGrid.SelectedItems.Count -eq 0) {
                [void][System.Windows.MessageBox]::Show(
                    $window,
                    'Select at least one command.',
                    'PSRecall',
                    [System.Windows.MessageBoxButton]::OK,
                    [System.Windows.MessageBoxImage]::Information
                )
                return
            }

            $window.DialogResult = $true
            $window.Close()
        })

        $dialogResult = $window.ShowDialog()
        if ($dialogResult) {
            @(
                $historyGrid.SelectedItems |
                    ForEach-Object { [long]$_.Id } |
                    Sort-Object
            )
        }
    }

    $runspaceParameters = @{
        ScriptBlock = $dialogScript
        Variables   = @{ GuiHistory = $History }
    }
    return @(Invoke-PSRecallStaRunspace @runspaceParameters)
}
