Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

#Install-Module -Name PSWindowsUpdate -Force

# 1. Resolve path to GUI.xaml
$xamlPath = Join-Path -Path $PSScriptRoot -ChildPath "FvLocalToolPanel.xaml"

if (-not (Test-Path -Path $xamlPath)) {
    Write-Error "Could not find GUI.xaml at: $xamlPath"
    Read-Host "Press Enter to exit..."
    return
}

# 2. Load XAML (Cleaned of x:Class attributes)
try {
    $rawXaml = Get-Content -Path $xamlPath -Raw
    # Remove x:Class and mc:Ignorable attributes that break XamlReader
    $rawXaml = $rawXaml -replace 'x:Class="[^"]*"', '' -replace 'mc:Ignorable="[^"]*"', ''
    
    [xml]$xaml = $rawXaml
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)
    $statusGrid = $window.FindName("StatusGrid")
}
catch {
    Write-Host "Error loading XAML file: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
    return
}

# 3. Setup Colors
$script:states = @{
    "IDLE"  = @{ Color = [System.Windows.Media.Color]::FromRgb(30, 41, 59);   Text = "[ UNKNOWN ]`n" }
    "OK"    = @{ Color = [System.Windows.Media.Color]::FromRgb(16, 185, 129);  Text = "[ READY ]`n" }
    "ERROR" = @{ Color = [System.Windows.Media.Color]::FromRgb(225, 29, 72);   Text = "[ ERROR ]`n" }
    "COMMAND" = @{ Color = [System.Windows.Media.Color]::FromRgb(0,0,255); Text = "[ COMMAND ]`n"}
}

# 4. Helper Function for Smooth Color Transitions
function Animate-ButtonColor ($button, $targetColor) {
    # Fallback to Transparent if background is not a SolidColorBrush yet
    $currentColor = [System.Windows.Media.Colors]::Transparent
    if ($button.Background -is [System.Windows.Media.SolidColorBrush]) {
        $currentColor = $button.Background.Color
    }

    $animation = New-Object System.Windows.Media.Animation.ColorAnimation
    $animation.From = $currentColor
    $animation.To = $targetColor
    $animation.Duration = [System.Windows.Duration]::new([TimeSpan]::FromMilliseconds(300))

    $newBrush = New-Object System.Windows.Media.SolidColorBrush($currentColor)
    $button.Background = $newBrush
    $newBrush.BeginAnimation([System.Windows.Media.SolidColorBrush]::ColorProperty, $animation)
}

function Switch-ButtonState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Object]$sndr,

        [Parameter(Mandatory = $true)]
        [ValidateSet("IDLE", "OK", "ERROR", "COMMAND")]
        [string]$TargetState
    )

    # Set the button properties based on the desired TARGET state
    $sndr.Tag     = $TargetState
    Animate-ButtonColor $sndr $script:states[$TargetState].Color
    $sndr.Content = $script:states[$TargetState].Text + $sndr.Name.Replace("Btn", "")
}

$Buttons = @(@{Text = "RecoveryPartition"; Style = "IDLE"}, @{ Text = "Updates"; Style = "IDLE"}, @{ Text="DiskAllocated"; Style = "IDLE"}, @{Text = "SYSPREp"; Style = "IDLE"}, @{Text="RAM"; Style="IDLE"}, @{Text="Saturnin"; Style="IDLE"}, @{Text="DeleteLocalUsers"; Style="COMMAND"}; @{Text="SusIdReplace"; Style="COMMAND"})

# 5. Build Dynamic Buttons
foreach ($i in $Buttons) {
    $btn = New-Object System.Windows.Controls.Button
    if ($window.Resources.Contains("AnimatedBlueButton")) {
        $btn.Style = $window.Resources["AnimatedBlueButton"]
    }
    
    $btn.Name = $i.Text
    # Initialize initial IDLE state
    Switch-ButtonState -sndr $btn -TargetState $i.Style

    $btn.Add_Click({
        param($sender, $e)
        
        switch ($sender.Name) {
            "RecoveryPartition" {
                if($sender.Tag -eq "IDLE"){
                    $recoveryCount = (Get-Partition | Where-Object { $_.Type -eq 'Recovery' } | Measure-Object).Count
                    if ($recoveryCount -gt 0) {
                        Switch-ButtonState -sndr $sender -TargetState "OK"
                    } else {
                        Switch-ButtonState -sndr $sender -TargetState "ERROR"
                    }
                }elseif($sender.Tag -eq "ERROR"){
                    .\createRecoveryPartition_local_FV.ps1
                }
                
            }
            "Updates" {
                if($sender.Tag -eq "IDLE"){
                    if (Get-WindowsUpdate){
                    Switch-ButtonState -sndr $sender -TargetState "OK"
                    }else{
                        Switch-ButtonState -sndr $sender -TargetState "ERROR"
                    }
                }elseif($sender.Tag -eq "ERROR"){
                    Start-Process "ms-settings:windowsupdate-action"
                }
                
            }
            "DiskAllocated"{
                if($sender.Tag -eq "IDLE"){
                    $cdrive = Get-Partition -Driveletter C | Get-Disk
                    $totalvol = $cdrive.Size
                    $alls = ($cdrive | Get-Partition | Measure-Object -Property Size -Sum).sum
                    $unal = ( $totalvol - $alls )
                    $unalspc = $null
                    if($unal / 1024 / 1024 -gt 100){
                        Switch-ButtonState -sndr $sender -TargetState "ERROR"
                    }else{
                        Switch-ButtonState -sndr $sender -TargetState "OK"
                    }
                }elseif($sender.Tag -eq "ERROR"){
                    Start-Process "diskmgmt.msc"
                }
                
            }
            "SYSPREp" {
                if($sender.Tag -eq "IDLE"){
                    $tagPath = "C:\Windows\System32\Sysprep\Sysprep_succeeded.tag"
                    if (Test-Path -Path $tagPath -PathType Leaf) {
                        Switch-ButtonState -sndr $sender -TargetState "OK"
                    } else {
                        Switch-ButtonState -sndr $sender -TargetState "ERROR"
                    }
                }elseif($sender.Tag -eq "ERROR"){
                    Start-Process "$env:SystemRoot\System32\Sysprep\"
                }
            }
            "RAM"{
                if($sender.Tag -eq "IDLE"){
                    if(((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB) -gt 14){
                        Switch-ButtonState -sndr $sender -TargetState "OK"
                    }else{
                        Switch-ButtonState -sndr $sender -TargetState "ERROR"
                    }
                }elseif($sender.Tag -eq "ERROR"){
                    Start-Process taskmgr
                }
            }
            "Saturnin"{
                if($sender.Tag -eq "IDLE"){
                    $usr = "saturnin"
                    $localusr = $null
                    $SaturninExistst = $false
                    try{
                        
                        $localusr = Get-LocalUser $usr 
                    }catch{}
                    if ($localusr -ceq $null){
                        Switch-ButtonState -sndr $sender -TargetState "ERROR"
                    }else{
                        Switch-ButtonState -sndr $sender -TargetState "OK"
                    }
                }elseif($sender.Tag -eq "ERROR"){
                    New-LocalUser -Name "saturnin" -NoPassword
                    Add-LocalGroupMember -Group "Administrators" -Member "saturnin"
                }
            }
            "DeleteLocalUsers"{
                $usrs = Get-LocalUser
                foreach($user in $usrs)
                {
                    if($user.name -ceq "saturnin")
                    {
                        Write-Host "working" -ForegroundColor Blue -BackgroundColor Blue
                    
                    }elseif ($user.name -ceq "Administrator"){
                        Disable-LocalUser -InputObject $user
                    }elseif ($user.name -ceq "Guest"){
                        Disable-LocalUser -InputObject $user
                    }elseif ($user.name -ceq "DefaultAccount"){
                        Disable-LocalUser -InputObject $user
                    }elseif ($user.name -ceq "WDAGUtilityAccount"){
                        Disable-LocalUser -InputObject $user
                    }
                    else{
                        Remove-LocalUser -Name $user.name
                    }
                }
            }
            "SusIdReplace"{
                .\sus.ps1
            }
        }
        if($sender.Tag -eq "ERROR"){
            Switch-ButtonState -sndr $sender -TargetState "IDLE"
        }
    })

    $statusGrid.Children.Add($btn) | Out-Null
}

# 6. Show Window
try {
    $null = $window.ShowDialog()
}
catch {
    Write-Host "Runtime Error: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit..."
}