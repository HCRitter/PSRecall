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
        Width="1350" Height="820" MinWidth="1000" MinHeight="650"
        WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <SolidColorBrush x:Key="WindowBackgroundBrush" Color="#FFFFFF" />
        <SolidColorBrush x:Key="SurfaceBrush" Color="#F6F8FA" />
        <SolidColorBrush x:Key="ControlBackgroundBrush" Color="#FFFFFF" />
        <SolidColorBrush x:Key="ForegroundBrush" Color="#1F2328" />
        <SolidColorBrush x:Key="BorderBrush" Color="#D0D7DE" />
        <SolidColorBrush x:Key="SelectionBrush" Color="#DDF4FF" />
        <SolidColorBrush x:Key="SelectionForegroundBrush" Color="#1F2328" />
        <SolidColorBrush x:Key="AlternatingRowBrush" Color="#F6F8FA" />
        <SolidColorBrush x:Key="DisabledBrush" Color="#8C959F" />
        <SolidColorBrush x:Key="AccentBrush" Color="#0969DA" />
        <SolidColorBrush x:Key="AccentForegroundBrush" Color="#FFFFFF" />

        <Style TargetType="Window">
            <Setter Property="Background" Value="{DynamicResource WindowBackgroundBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="{DynamicResource ControlBackgroundBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="CaretBrush" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="Padding" Value="6,4" />
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Background" Value="{DynamicResource ControlBackgroundBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="MinHeight" Value="28" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid>
                            <Border x:Name="ComboBorder"
                                    Background="{TemplateBinding Background}"
                                    BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="{TemplateBinding BorderThickness}"
                                    CornerRadius="3">
                                <Grid>
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*" />
                                        <ColumnDefinition Width="32" />
                                    </Grid.ColumnDefinitions>
                                    <ContentPresenter Grid.Column="0"
                                                      Margin="8,3,4,3"
                                                      VerticalAlignment="Center"
                                                      Content="{TemplateBinding SelectionBoxItem}"
                                                      ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                                      ContentStringFormat="{TemplateBinding SelectionBoxItemStringFormat}"
                                                      TextElement.Foreground="{TemplateBinding Foreground}" />
                                    <ToggleButton Grid.Column="1"
                                                  Focusable="False"
                                                  Background="Transparent"
                                                  BorderThickness="0"
                                                  IsChecked="{Binding IsDropDownOpen, RelativeSource={RelativeSource TemplatedParent}, Mode=TwoWay}">
                                        <ToggleButton.Template>
                                            <ControlTemplate TargetType="ToggleButton">
                                                <Border Background="Transparent">
                                                    <Path Width="8"
                                                          Height="5"
                                                          HorizontalAlignment="Center"
                                                          VerticalAlignment="Center"
                                                          Fill="{DynamicResource ForegroundBrush}"
                                                          Data="M 0 0 L 8 0 L 4 5 Z" />
                                                </Border>
                                            </ControlTemplate>
                                        </ToggleButton.Template>
                                    </ToggleButton>
                                </Grid>
                            </Border>
                            <Popup x:Name="PART_Popup"
                                   Placement="Bottom"
                                   IsOpen="{TemplateBinding IsDropDownOpen}"
                                   AllowsTransparency="True"
                                   Focusable="False"
                                   PopupAnimation="Fade">
                                <Border Margin="0,2,0,0"
                                        MinWidth="{Binding ActualWidth, RelativeSource={RelativeSource TemplatedParent}}"
                                        Background="{DynamicResource ControlBackgroundBrush}"
                                        BorderBrush="{DynamicResource BorderBrush}"
                                        BorderThickness="1"
                                        CornerRadius="3">
                                    <ScrollViewer MaxHeight="300">
                                        <ItemsPresenter />
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsKeyboardFocusWithin" Value="True">
                                <Setter TargetName="ComboBorder" Property="BorderBrush" Value="{DynamicResource AccentBrush}" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="{DynamicResource ControlBackgroundBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="Padding" Value="8,5" />
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="{DynamicResource SelectionBrush}" />
                    <Setter Property="Foreground" Value="{DynamicResource SelectionForegroundBrush}" />
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Foreground" Value="{DynamicResource DisabledBrush}" />
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="Padding" Value="10,4" />
        </Style>
        <Style x:Key="PrimaryButtonStyle" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="{DynamicResource AccentBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource AccentForegroundBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource AccentBrush}" />
            <Setter Property="FontWeight" Value="SemiBold" />
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
        </Style>
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="{DynamicResource ControlBackgroundBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="HorizontalGridLinesBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="VerticalGridLinesBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="RowBackground" Value="{DynamicResource ControlBackgroundBrush}" />
            <Setter Property="AlternatingRowBackground" Value="{DynamicResource AlternatingRowBrush}" />
        </Style>
        <Style TargetType="DataGridColumnHeader">
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="Padding" Value="8,6" />
        </Style>
        <Style TargetType="DataGridRow">
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="{DynamicResource SelectionBrush}" />
                    <Setter Property="Foreground" Value="{DynamicResource SelectionForegroundBrush}" />
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="DataGridCell">
            <Setter Property="Foreground" Value="{Binding Foreground, RelativeSource={RelativeSource AncestorType=DataGridRow}}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="Padding" Value="6,4" />
        </Style>
        <Style TargetType="ToolTip">
            <Setter Property="Background" Value="{DynamicResource SurfaceBrush}" />
            <Setter Property="Foreground" Value="{DynamicResource ForegroundBrush}" />
            <Setter Property="BorderBrush" Value="{DynamicResource BorderBrush}" />
            <Setter Property="MaxWidth" Value="900" />
        </Style>
    </Window.Resources>

    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto" />
            <RowDefinition Height="*" />
            <RowDefinition Height="Auto" />
            <RowDefinition Height="Auto" />
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,10">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*" />
                <ColumnDefinition Width="Auto" />
                <ColumnDefinition Width="150" />
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" VerticalAlignment="Center"
                       Text="Select commands, configure optional export settings, then use the selection or export it directly."
                       TextWrapping="Wrap" />
            <TextBlock Grid.Column="1" Margin="16,0,8,0" VerticalAlignment="Center" Text="Theme:" />
            <ComboBox x:Name="ThemeComboBox" Grid.Column="2" SelectedIndex="0">
                <ComboBoxItem Content="System" />
                <ComboBoxItem Content="Light" />
                <ComboBoxItem Content="Dark" />
            </ComboBox>
        </Grid>

        <DataGrid x:Name="HistoryGrid" Grid.Row="1" AutoGenerateColumns="False"
                  CanUserAddRows="False" CanUserDeleteRows="False"
                  CanUserReorderColumns="True" CanUserResizeColumns="True" CanUserSortColumns="True"
                  IsReadOnly="True" SelectionMode="Extended" SelectionUnit="FullRow"
                  HeadersVisibility="Column" RowHeaderWidth="0">
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

        <GroupBox Grid.Row="2" Header="Export options" Margin="0,12,0,0" Padding="10">
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
                <TextBlock Grid.Row="0" Grid.Column="0" Margin="0,4,10,0" Text="Format:" />
                <ComboBox x:Name="FormatComboBox" Grid.Row="0" Grid.Column="1" SelectedIndex="0">
                    <ComboBoxItem Content="PowerShell" />
                    <ComboBoxItem Content="Text" />
                    <ComboBoxItem Content="Markdown" />
                </ComboBox>
                <TextBlock Grid.Row="1" Grid.Column="0" Margin="0,10,10,0" Text="Title:" />
                <TextBox x:Name="TitleTextBox" Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3"
                         Margin="0,8,0,0" Text="PSRecall Session Export" />
                <WrapPanel Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="4" Margin="0,12,0,0">
                    <CheckBox x:Name="IncludeOutputCheckBox" Margin="0,0,24,0" Content="Include output" />
                    <CheckBox x:Name="ResolveAliasesCheckBox" Margin="0,0,24,0" Content="Resolve aliases" />
                    <CheckBox x:Name="IncludeSensitiveMetadataCheckBox" Content="Include sensitive metadata" />
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
            <Button x:Name="SelectAllButton" Grid.Column="0" Width="105" Height="30" Margin="0,0,8,0" Content="Select All" />
            <Button x:Name="ClearButton" Grid.Column="1" Width="105" Height="30" Content="Clear" />
            <Button x:Name="CancelButton" Grid.Column="3" Width="105" Height="30" Margin="0,0,8,0" IsCancel="True" Content="Cancel" />
            <Button x:Name="UseSelectionButton" Grid.Column="4" Width="125" Height="30" Margin="0,0,8,0" Content="Use Selection" />
            <Button x:Name="ExportButton" Grid.Column="5" Width="125" Height="30" IsDefault="True" Style="{StaticResource PrimaryButtonStyle}" Content="Export" />
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
        $themeComboBox = $window.FindName('ThemeComboBox')
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

        $getSystemTheme = {
            try {
                $personalizePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
                $appsUseLightTheme = Get-ItemPropertyValue -Path $personalizePath -Name AppsUseLightTheme -ErrorAction Stop
                if ($appsUseLightTheme -eq 0) {
                    return 'Dark'
                }
            }
            catch {
                # Light is the safe default when the Windows preference cannot be read.
            }

            return 'Light'
        }

        $applyTheme = {
            param (
                [Parameter(Mandatory)]
                [ValidateSet('Light', 'Dark')]
                [string]$Theme
            )

            $colors = if ($Theme -eq 'Dark') {
                @{
                    WindowBackground    = '#0D1117'
                    Surface             = '#161B22'
                    ControlBackground   = '#21262D'
                    Foreground          = '#F0F6FC'
                    Border              = '#30363D'
                    Selection           = '#1F6FEB'
                    SelectionForeground = '#FFFFFF'
                    AlternatingRow      = '#161B22'
                    Disabled            = '#6E7681'
                    Accent              = '#238636'
                    AccentForeground    = '#FFFFFF'
                }
            }
            else {
                @{
                    WindowBackground    = '#FFFFFF'
                    Surface             = '#F6F8FA'
                    ControlBackground   = '#FFFFFF'
                    Foreground          = '#1F2328'
                    Border              = '#D0D7DE'
                    Selection           = '#DDF4FF'
                    SelectionForeground = '#1F2328'
                    AlternatingRow      = '#F6F8FA'
                    Disabled            = '#8C959F'
                    Accent              = '#0969DA'
                    AccentForeground    = '#FFFFFF'
                }
            }

            $resourceMap = @{
                WindowBackgroundBrush    = 'WindowBackground'
                SurfaceBrush             = 'Surface'
                ControlBackgroundBrush   = 'ControlBackground'
                ForegroundBrush          = 'Foreground'
                BorderBrush              = 'Border'
                SelectionBrush           = 'Selection'
                SelectionForegroundBrush = 'SelectionForeground'
                AlternatingRowBrush      = 'AlternatingRow'
                DisabledBrush            = 'Disabled'
                AccentBrush              = 'Accent'
                AccentForegroundBrush    = 'AccentForeground'
            }

            foreach ($resourceName in $resourceMap.Keys) {
                $colorName = $resourceMap[$resourceName]
                $color = [System.Windows.Media.ColorConverter]::ConvertFromString($colors[$colorName])
                $window.Resources[$resourceName] = [System.Windows.Media.SolidColorBrush]::new($color)
            }
        }

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

        $themeComboBox.Add_SelectionChanged({
            if ($null -eq $themeComboBox.SelectedItem) {
                return
            }

            $selectedTheme = [string]$themeComboBox.SelectedItem.Content
            $effectiveTheme = if ($selectedTheme -eq 'System') {
                & $getSystemTheme
            }
            else {
                $selectedTheme
            }

            & $applyTheme -Theme $effectiveTheme
        })

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

        & $applyTheme -Theme (& $getSystemTheme)

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
