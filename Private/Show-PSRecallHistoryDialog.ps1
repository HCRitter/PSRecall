function Show-PSRecallHistoryDialog {
    [CmdletBinding()]
    [OutputType('PSRecall.GuiResult')]
    param (
        [Parameter(Mandatory)]
        [object[]]$History,

        [Parameter()]
        [switch]$DefaultIncludeOutput
    )

    $dialogScript = {
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase

        $xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PSRecall - Select and export session commands"
        Width="1350"
        Height="820"
        MinWidth="1000"
        MinHeight="650"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0"
                   Margin="0,0,0,10"
                   Text="Select commands, configure optional export settings, then use the selection or export it directly."
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
                  AlternatingRowBackground="#FFF3F3F3"
                  RowHeaderWidth="0">
            <DataGrid.Columns>
                <DataGridTextColumn Header="ID" Binding="{Binding Id}" Width="65" />
                <DataGridTextColumn Header="Status" Binding="{Binding ExecutionStatus}" Width="105" />
                <DataGridTextColumn Header="Started" Binding="{Binding StartExecution}" Width="155" />
                <DataGridTextColumn Header="Command" Binding="{Binding CommandLine}" Width="2*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="TextWrapping" Value="Wrap" />
                            <Setter Property="VerticalAlignment" Value="Top" />
                            <Setter Property="ToolTip" Value="{Binding CommandLine}" />
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
                <DataGridTextColumn Header="Output" Binding="{Binding Output}" Width="3*">
                    <DataGridTextColumn.ElementStyle>
                        <Style TargetType="TextBlock">
                            <Setter Property="TextWrapping" Value="Wrap" />
                            <Setter Property="VerticalAlignment" Value="Top" />
                            <Setter Property="MaxHeight" Value="140" />
                            <Setter Property="ToolTip" Value="{Binding Output}" />
                        </Style>
                    </DataGridTextColumn.ElementStyle>
                </DataGridTextColumn>
            </DataGrid.Columns>
        </DataGrid>

        <GroupBox Grid.Row="2"
                  Header="Export options"
                  Margin="0,12,0,0"
                  Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                    <RowDefinition Height="Auto" />
                </Grid.RowDefinitions>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto" />
                    <ColumnDefinition Width="220" />
                    <ColumnDefinition Width="24" />
                    <ColumnDefinition Width="*" />
                </Grid.ColumnDefinitions>

                <TextBlock Grid.Row="0"
                           Grid.Column="0"
                           Margin="0,4,10,0"
                           Text="Format:" />
                <ComboBox x:Name="FormatComboBox"
                          Grid.Row="0"
                          Grid.Column="1"
                          SelectedIndex="0">
                    <ComboBoxItem Content="PowerShell" />
                    <ComboBoxItem Content="Text" />
                    <ComboBoxItem Content="Markdown" />
                </ComboBox>

                <TextBlock Grid.Row="1"
                           Grid.Column="0"
                           Margin="0,10,10,0"
                           Text="Title:" />
                <TextBox x:Name="TitleTextBox"
                         Grid.Row="1"
                         Grid.Column="1"
                         Grid.ColumnSpan="3"
                         Margin="0,8,0,0"
                         Text="PSRecall Session Export" />

                <WrapPanel Grid.Row="2"
                           Grid.Column="0"
                           Grid.ColumnSpan="4"
                           Margin="0,12,0,0">
                    <CheckBox x:Name="IncludeOutputCheckBox"
                              Margin="0,0,24,0"
                              Content="Include output" />
                    <CheckBox x:Name="ResolveAliasesCheckBox"
                              Margin="0,0,24,0"
                              Content="Resolve aliases" />
                    <CheckBox x:Name="IncludeSensitiveMetadataCheckBox"
                              Content="Include sensitive metadata" />
                </WrapPanel>
            </Grid>
        </GroupBox>

        <Grid Grid.Row="3" Margin="0,12,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
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
                    Margin="0,0,8,0"
                    Content="Use Selection" />
            <Button x:Name="ExportButton"
                    Grid.Column="5"
                    Width="125"
                    Height="30"
                    IsDefault="True"
                    Content="Export" />
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
        $formatComboBox = $window.FindName('FormatComboBox')
        $titleTextBox = $window.FindName('TitleTextBox')
        $includeOutputCheckBox = $window.FindName('IncludeOutputCheckBox')
        $resolveAliasesCheckBox = $window.FindName('ResolveAliasesCheckBox')
        $includeSensitiveMetadataCheckBox = $window.FindName('IncludeSensitiveMetadataCheckBox')
        $selectAllButton = $window.FindName('SelectAllButton')
        $clearButton = $window.FindName('ClearButton')
        $cancelButton = $window.FindName('CancelButton')
        $useSelectionButton = $window.FindName('UseSelectionButton')
        $exportButton = $window.FindName('ExportButton')

        $historyGrid.ItemsSource = @($GuiHistory)
        $includeOutputCheckBox.IsChecked = [bool]$GuiDefaultIncludeOutput

        $hasCapturedOutput = @(
            $GuiHistory | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Output) }
        ).Count -gt 0
        $includeOutputCheckBox.IsEnabled = $hasCapturedOutput
        if (-not $hasCapturedOutput) {
            $includeOutputCheckBox.IsChecked = $false
            $includeOutputCheckBox.ToolTip = 'No output was captured. Call Get-PSRecall with -IncludeOutput.'
        }

        $formatComboBox.Add_SelectionChanged({
            $selectedFormat = [string]$formatComboBox.SelectedItem.Content
            $titleTextBox.IsEnabled = $selectedFormat -ne 'PowerShell'
        })
        $titleTextBox.IsEnabled = $false

        $selectAllButton.Add_Click({ $historyGrid.SelectAll() })
        $clearButton.Add_Click({ $historyGrid.UnselectAll() })
        $cancelButton.Add_Click({
            $window.Tag = 'Cancel'
            $window.DialogResult = $false
            $window.Close()
        })

        $completeAction = {
            param ([string]$Action)

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

            $window.Tag = $Action
            $window.DialogResult = $true
            $window.Close()
        }

        $useSelectionButton.Add_Click({ & $completeAction -Action 'Select' })
        $exportButton.Add_Click({ & $completeAction -Action 'Export' })

        $dialogResult = $window.ShowDialog()
        if (-not $dialogResult) {
            [pscustomobject]@{
                PSTypeName = 'PSRecall.GuiResult'
                Action     = 'Cancel'
            }
            return
        }

        [pscustomobject]@{
            PSTypeName               = 'PSRecall.GuiResult'
            Action                   = [string]$window.Tag
            SelectedIds              = @($historyGrid.SelectedItems | ForEach-Object { [long]$_.Id } | Sort-Object)
            Format                   = [string]$formatComboBox.SelectedItem.Content
            Title                    = [string]$titleTextBox.Text
            IncludeOutput            = [bool]$includeOutputCheckBox.IsChecked
            ResolveAliases           = [bool]$resolveAliasesCheckBox.IsChecked
            IncludeSensitiveMetadata = [bool]$includeSensitiveMetadataCheckBox.IsChecked
        }
    }

    $variables = @{
        GuiHistory              = $History
        GuiDefaultIncludeOutput = [bool]$DefaultIncludeOutput
    }

    Invoke-PSRecallStaRunspace -ScriptBlock $dialogScript -Variables $variables |
        Select-Object -First 1
}
