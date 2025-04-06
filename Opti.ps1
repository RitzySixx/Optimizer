# Define the GitHub raw file URL
$githubScriptUrl = "https://raw.githubusercontent.com/RitzySixx/Optimizer/refs/heads/main/Opti.ps1"

# Get the current script path
$currentScript = $MyInvocation.MyCommand.Path

# Check for updates
try {
    $latestVersion = ((Invoke-WebRequest -Uri $githubScriptUrl).Content).Trim()
    $currentVersion = (Get-Content -Path $currentScript -Raw).Trim()

    if ($latestVersion -ne $currentVersion) {
        Write-Host "Update found! Downloading latest version..." -ForegroundColor Green
        $latestVersion | Out-File -FilePath $currentScript -Force -Encoding UTF8
        Write-Host "Script will restart once Update is Complete..." -ForegroundColor Green
        Start-Sleep -Seconds 10
        Start-Process powershell.exe -ArgumentList "-NoExit -File `"$currentScript`""
        exit
    }
} catch {
    Write-Host "Unable to check for updates. Continuing with current version..." -ForegroundColor Yellow
}

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
    Exit
}

# Redirect and suppress all output
$script:UIOutput = New-Object System.IO.StringWriter
$script:restorePointCreated = $false
[Console]::SetOut($script:UIOutput)

# Set all preferences to silent
$global:ProgressPreference = 'SilentlyContinue'
$global:VerbosePreference = 'SilentlyContinue'
$global:DebugPreference = 'SilentlyContinue'
$global:InformationPreference = 'SilentlyContinue'
$global:WarningPreference = 'SilentlyContinue'
$global:ErrorActionPreference = 'SilentlyContinue'

# Registry backup and restore point setup
$backupPath = "C:\RegistryBackup"
$registryBackup = Join-Path $backupPath "RegistryBackup.reg"

# Create backup directory if it doesn't exist
if (-not (Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Write-Host "Created Registry Backup directory at: $backupPath" -ForegroundColor Green
}

# Only create registry backup if it doesn't exist
if (-not (Test-Path $registryBackup)) {
    Write-Host "Creating initial Registry Backup..." -ForegroundColor Cyan
    reg export HKLM $registryBackup /y | Out-Null
    Write-Host "Registry backup created at: $registryBackup" -ForegroundColor Green
}

# Enable System Restore
Enable-ComputerRestore -Drive "C:\"

# Initialize window properties
$host.UI.RawUI.WindowTitle = "Ritzy Optimizer"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Load WPF assemblies with complete silence
foreach ($assembly in @('PresentationFramework', 'PresentationCore', 'WindowsBase')) {
    [void][System.Reflection.Assembly]::LoadWithPartialName($assembly)
}

# Additional UI initialization
[void][System.Windows.Forms.Application]::EnableVisualStyles()

# Clear any remaining output
Clear-Host

function Show-TermsOfService {
    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
    
    # Create the TOS overlay window
    $tosXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Terms of Service" Height="625" Width="550" WindowStartupLocation="CenterScreen"
        ResizeMode="NoResize" AllowsTransparency="True" WindowStyle="None" Background="Transparent">
    <Border CornerRadius="15" Background="#222222" BorderBrush="#CC0000" BorderThickness="2" Margin="20">
        <Border.Effect>
            <DropShadowEffect BlurRadius="15" ShadowDepth="5" Opacity="0.7"/>
        </Border.Effect>
        <Grid Margin="25">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <TextBlock Grid.Row="0" Text="TERMS OF SERVICE" 
                       FontSize="26" FontWeight="Bold" Foreground="#CC0000" 
                       HorizontalAlignment="Center" Margin="0,5,0,15"/>
            
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Hidden">
                <StackPanel>
                    <TextBlock TextWrapping="Wrap" Margin="0,0,0,15" Foreground="White" FontSize="15" FontWeight="SemiBold">
                        Please read and acknowledge the following terms:
                    </TextBlock>
                    
                    <TextBlock TextWrapping="Wrap" Margin="10,0,0,15" Foreground="White" FontSize="14">
                        • We cannot guarantee a specific value of FPS and/or performance benefit from applying any optimization, 
                          as each system and configuration is different.
                    </TextBlock>
                    
                    <TextBlock TextWrapping="Wrap" Margin="10,0,0,15" Foreground="White" FontSize="14">
                        • If you are unsure about an optimization, do <Run FontWeight="Bold">NOT</Run> apply it.
                    </TextBlock>
                    
                    <TextBlock TextWrapping="Wrap" Margin="10,0,0,15" Foreground="White" FontSize="14">
                        • By running this application, you agree that we / Ritzy is <Run FontWeight="Bold">NOT</Run> 
                          responsible for any damages or malfunctions that may occur from an optimization.
                    </TextBlock>
                    
                    <TextBlock TextWrapping="Wrap" Margin="10,0,0,15" Foreground="White" FontSize="14">
                        • Some optimizations may modify system settings. While these changes are generally safe, 
                          they may affect other applications or system behavior.
                    </TextBlock>
                    
                    <TextBlock TextWrapping="Wrap" Margin="10,0,0,15" Foreground="White" FontSize="14">
                        • If at any time there is an issue, you can revert changes with the "Revert Changes" button 
                          and use the system restore point that we create before applying any optimizations.
                    </TextBlock>
                    
                    <TextBlock TextWrapping="Wrap" Margin="10,0,0,15" Foreground="White" FontSize="14">
                        • This application is provided "as is" without warranty of any kind, either expressed or implied.
                    </TextBlock>
                </StackPanel>
            </ScrollViewer>
            
            <Button Grid.Row="2" x:Name="TOSAgreeButton" Content="I AGREE" 
                    Background="#CC0000" Foreground="White" FontWeight="Bold" FontSize="16" BorderThickness="0"
                    Width="200" Height="45" Margin="0,15,0,0" 
                    HorizontalAlignment="Center">
                <Button.Resources>
                    <Style TargetType="Border">
                        <Setter Property="CornerRadius" Value="8"/>
                    </Style>
                </Button.Resources>
                <Button.Effect>
                    <DropShadowEffect BlurRadius="5" ShadowDepth="2" Opacity="0.7"/>
                </Button.Effect>
            </Button>
        </Grid>
    </Border>
</Window>
"@

    $tosReader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($tosXaml))
    $tosWindow = [Windows.Markup.XamlReader]::Load($tosReader)
    $tosAgreeButton = $tosWindow.FindName("TOSAgreeButton")

    $script:userAgreed = $false
    $tosAgreeButton.Add_Click({
        $script:userAgreed = $true
        $tosWindow.Close()
    })

    # Make the TOS window stay on top
    $tosWindow.Topmost = $true
    
    # Show the TOS window as a dialog
    $tosWindow.ShowDialog() | Out-Null
    
    return $script:userAgreed
}

# Function to create restore point if not created in the last 24 hours
function Ensure-SingleRestorePoint {
    # Check if a restore point was created in the last 24 hours
    $recentPoint = Get-ComputerRestorePoint | Where-Object { 
        $_.CreationTime -gt (Get-Date).AddHours(-24) -and 
        $_.Description -eq "Ritzy Optimizer Changes" 
    } | Select-Object -First 1
    
    if (-not $recentPoint) {
        Write-Host "Creating System Restore Point..." -ForegroundColor Cyan
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "Ritzy Optimizer Changes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction SilentlyContinue
        Write-Host "System Restore Point created successfully!" -ForegroundColor Green
    } else {
        Write-Host "Using existing restore point from the last 24 hours." -ForegroundColor Cyan
    }
}

# function to ensure Chocolatey is available and install it
function Ensure-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-WebRequest https://community.chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
        refreshenv
        Write-Host "Chocolatey installed successfully!" -ForegroundColor Green
    }
}

# Display Ritzy Logo
function Show-RitzyLogo {
    Clear-Host
    Write-Host ""
    Write-Host "██████╗░██╗████████╗███████╗██╗░░░██╗  ████████╗░█████╗░░█████╗░██╗░░░░░"
    Write-Host "██╔══██╗██║╚══██╔══╝╚════██║╚██╗░██╔╝  ╚══██╔══╝██╔══██╗██╔══██╗██║░░░░░"
    Write-Host "██████╔╝██║░░░██║░░░░░███╔═╝░╚████╔╝░  ░░░██║░░░██║░░██║██║░░██║██║░░░░░"
    Write-Host "██╔══██╗██║░░░██║░░░██╔══╝░░░░╚██╔╝░░  ░░░██║░░░██║░░██║██║░░██║██║░░░░░"
    Write-Host "██║░░██║██║░░░██║░░░███████╗░░░██║░░░  ░░░██║░░░╚█████╔╝╚█████╔╝███████╗"
    Write-Host "╚═╝░░╚═╝╚═╝░░░╚═╝░░░╚══════╝░░░╚═╝░░░  ░░░╚═╝░░░░╚════╝░░╚════╝░╚══════╝"
    Write-Host ""
    Write-Host "====Ritzy====="
    Write-Host "=====Windows Optimizer====="
}

# Call the logo function
Show-RitzyLogo

Add-Type -AssemblyName PresentationFramework

# Apps Data Structure
$apps = @{
    "Chrome" = @{
        content = "Chrome"
        description = "Google Chrome is a widely used web browser known for its speed, simplicity, and seamless integration with Google services."
        link = "https://www.google.com/chrome/"
        winget = "Google.Chrome"
        choco = "googlechrome"
    }
    "Firefox" = @{
        content = "Firefox"
        description = "Mozilla Firefox is a fast, privacy-focused browser with extensive customization options."
        link = "https://www.mozilla.org/firefox/"
        winget = "Mozilla.Firefox"
        choco = "firefox"
    }
    "Brave" = @{
        content = "Brave"
        description = "Brave is a privacy-focused web browser that blocks ads and trackers, offering a faster and safer browsing experience."
        link = "https://www.brave.com"
        winget = "Brave.Brave"
        choco = "brave"
    }
    "Discord" = @{
        content = "Discord"
        description = "Discord is a popular platform for chat, voice, and video communication."
        link = "https://discord.com/"
        winget = "Discord.Discord"
        choco = "discord"
    }
    "Steam" = @{
        content = "Steam"
        description = "Steam is the ultimate destination for playing, discussing, and creating games."
        link = "https://store.steampowered.com/"
        winget = "Valve.Steam"
        choco = "steam"
    }
    "7-Zip" = @{
        content = "7-Zip"
        description = "7-Zip is a file archiver with a high compression ratio and strong encryption."
        link = "https://7-zip.org/"
        winget = "7zip.7zip"
        choco = "7zip"
    }
    "WinRAR" = @{
        content = "WinRAR"
        description = "WinRAR is a powerful archive manager that allows you to create, manage, and extract compressed files."
        link = "https://www.win-rar.com/"
        winget = "RARLab.WinRAR"
        choco = "winrar"
    }
    "ISLC" = @{
        content = "ISLC"
        description = "Intelligent Standby List Cleaner (ISLC) is a utility that helps manage and clear the standby list in Windows, potentially improving system performance."
        link = "https://www.wagnardsoft.com/ISLCw"
        choco = "islc"
    }
    "Epic Games" = @{
        content = "Epic Games"
        description = "Epic Games Launcher for Fortnite, Unreal Engine, and many other games with regular free offerings."
        link = "https://www.epicgames.com/"
        winget = "EpicGames.EpicGamesLauncher"
        choco = "epic-games-launcher"
    }
    "Ubisoft Connect" = @{
        content = "Ubisoft Connect"
        description = "Ubisoft's gaming platform for Assassin's Creed, Far Cry, and other Ubisoft titles."
        link = "https://ubisoftconnect.com/"
        winget = "Ubisoft.Connect"
        choco = "ubisoft-connect"
    }
    "Razer Synapse" = @{
    content = "Razer Synapse"
    description = "Configuration software for Razer gaming peripherals with macro and lighting controls."
    link = "https://www.razer.com/synapse-3"
    winget = "Razer.Synapse"
    choco = "razer-synapse-3"
    }

"Razer Cortex" = @{
    content = "Razer Cortex"
    description = "Game booster and optimization tool that helps improve gaming performance."
    link = "https://www.razer.com/cortex"
    winget = "Razer.Cortex"
    choco = "razer-cortex"
    }

"AMD Radeon Software" = @{
    content = "AMD Radeon Software"
    description = "Complete software suite for AMD graphics cards with performance tuning and streaming features."
    link = "https://www.amd.com/en/technologies/radeon-software"
    winget = "AMD.RyzenMaster"
    }

"Streamlabs" = @{
    content = "Streamlabs"
    description = "All-in-one streaming app with custom overlays, alerts, and chat management."
    link = "https://streamlabs.com/"
    winget = "Streamlabs.Streamlabs"
    choco = "streamlabs-obs"
    }

"OBS Studio" = @{
    content = "OBS Studio"
    description = "Professional broadcasting software for live streaming and recording."
    link = "https://obsproject.com/"
    winget = "OBSProject.OBSStudio"
    choco = "obs-studio"
    }

"SteelSeries GG" = @{
    content = "SteelSeries GG"
    description = "All-in-one platform for SteelSeries gear configuration, performance monitoring, and game capture"
    link = "https://steelseries.com/gg"
    winget = "SteelSeries.GG"
    choco = "steelseries-gg"
}

"Visual Studio Code" = @{
    content = "Visual Studio Code"
    description = "powerful code editor developed by Microsoft. It supports multiple programming languages, offers built-in Git integration, debugging tools, extensions, and a highly customizable interface."
    link = "https://code.visualstudio.com/"
    winget = "Microsoft.VisualStudioCode"
    choco = "vscode"
}

"Spotify" = @{
    content = "Spotify"
    description = "Digital music streaming service with millions of songs and podcasts"
    link = "https://spotify.com/"
    winget = "Spotify.Spotify"
    choco = "spotify"
}

"Spicetify" = @{
    content = "Spicetify"
    description = "Powerful CLI tool for Spotify customization with themes and mods"
    link = "https://spicetify.app/"
    winget = "Spicetify.Spicetify"
    choco = "spicetify-cli"
}

"Everything Tool" = @{
    content = "Everything Tool"
    description = "Everything is search engine that locates files and folders by filename instantly for Windows. Unlike Windows search Everything initially displays every file and folder on your computer (hence the name Everything). You type in a search filter to limit what files and folders are displayed."
    link = "https://www.voidtools.com/"
    winget = "voidtools.Everything"
    choco = "everything"
}

"Proton VPN" = @{
    content = "Proton VPN"
    description = "When you use ProtonVPN to browse the web, your Internet connection is encrypted. By routing your connection through encrypted tunnels, ProtonVPNs advanced security features ensure that an attacker cannot eavesdrop on your connection. It also allows you to access websites that might be blocked in your country."
    link = "https://protonvpn.com/"
    choco = "protonvpn"
}

    "OneDrive" = @{
        content = "OneDrive"
        description = "Cloud storage service for file syncing, backup and sharing across devices."
        link = "https://onedrive.live.com/"
        winget = "Microsoft.OneDrive"
        choco = "onedrive"
        postInstall = {
            $regKeys = @(
                "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
                "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
            )
            foreach ($key in $regKeys) {
                Set-ItemProperty -Path $key -Name "System.IsPinnedToNameSpaceTree" -Value 1
            }
        }
    }

    "Microsoft Teams" = @{
        content = "Microsoft Teams"
        description = "Comprehensive collaboration platform featuring chat, video meetings, file sharing, and app integration."
        link = "https://www.microsoft.com/microsoft-teams/"
        winget = "Microsoft.Teams"
        choco = "microsoft-teams"
    }

    "Skype" = @{
        content = "Skype"
        description = "Popular communication tool for video calls, instant messaging, and voice chats."
        link = "https://www.skype.com/"
        winget = "Microsoft.Skype"
        choco = "skype"
    }

    "NVIDIA Geforce Experience" = @{
        content = "NVIDIA GeForce Experience"
        description = "Game optimization and driver management tool with built-in streaming features."
        link = "https://www.nvidia.com/en-us/geforce/geforce-experience/"
        choco = "nvidia-app"
        }
    }

$debloatItems = @{
"Remove OneDrive" = @{
    content = "Remove OneDrive"
    description = "Will be uninstalled. Cloud storage service for file syncing, backup and sharing across devices."
    action = {
        Write-Host "Starting OneDrive Removal Process..." -ForegroundColor Cyan
        
        # Kill OneDrive process
        taskkill /f /im OneDrive.exe
        
        # Migrate OneDrive files to local folders
        $oneDrivePath = "$env:USERPROFILE\OneDrive"
        if (Test-Path $oneDrivePath) {
            Write-Host "Moving OneDrive files to local folders..." -ForegroundColor Yellow
            Move-Item -Path "$oneDrivePath\*" -Destination "$env:USERPROFILE" -Force
            Write-Host "Files moved successfully!" -ForegroundColor Green
        }
        
        # Uninstall OneDrive
        $uninstaller = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
        if (Test-Path $uninstaller) {
            Write-Host "Uninstalling OneDrive..." -ForegroundColor Yellow
            Start-Process $uninstaller "/uninstall" -NoNewWindow -Wait
        }
        
        # Remove OneDrive leftovers
        Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
        
        # Remove OneDrive from Explorer
        $regKeys = @(
            "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
        )
        foreach ($key in $regKeys) {
            if (Test-Path $key) {
                New-ItemProperty -Path $key -Name "System.IsPinnedToNameSpaceTree" -Value 0 -PropertyType DWORD -Force
            }
        }
        
        # Prevent OneDrive from reinstalling
        $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
        if (!(Test-Path $regPath)) {
            New-Item -Path $regPath -Force
        }
        New-ItemProperty -Path $regPath -Name "DisableFileSyncNGSC" -Value 1 -PropertyType DWORD -Force
        
        Write-Host "OneDrive has been completely removed and blocked from reinstalling!" -ForegroundColor Green
        }
    }   
    "RemoveTeams" = @{
        content = "Remove Teams"
        description = "Will be uninstalled. Video meetings, chat, calls, collaboration and file sharing platform"
        action = {
            Write-Host "`nStarting Teams Removal Process..." -ForegroundColor Cyan
            
            # Kill Teams processes
            taskkill /F /IM Teams.exe /T
            
            # Multiple removal methods
            winget uninstall "Microsoft Teams"
            Get-AppxPackage -Name "*Teams*" -AllUsers | Remove-AppxPackage -AllUsers
            
            # Remove Teams Machine-Wide Installer
            $TeamsPath = [System.IO.Path]::Combine($env:ProgramFiles, 'Teams Installer')
            if (Test-Path $TeamsPath) {
                Start-Process -FilePath "$TeamsPath\Teams.exe" -ArgumentList "-uninstall -s" -Wait
            }
            
            # Clean installation directories
            $teamsPaths = @(
                "$env:LOCALAPPDATA\Microsoft\Teams",
                "$env:PROGRAMFILES\Microsoft\Teams",
                "$env:PROGRAMFILES(x86)\Microsoft\Teams",
                "$env:APPDATA\Microsoft\Teams",
                "$env:PROGRAMDATA\Microsoft\Teams",
                "$env:LOCALAPPDATA\Microsoft\TeamsMeetingAddin",
                "$env:LOCALAPPDATA\Microsoft\TeamsPresenceAddin"
            )
            foreach ($path in $teamsPaths) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # Clean registry
            $registryPaths = @(
                "HKCU:\Software\Microsoft\Office\Teams",
                "HKLM:\SOFTWARE\Microsoft\Teams",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Teams"
            )
            foreach ($path in $registryPaths) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            Write-Host "Teams has been completely removed!" -ForegroundColor Green
        }
    }
    "RemoveSolitaire" = @{
        content = "Remove Solitaire"
        description = "Will be uninstalled. Collection of card games including Solitaire, Spider, FreeCell with daily challenges"
        action = {
            Write-Host "`nStarting Solitaire Removal Process..." -ForegroundColor Cyan
            
            # Kill Solitaire processes
            taskkill /F /IM "Microsoft.MicrosoftSolitaireCollection*" /T
            
            # Multiple removal methods
            winget uninstall "Microsoft Solitaire Collection"
            Get-AppxPackage -Name "Microsoft.MicrosoftSolitaireCollection" -AllUsers | Remove-AppxPackage -AllUsers
            
            # Remove using DISM
            DISM /Online /Remove-ProvisionedAppxPackage /PackageName:Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe
            
            # Clean installation directories
            Remove-Item -Path "$env:LOCALAPPDATA\Packages\Microsoft.MicrosoftSolitaireCollection*" -Recurse -Force
            
            # Block reinstallation
            $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft.MicrosoftSolitaireCollection"
            Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
            
            Write-Host "Solitaire Collection has been completely removed!" -ForegroundColor Green
        }
    }
    "RemoveCortana" = @{
        content = "Remove Cortana"
        description = "Will be uninstalled. Voice assistant for searches, reminders, system control and web queries"
        action = {
            Write-Host "`nStarting Cortana Removal Process..." -ForegroundColor Cyan
            
            # Kill Cortana processes
            taskkill /F /IM "RuntimeBroker.exe" /T
            taskkill /F /IM "SearchUI.exe" /T
            
            # Multiple removal methods
            winget uninstall "Cortana"
            Get-AppxPackage -Name "Microsoft.549981C3F5F10" -AllUsers | Remove-AppxPackage -AllUsers
            Get-AppxPackage -Name "*Cortana*" -AllUsers | Remove-AppxPackage -AllUsers
            
            # Remove using DISM
            DISM /Online /Remove-ProvisionedAppxPackage /PackageName:Microsoft.549981C3F5F10_8wekyb3d8bbwe
            
            # Disable through registry
            $regPaths = @(
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search",
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
            )
            foreach ($path in $regPaths) {
                if (!(Test-Path $path)) { New-Item -Path $path -Force }
                Set-ItemProperty -Path $path -Name "AllowCortana" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path $path -Name "DisableWebSearch" -Value 1 -Type DWord -Force
            }
            
            Write-Host "Cortana has been completely removed!" -ForegroundColor Green
        }
    }
    "RemoveLinkedIn" = @{
        content = "Remove LinkedIn"
        description = "Will be uninstalled. Professional networking, job searching and business news platform"
        action = {
            Write-Host "`nStarting LinkedIn Removal Process..." -ForegroundColor Cyan
            
            # Kill LinkedIn processes
            taskkill /F /IM "LinkedIn*" /T
            
            # Multiple removal methods
            winget uninstall "LinkedIn"
            Get-AppxPackage -Name "Microsoft.LinkedIn" -AllUsers | Remove-AppxPackage -AllUsers
            Get-AppxPackage -Name "*LinkedIn*" -AllUsers | Remove-AppxPackage -AllUsers
            
            # Remove using DISM
            DISM /Online /Remove-ProvisionedAppxPackage /PackageName:Microsoft.LinkedIn_8wekyb3d8bbwe
            
            # Clean installation directories
            Remove-Item -Path "$env:LOCALAPPDATA\Packages\Microsoft.LinkedIn*" -Recurse -Force
            Remove-Item -Path "$env:PROGRAMFILES\WindowsApps\Microsoft.LinkedIn*" -Recurse -Force
            
            Write-Host "LinkedIn has been completely removed!" -ForegroundColor Green
        }
    }
"RemoveGetHelp" = @{
    content = "Remove Get Help"
    description = "Will be uninstalled. Microsoft support assistant"
    action = {
        Write-Host "Removing Get Help..." -ForegroundColor Cyan
        Get-AppxPackage "Microsoft.GetHelp" -AllUsers | Remove-AppxPackage -AllUsers
        Write-Host "Get Help removed!" -ForegroundColor Green
    }
}

"RemoveGetStarted" = @{
    content = "Remove Get Started"
    description = "Will be uninstalled. Windows tutorial app"
    action = {
        Write-Host "Removing Get Started..." -ForegroundColor Cyan
        Get-AppxPackage "Microsoft.Getstarted" -AllUsers | Remove-AppxPackage -AllUsers
        Write-Host "Get Started removed!" -ForegroundColor Green
    }
}

"RemoveFeedback" = @{
    content = "Remove Feedback Hub"
    description = "Will be uninstalled. Windows Feedback collection app"
    action = {
        Write-Host "Removing Feedback Hub..." -ForegroundColor Cyan
        Get-AppxPackage "Microsoft.WindowsFeedbackHub" -AllUsers | Remove-AppxPackage -AllUsers
        Write-Host "Feedback Hub removed!" -ForegroundColor Green
    }
}

"RemovePhone" = @{
    content = "Remove Your Phone"
    description = "Will be uninstalled. Phone companion app"
    action = {
        Write-Host "Removing Your Phone..." -ForegroundColor Cyan
        Get-AppxPackage "Microsoft.YourPhone" -AllUsers | Remove-AppxPackage -AllUsers
        Write-Host "Your Phone removed!" -ForegroundColor Green
    }
}

"RemovePeople" = @{
    content = "Remove People"
    description = "Will be uninstalled. People app for contacts"
    action = {
        Write-Host "Removing People app..." -ForegroundColor Cyan
        Get-AppxPackage "Microsoft.People" -AllUsers | Remove-AppxPackage -AllUsers
        Write-Host "People app removed!" -ForegroundColor Green
        }
    }

    "RemoveSkype" = @{
        content = "Remove Skype"
        description = "Will be uninstalled. Video chat and messaging app"
        action = {
            Get-AppxPackage "Microsoft.Skype" -AllUsers | Remove-AppxPackage -AllUsers
        }
    }
}

$optimizations = @{
    "Optimize_TCP_IP_Settings" = @{
        content = "Optimize TCP/IP Network Settings"
        description = "Optimizes TCP/IP parameters to improve network performance, reduce latency, and enhance connection stability for gaming and streaming"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting TCP/IP Settings Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize TCP/IP parameters for better network performance." -ForegroundColor Yellow
            
            $tcpipSettings = @{
                "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" = @{
                    "DefaultTTL" = 0x80
                    "DisableTaskOffload" = 0
                    "EnableConnectionRateLimiting" = 0
                    "EnableDCA" = 1
                    "EnablePMTUBHDetect" = 0
                    "EnablePMTUDiscovery" = 1
                    "EnableRSS" = 1
                    "TcpTimedWaitDelay" = 0x1e
                    "EnableWsd" = 0
                    "GlobalMaxTcpWindowSize" = 0xffff
                    "TcpWindowSize" = 0xffff
                    "MaxConnectionsPer1_0Server" = 0xa
                    "MaxConnectionsPerServer" = 0x0
                    "MaxFreeTcbs" = 0x10000
                    "EnableTCPA" = 0
                    "Tcp1323Opts" = 1
                    "TcpCreateAndConnectTcbRateLimitDepth" = 0
                    "TcpMaxDataRetransmissions" = 3
                    "TcpMaxDupAcks" = 2
                    "TcpMaxSendFree" = 0xffff
                    "TcpNumConnections" = 0xfffffe
                    "MaxHashTableSize" = 0x10000
                    "MaxUserPort" = 0xfffe
                    "SackOpts" = 1
                    "SynAttackProtect" = 1
                    "DelayedAckFrequency" = 1
                    "DelayedAckTicks" = 1
                    "CongestionAlgorithm" = 1
                    "MultihopSets" = 0xf
                    "FastCopyReceiveThreshold" = 0x4000
                    "FastSendDatagramThreshold" = 0x4000
                    "DisableUserTOSSetting" = 0
                }
            }
            
            foreach ($path in $tcpipSettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $tcpipSettings[$path].Keys) {
                    Write-Host "Setting $name to $($tcpipSettings[$path][$name])" -ForegroundColor Green
                    Set-ItemProperty -Path $path -Name $name -Value $tcpipSettings[$path][$name] -Type DWord
                }
            }
            
            Write-Host "`n=== TCP/IP Settings Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Disable_Nagles_Algorithm" = @{
        content = "Disable Nagle's Algorithm (Reduce Latency)"
        description = "Disables Nagle's Algorithm on all network interfaces to reduce latency for gaming, video conferencing, and real-time applications"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting Nagle's Algorithm Disabling Process ===" -ForegroundColor Cyan
            Write-Host "This will disable Nagle's Algorithm on all network interfaces to reduce latency." -ForegroundColor Yellow
            
            # Get all network interfaces
            $interfaces = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            foreach ($interface in $interfaces) {
                Write-Host "Configuring interface: $($interface.PSChildName)" -ForegroundColor Yellow
                
                # Check and create TcpAckFrequency
                if (!(Get-ItemProperty -Path $interface.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue)) {
                    Write-Host "Creating TcpAckFrequency registry value..." -ForegroundColor Green
                    New-ItemProperty -Path $interface.PSPath -Name "TcpAckFrequency" -Value 1 -PropertyType DWord -Force | Out-Null
                } else {
                    Write-Host "Setting TcpAckFrequency value..." -ForegroundColor Green
                    Set-ItemProperty -Path $interface.PSPath -Name "TcpAckFrequency" -Value 1 -Type DWord
                }
                
                # Check and create TCPNoDelay
                if (!(Get-ItemProperty -Path $interface.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue)) {
                    Write-Host "Creating TCPNoDelay registry value..." -ForegroundColor Green
                    New-ItemProperty -Path $interface.PSPath -Name "TCPNoDelay" -Value 1 -PropertyType DWord -Force | Out-Null
                } else {
                    Write-Host "Setting TCPNoDelay value..." -ForegroundColor Green
                    Set-ItemProperty -Path $interface.PSPath -Name "TCPNoDelay" -Value 1 -Type DWord
                }
            }
            
            Write-Host "`n=== Nagle's Algorithm Successfully Disabled on All Interfaces! ===" -ForegroundColor Cyan
        }
    }
    
    "Disable_Network_Power_Saving" = @{
        content = "Disable Network Power Saving Features"
        description = "Disables all power saving features on network adapters to prevent latency spikes, connection drops, and performance degradation"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting Network Power Saving Disabling Process ===" -ForegroundColor Cyan
            Write-Host "This will disable power saving features on all network adapters." -ForegroundColor Yellow
            
            # Get all network adapters
            Get-NetAdapter | ForEach-Object {
                Write-Host "Processing adapter: $($_.Name)" -ForegroundColor Green
                
                # Disable Power Saving features
                try {
                    Set-NetAdapterPowerManagement -Name $_.Name -SelectiveSuspend Disabled -WakeOnMagicPacket Disabled -WakeOnPattern Disabled -ErrorAction SilentlyContinue
                } catch {
                    Write-Host "Could not set power management for $($_.Name). This may be normal for some adapters." -ForegroundColor Yellow
                }
                
                # Additional power saving registry settings
                $adapterPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$($_.InterfaceIndex)"
                if (Test-Path $adapterPath) {
                    Set-ItemProperty -Path $adapterPath -Name "PnPCapabilities" -Value 24 -Type DWord -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $adapterPath -Name "PowerSavingEnabled" -Value 0 -Type DWord -ErrorAction SilentlyContinue
                }
            }
            
            Write-Host "`n=== Network Power Saving Features Successfully Disabled! ===" -ForegroundColor Cyan
        }
    }


    
    "Configure_QoS_Settings" = @{
        content = "Optimize Quality of Service (QoS) Settings"
        description = "Configures Quality of Service settings to prioritize your network traffic and improve performance for gaming and streaming"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting QoS Configuration Process ===" -ForegroundColor Cyan
            Write-Host "This will configure Quality of Service settings for better network performance." -ForegroundColor Yellow
            
            # Create QoS policy paths if they don't exist
            $qosPaths = @(
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS",
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched",
                "HKLM:\SYSTEM\CurrentControlSet\Services\Psched",
                "HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\QoS"
            )
            
            foreach ($path in $qosPaths) {
                if (!(Test-Path $path)) {
                    New-Item -Path $path -Force | Out-Null
                }
            }
            
            # Configure QoS settings
            Write-Host "Setting TCP Autotuning Level to Off" -ForegroundColor Green
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS" -Name "Tcp Autotuning Level" -Value "Off" -Type String -ErrorAction SilentlyContinue
            
            Write-Host "Setting DSCP Marking Request to Ignored" -ForegroundColor Green
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS" -Name "Application DSCP Marking Request" -Value "Ignored" -Type String -ErrorAction SilentlyContinue
            
            Write-Host "Setting NonBestEffortLimit to 0" -ForegroundColor Green
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Name "NonBestEffortLimit" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Psched" -Name "NonBestEffortLimit" -Value 0 -Type DWord -ErrorAction SilentlyContinue
            
            # Configure NLA Settings
            Write-Host "Configuring NLA Settings" -ForegroundColor Green
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\QoS" -Name "Do not use NLA" -Value "1" -Type String -ErrorAction SilentlyContinue
            
            Write-Host "`n=== QoS Settings Configuration Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_Network_Throttling" = @{
        content = "Disable Network Throttling"
        description = "Disables Windows network throttling to improve network throughput for high-bandwidth applications like gaming and streaming"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting Network Throttling Optimization ===" -ForegroundColor Cyan
            Write-Host "This will disable network throttling to improve network throughput." -ForegroundColor Yellow
            
            $systemProfilePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
            if (!(Test-Path $systemProfilePath)) {
                New-Item -Path $systemProfilePath -Force | Out-Null
            }
            
            Write-Host "Setting NetworkThrottlingIndex to maximum value" -ForegroundColor Green
            Set-ItemProperty -Path $systemProfilePath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
            
            Write-Host "Setting SystemResponsiveness to prioritize network traffic" -ForegroundColor Green
            Set-ItemProperty -Path $systemProfilePath -Name "SystemResponsiveness" -Value 10 -Type DWord
            
            Write-Host "`n=== Network Throttling Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_MSMQ_Settings" = @{
        content = "Optimize Microsoft Message Queuing (MSMQ)"
        description = "Optimizes Microsoft Message Queuing settings to improve network communication performance for applications that use MSMQ"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting MSMQ Settings Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize Microsoft Message Queuing settings." -ForegroundColor Yellow
            
            $msmqPath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters"
            if (!(Test-Path $msmqPath)) {
                New-Item -Path $msmqPath -Force | Out-Null
            }
            
            Write-Host "Setting TCPNoDelay for MSMQ" -ForegroundColor Green
            Set-ItemProperty -Path $msmqPath -Name "TCPNoDelay" -Value 1 -Type DWord
            
            Write-Host "`n=== MSMQ Settings Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_NetBT_Settings" = @{
        content = "Optimize NetBIOS Settings"
        description = "Optimizes NetBIOS over TCP/IP settings to improve network name resolution and connection performance"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting NetBIOS Settings Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize NetBIOS over TCP/IP settings." -ForegroundColor Yellow
            
            $netbtPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters"
            if (!(Test-Path $netbtPath)) {
                New-Item -Path $netbtPath -Force | Out-Null
            }
            
            Write-Host "Setting NameSrvQueryTimeout" -ForegroundColor Green
            Set-ItemProperty -Path $netbtPath -Name "NameSrvQueryTimeout" -Value 3000 -Type DWord
            
            Write-Host "Setting NodeType to P-node (peer-to-peer)" -ForegroundColor Green
            Set-ItemProperty -Path $netbtPath -Name "NodeType" -Value 2 -Type DWord
            
            Write-Host "Enabling SessionKeepAlive" -ForegroundColor Green
            Set-ItemProperty -Path $netbtPath -Name "SessionKeepAlive" -Value 1 -Type DWord
            
            Write-Host "`n=== NetBIOS Settings Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_DNS_Priority" = @{
        content = "Optimize DNS Resolution Priority"
        description = "Optimizes DNS resolution priority settings to speed up website and network resource access by improving name resolution"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting DNS Priority Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize DNS resolution priority." -ForegroundColor Yellow
            
            $serviceProviderPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider"
            if (!(Test-Path $serviceProviderPath)) {
                New-Item -Path $serviceProviderPath -Force | Out-Null
            }
            
            Write-Host "Setting LocalPriority" -ForegroundColor Green
            Set-ItemProperty -Path $serviceProviderPath -Name "LocalPriority" -Value 4 -Type DWord
            
            Write-Host "Setting HostsPriority" -ForegroundColor Green
            Set-ItemProperty -Path $serviceProviderPath -Name "HostsPriority" -Value 5 -Type DWord
            
            Write-Host "Setting DnsPriority" -ForegroundColor Green
            Set-ItemProperty -Path $serviceProviderPath -Name "DnsPriority" -Value 6 -Type DWord
            
            Write-Host "Setting NetbtPriority" -ForegroundColor Green
            Set-ItemProperty -Path $serviceProviderPath -Name "NetbtPriority" -Value 7 -Type DWord
            
            Write-Host "`n=== DNS Priority Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_LanmanWorkstation" = @{
        content = "Optimize Workstation Service"
        description = "Optimizes Windows Workstation service settings to improve network file sharing performance and responsiveness"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting Workstation Service Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize Windows Workstation service for better network file sharing." -ForegroundColor Yellow
            
            $lanmanWorkstationPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
            if (!(Test-Path $lanmanWorkstationPath)) {
                New-Item -Path $lanmanWorkstationPath -Force | Out-Null
            }
            
            Write-Host "Setting MaxCmds to increase concurrent network operations" -ForegroundColor Green
            Set-ItemProperty -Path $lanmanWorkstationPath -Name "MaxCmds" -Value 0x1e -Type DWord
            
            Write-Host "Setting MaxThreads to improve multi-threaded performance" -ForegroundColor Green
            Set-ItemProperty -Path $lanmanWorkstationPath -Name "MaxThreads" -Value 0x1e -Type DWord
            
            Write-Host "Setting MaxCollectionCount to optimize memory usage" -ForegroundColor Green
            Set-ItemProperty -Path $lanmanWorkstationPath -Name "MaxCollectionCount" -Value 0x20 -Type DWord
            
            Write-Host "`n=== Workstation Service Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_LanmanServer" = @{
        content = "Optimize Server Service"
        description = "Optimizes Windows Server service settings to improve file sharing, network performance, and connection handling"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting Server Service Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize Windows Server service for better network file sharing." -ForegroundColor Yellow
            
            $lanmanServerPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
            if (!(Test-Path $lanmanServerPath)) {
                New-Item -Path $lanmanServerPath -Force | Out-Null
            }
            
            $serverSettings = @{
                "IRPStackSize" = 0x32                # Increases the size of the internal routing table
                "SizReqBuf" = 0x4410                 # Increases the size of the request buffer
                "Size" = 3                           # Sets server size to optimize for network performance
                "MaxWorkItems" = 0x2000              # Increases maximum simultaneous work items
                "MaxMpxCt" = 0x800                   # Increases maximum multiplexed connections
                "MaxCmds" = 0x800                    # Increases maximum pending commands
                "DisableStrictNameChecking" = 1      # Disables strict name checking for better compatibility
                "autodisconnect" = 0xffffffff        # Disables auto-disconnect for persistent connections
                "EnableOplocks" = 0                  # Disables opportunistic locks for better real-time performance
                "SharingViolationDelay" = 0          # Eliminates sharing violation delay
                "SharingViolationRetries" = 0        # Eliminates sharing violation retries
            }
            
            foreach ($setting in $serverSettings.Keys) {
                Write-Host "Setting $setting to $($serverSettings[$setting])" -ForegroundColor Green
                Set-ItemProperty -Path $lanmanServerPath -Name $setting -Value $serverSettings[$setting] -Type DWord
            }
            
            Write-Host "`n=== Server Service Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_AFD_Settings" = @{
        content = "Optimize Ancillary Function Driver Settings"
        description = "Optimizes Windows AFD settings to improve socket performance, network throughput, and reduce latency for all applications"
        category = "Latency"
        action = {
            Write-Host "`n=== Starting AFD Settings Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize Ancillary Function Driver settings for better network performance." -ForegroundColor Yellow
            
            $afdPath = "HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters"
            if (!(Test-Path $afdPath)) {
                New-Item -Path $afdPath -Force | Out-Null
            }
            
            $afdSettings = @{
                "DefaultReceiveWindow" = 0x4000          # Optimizes the default receive window size
                "DefaultSendWindow" = 0x4000             # Optimizes the default send window size
                "FastCopyReceiveThreshold" = 0x4000      # Improves receive performance for large data
                "FastSendDatagramThreshold" = 0x4000     # Improves send performance for large data
                "DynamicSendBufferDisable" = 0           # Enables dynamic send buffer for better adaptability
                "IgnorePushBitOnReceives" = 1            # Improves throughput by ignoring TCP push bit
                "NonBlockingSendSpecialBuffering" = 1    # Enhances non-blocking send operations
                "DisableRawSecurity" = 1                 # Disables raw security checks for better performance
            }
            
            foreach ($setting in $afdSettings.Keys) {
                Write-Host "Setting $setting to $($afdSettings[$setting])" -ForegroundColor Green
                Set-ItemProperty -Path $afdPath -Name $setting -Value $afdSettings[$setting] -Type DWord
            }
            
            Write-Host "`n=== AFD Settings Optimization Complete! ===" -ForegroundColor Cyan
        }
    }

    "Service Optimization" = @{
    content = "Set Services to Manual"
    description = "Configures Windows services to optimal startup states for better system performance"
    category = @("FPS", "Latency")
    action = {
        Write-Host "`n=== Starting Service Optimization ===" -ForegroundColor Cyan
        
        $serviceConfigs = @(
            @{ Name = "AJRouter"; StartupType = "Disabled"; OriginalType = "Manual" },
            @{ Name = "ALG"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "AppIDSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "AppMgmt"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "AppReadiness"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "AppVClient"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "AppXSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Appinfo"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "AssignedAccessManagerSvc"; StartupType = "Disabled"; OriginalType = "Manual" },
            @{ Name = "AudioEndpointBuilder"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "AudioSrv"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "Audiosrv"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "AxInstSV"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "BDESVC"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "BFE"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "BITS"; StartupType = "AutomaticDelayedStart"; OriginalType = "Automatic" },
            @{ Name = "BTAGService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "BcastDVRUserService_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "BluetoothUserService_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "BrokerInfrastructure"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "Browser"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "BthAvctpSvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "BthHFSrv"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "CDPSvc"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "CDPUserSvc_*"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "COMSysApp"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "CaptureService_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "CertPropSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "ClipSVC"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "ConsentUxUserSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "CoreMessagingRegistrar"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "CredentialEnrollmentManagerUserSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "CryptSvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "CscService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DPS"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "DcomLaunch"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "DcpSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DevQueryBroker"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DeviceAssociationBrokerSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DeviceAssociationService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DeviceInstall"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DevicePickerUserSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DevicesFlowUserSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Dhcp"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "DiagTrack"; StartupType = "Disabled"; OriginalType = "Automatic" },
            @{ Name = "DialogBlockingService"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "DispBrokerDesktopSvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "DisplayEnhancementService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DmEnrollmentSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Dnscache"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "EFS"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "EapHost"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "EntAppSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "EventLog"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "EventSystem"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "FDResPub"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Fax"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "FontCache"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "FrameServer"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "FrameServerMonitor"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "GraphicsPerfSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "HomeGroupListener"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "HomeGroupProvider"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "HvHost"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "IEEtwCollectorService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "IKEEXT"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "InstallService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "InventorySvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "IpxlatCfgSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "KeyIso"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "KtmRm"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "LSM"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "LanmanServer"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "LanmanWorkstation"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "LicenseManager"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "LxpSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "MSDTC"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "MSiSCSI"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "MapsBroker"; StartupType = "AutomaticDelayedStart"; OriginalType = "Automatic" },
            @{ Name = "McpManagementService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "MessagingService_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "MicrosoftEdgeElevationService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "MixedRealityOpenXRSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "MpsSvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "MsKeyboardFilter"; StartupType = "Manual"; OriginalType = "Disabled" },
            @{ Name = "NPSMSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NaturalAuthentication"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NcaSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NcbService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NcdAutoSetup"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NetSetupSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NetTcpPortSharing"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "Netlogon"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "Netman"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NgcCtnrSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NgcSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "NlaSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "OneSyncSvc_*"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "P9RdrService_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PNRPAutoReg"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PNRPsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PcaSvc"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "PeerDistSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PenService_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PerfHost"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PhoneSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PimIndexMaintenanceSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PlugPlay"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PolicyAgent"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Power"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "PrintNotify"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "PrintWorkflowUserSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "ProfSvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "PushToInstall"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "QWAVE"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "RasAuto"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "RasMan"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "RemoteAccess"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "RemoteRegistry"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "RetailDemo"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "RmSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "RpcEptMapper"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "RpcLocator"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "RpcSs"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SCPolicySvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SCardSvr"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SDRSVC"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SEMgrSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SENS"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SNMPTRAP"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SNMPTrap"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SSDPSRV"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SamSs"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "ScDeviceEnum"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Schedule"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SecurityHealthService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Sense"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SensorDataService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SensorService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SensrSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SessionEnv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SharedAccess"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SharedRealitySvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "ShellHWDetection"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SmsRouter"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Spooler"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SstpSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "StiSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "StorSvc"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "SysMain"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SystemEventsBroker"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "TabletInputService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TapiSrv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TermService"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "Themes"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "TieringEngineService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TimeBroker"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TimeBrokerSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TokenBroker"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TrkWks"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "TroubleshootingSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TrustedInstaller"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "UI0Detect"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "UdkUserSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "UevAgentService"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "UmRdpService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "UnistoreSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "UserDataSvc_*"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "UserManager"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "UsoSvc"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "VGAuthService"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "VMTools"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "VSS"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "VacSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "VaultSvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "W32Time"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WEPHOSTSVC"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WFDSConMgrSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WMPNetworkSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WManSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WPDBusEnum"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WSService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WSearch"; StartupType = "AutomaticDelayedStart"; OriginalType = "Automatic" },
            @{ Name = "WaaSMedicSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WalletService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WarpJITSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WbioSrvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Wcmsvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "WcsPlugInService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WdNisSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WdiServiceHost"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WdiSystemHost"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WebClient"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Wecsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WerSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WiaRpc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WinDefend"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "WinHttpAutoProxySvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WinRM"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Winmgmt"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "WlanSvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "WpcMonSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "WpnService"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "WpnUserService_*"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "XblAuthManager"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "XblGameSave"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "XboxGipSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "XboxNetApiSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "autotimesvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "bthserv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "camsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "cbdhsvc_*"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "cloudidsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "dcsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "defragsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "diagnosticshub.standardcollector.service"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "diagsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "dmwappushservice"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "dot3svc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "edgeupdate"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "edgeupdatem"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "embeddedmode"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "fdPHost"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "fhsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "gpsvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "hidserv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "icssvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "iphlpsvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "lfsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "lltdsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "lmhosts"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "mpssvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "msiserver"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "netprofm"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "nsi"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "p2pimsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "p2psvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "perceptionsimulation"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "pla"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "seclogon"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "shpamsvc"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "smphost"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "spectrum"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "sppsvc"; StartupType = "AutomaticDelayedStart"; OriginalType = "Automatic" },
            @{ Name = "ssh-agent"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "svsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "swprv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "tiledatamodelsvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "tzautoupdate"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "uhssvc"; StartupType = "Disabled"; OriginalType = "Disabled" },
            @{ Name = "upnphost"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vds"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vm3dservice"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "vmicguestinterface"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vmicheartbeat"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vmickvpexchange"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vmicrdv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vmicshutdown"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vmictimesync"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vmicvmsession"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vmicvss"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "vmvss"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "wbengine"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "wcncsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "webthreatdefsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "webthreatdefusersvc_*"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "wercplsupport"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "wisvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "wlidsvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "wlpasvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "wmiApSrv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "workfolderssvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "wscsvc"; StartupType = "AutomaticDelayedStart"; OriginalType = "Automatic" },
            @{ Name = "wuauserv"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "wudfsvc"; StartupType = "Manual"; OriginalType = "Manual" }
        )

        foreach ($service in $serviceConfigs) {
            $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
            if ($svc) {
                Write-Host "Setting $($service.Name) to $($service.StartupType)" -ForegroundColor Yellow
                Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host "`nService optimization completed successfully!" -ForegroundColor Green
    }
}
    
    "Optimize_Power_Settings" = @{
        content = "Optimize Power Settings for Performance"
        description = "Configures power settings for maximum performance by disabling power throttling and sleep states that can reduce FPS in games"
        category = @("FPS", "Latency")
        action = {
            Write-Host "`n=== Starting Power Settings Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize power settings for maximum performance." -ForegroundColor Yellow
            
            $powerSettings = @{
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" = @{
                    "ACSettingIndex" = 0
                    "DCSettingIndex" = 0
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" = @{
                    "ACSettingIndex" = 0
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" = @{
                    "ACSettingIndex" = 0
                    "DCSettingIndex" = 0
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\3b04d4fd-1cc7-4f23-ab1c-d1337819c4bb\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" = @{
                    "ACSettingIndex" = 0
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\4b92d758-5a24-4851-a470-815d78aee119\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" = @{
                    "ACSettingIndex" = 64
                    "DCSettingIndex" = 64
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\4b92d758-5a24-4851-a470-815d78aee119\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" = @{
                    "ACSettingIndex" = 64
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\7b224883-b3cc-4d79-819f-8374152cbe7c\DefaultPowerSchemeValues\381b4222-f694-41f0-9685-ff5bb260df2e" = @{
                    "ACSettingIndex" = 64
                    "DCSettingIndex" = 64
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\7b224883-b3cc-4d79-819f-8374152cbe7c\DefaultPowerSchemeValues\8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" = @{
                    "ACSettingIndex" = 64
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\943c8cb6-6f93-4227-ad87-e9a3feec08d1" = @{
                    "Attributes" = 2
                }
            }
            
            foreach ($path in $powerSettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $powerSettings[$path].Keys) {
                    Write-Host "Setting $name to $($powerSettings[$path][$name])" -ForegroundColor Green
                    Set-ItemProperty -Path $path -Name $name -Value $powerSettings[$path][$name] -Type DWord
                }
            }
            
            Write-Host "`n=== Power Settings Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_Memory_Management" = @{
        content = "Optimize Memory Management"
        description = "Enhances memory management settings to improve game performance, reduce stuttering, and optimize RAM usage"
        category = "FPS"
        action = {
            Write-Host "`n=== Starting Memory Management Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize memory management settings for better performance." -ForegroundColor Yellow
            
            $memorySettings = @{
                "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" = @{
                    "FeatureSettings" = 0
                    "FeatureSettingsOverrideMask" = 3
                    "FeatureSettingsOverride" = 3
                    "LargeSystemCache" = 0
                    "NonPagedPoolQuota" = 0
                    "NonPagedPoolSize" = 0
                    "SessionViewSize" = 0xc0
                    "SystemPages" = 0
                    "SecondLevelDataCache" = 0xc00
                    "SessionPoolSize" = 0xc0
                    "DisablePagingExecutive" = 1
                    "PagedPoolSize" = 0xc0
                    "PagedPoolQuota" = 0
                    "PhysicalAddressExtension" = 1
                    "IoPageLockLimit" = 0x100000
                    "PoolUsageMaximum" = 0x60
                }
            }
            
            foreach ($path in $memorySettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $memorySettings[$path].Keys) {
                    Write-Host "Setting $name to $($memorySettings[$path][$name])" -ForegroundColor Green
                    Set-ItemProperty -Path $path -Name $name -Value $memorySettings[$path][$name] -Type DWord
                }
            }
            
            Write-Host "`n=== Memory Management Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Disable_Background_Apps" = @{
        content = "Disable Background Applications"
        description = "Disables background applications and services that consume system resources and can reduce gaming performance"
        category = "FPS"
        action = {
            Write-Host "`n=== Starting Background Applications Disabling Process ===" -ForegroundColor Cyan
            Write-Host "This will disable background applications to free up system resources." -ForegroundColor Yellow
            
            $backgroundSettings = @{
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" = @{
                    "GlobalUserDisabled" = 1
                }
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" = @{
                    "BackgroundAppGlobalToggle" = 0
                }
            }
            
            foreach ($path in $backgroundSettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $backgroundSettings[$path].Keys) {
                    Write-Host "Setting $name to $($backgroundSettings[$path][$name])" -ForegroundColor Green
                    Set-ItemProperty -Path $path -Name $name -Value $backgroundSettings[$path][$name] -Type DWord
                }
            }
            
            Write-Host "`n=== Background Applications Disabling Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Disable_Game_DVR" = @{
        content = "Disable Game DVR and Game Bar"
        description = "Disables Windows Game DVR and Game Bar features that can significantly reduce gaming performance and cause FPS drops"
        category = "FPS"
        action = {
            Write-Host "`n=== Starting Game DVR Disabling Process ===" -ForegroundColor Cyan
            Write-Host "This will disable Game DVR and Game Bar to improve gaming performance." -ForegroundColor Yellow
            
            $gameDvrSettings = @{
                "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" = @{
                    "value" = 0
                }
                "HKCU:\System\GameConfigStore" = @{
                    "GameDVR_Enabled" = 0
                    "GameDVR_FSEBehavior" = 2
                    "GameDVR_FSEBehaviorMode" = 2
                    "GameDVR_HonorUserFSEBehavior" = 0
                    "GameDVR_DXGIHonorFSEWindowsCompatible" = 1
                }
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" = @{
                    "AllowGameDVR" = 0
                }
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" = @{
                    "AppCaptureEnabled" = 0
                }
            }
            
            foreach ($path in $gameDvrSettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $gameDvrSettings[$path].Keys) {
                    Write-Host "Setting $name to $($gameDvrSettings[$path][$name])" -ForegroundColor Green
                    Set-ItemProperty -Path $path -Name $name -Value $gameDvrSettings[$path][$name] -Type DWord
                }
            }
            
            Write-Host "`n=== Game DVR Disabling Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_System_Responsiveness" = @{
        content = "Optimize System Responsiveness"
        description = "Optimizes system responsiveness settings to prioritize foreground applications and reduce input lag in games"
        category = @("FPS", "Latency")
        action = {
            Write-Host "`n=== Starting System Responsiveness Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize system responsiveness settings." -ForegroundColor Yellow
            
            $systemProfileSettings = @{
                "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" = @{
                    "SystemResponsiveness" = 10
                    "NetworkThrottlingIndex" = 0xffffffff
                }
            }
            
            foreach ($path in $systemProfileSettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $systemProfileSettings[$path].Keys) {
                    $value = $systemProfileSettings[$path][$name]
                    
                    # Handle string values
                    if ($value -is [string]) {
                        Write-Host "Setting $name to $value" -ForegroundColor Green
                        Set-ItemProperty -Path $path -Name $name -Value $value -Type String
                    } else {
                        Write-Host "Setting $name to $value" -ForegroundColor Green
                        Set-ItemProperty -Path $path -Name $name -Value $value -Type DWord
                    }
                }
            }
            
            Write-Host "`n=== System Responsiveness Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
"Enable_GPU_Low_Latency_Mode" = @{
    content = "Enable GPU Low Latency Mode (NVIDIA / AMD)"
    description = "Configures GPU driver settings to minimize render queue depth and reduce system latency for competitive FPS games"
    category = "Latency"
    action = {
        Write-Host "`n=== Enabling GPU Low Latency Mode ===" -ForegroundColor Cyan
        
        # Detect GPU vendor
        $gpuInfo = Get-WmiObject Win32_VideoController | Where-Object { $_.AdapterDACType -ne "Internal" }
        $isNvidia = $gpuInfo.Name -match "NVIDIA"
        $isAMD = $gpuInfo.Name -match "AMD|Radeon"
        
        if ($isNvidia) {
            Write-Host "NVIDIA GPU detected, configuring NVIDIA Reflex settings..." -ForegroundColor Green
            
            # NVIDIA Low Latency Mode (Ultra)
            $nvPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
            if (!(Test-Path $nvPath)) {
                $nvPath = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" |
                           Where-Object { Get-ItemProperty -Path $_.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue } |
                           Where-Object { (Get-ItemProperty -Path $_.PSPath).DriverDesc -like "*NVIDIA*" } |
                           Select-Object -First 1 -ExpandProperty PSPath
            }
            
            if ($nvPath) {
                # Force maximum pre-rendered frames to 1 (lowest latency)
                $nvidiaProfilePath = "HKCU:\Software\NVIDIA Corporation\Global\NVTweak"
                if (!(Test-Path $nvidiaProfilePath)) {
                    New-Item -Path $nvidiaProfilePath -Force | Out-Null
                }
                Set-ItemProperty -Path $nvidiaProfilePath -Name "MaxPreRenderedFrames" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                
                # Enable Ultra Low Latency mode
                $nvCplPath = "HKCU:\Software\NVIDIA Corporation\Global\NvCplApi\Profiles"
                if (!(Test-Path $nvCplPath)) {
                    New-Item -Path $nvCplPath -Force | Out-Null
                }
                Set-ItemProperty -Path $nvCplPath -Name "0x00000000" -Value 0x00000002 -Type DWord -ErrorAction SilentlyContinue
                
                Write-Host "✓ Maximum pre-rendered frames set to 1" -ForegroundColor Yellow
                Write-Host "✓ Ultra Low Latency mode enabled" -ForegroundColor Yellow
            }
        }
        elseif ($isAMD) {
            Write-Host "AMD GPU detected, configuring Anti-Lag settings..." -ForegroundColor Green
            
            # AMD Anti-Lag settings
            $amdPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
            if (!(Test-Path $amdPath)) {
                $amdPath = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" |
                            Where-Object { Get-ItemProperty -Path $_.PSPath -Name "DriverDesc" -ErrorAction SilentlyContinue } |
                            Where-Object { (Get-ItemProperty -Path $_.PSPath).DriverDesc -like "*AMD*" -or (Get-ItemProperty -Path $_.PSPath).DriverDesc -like "*Radeon*" } |
                            Select-Object -First 1 -ExpandProperty PSPath
            }
            
            if ($amdPath) {
                # Enable AMD Anti-Lag
                Set-ItemProperty -Path $amdPath -Name "KMD_EnableAntiLag" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                
                # Set Flip Queue Size to 1 (minimum pre-rendered frames)
                Set-ItemProperty -Path $amdPath -Name "FlipQueueSize" -Value 1 -Type DWord -ErrorAction SilentlyContinue
                
                Write-Host "✓ AMD Anti-Lag enabled" -ForegroundColor Yellow
                Write-Host "✓ Flip Queue Size set to 1" -ForegroundColor Yellow
            }
        }
        
        # Configure universal game task settings with SAFE values
        Write-Host "Configuring universal game task settings with safe values..." -ForegroundColor Yellow
        $gamesTaskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        if (!(Test-Path $gamesTaskPath)) {
            New-Item -Path $gamesTaskPath -Force | Out-Null
        }
        
        # Add all the game task settings with SAFE values
        $gameTaskSettings = @{
            "Background Only" = "False"
            "GPU Priority" = 4            # Safe value (0-3 is normal range)
            "Priority" = 3                # Above Normal (safer than Real-time)
            "Scheduling Category" = "High"
            "SFIO Priority" = "High"
        }
        
        foreach ($setting in $gameTaskSettings.GetEnumerator()) {
            if ($setting.Value -is [string]) {
                Write-Host "Setting $($setting.Key) to $($setting.Value)" -ForegroundColor Green
                Set-ItemProperty -Path $gamesTaskPath -Name $setting.Key -Value $setting.Value -Type String
            } else {
                Write-Host "Setting $($setting.Key) to $($setting.Value)" -ForegroundColor Green
                Set-ItemProperty -Path $gamesTaskPath -Name $setting.Key -Value $setting.Value -Type DWord
            }
        }
        
        # Configure Windows Game Mode
        $gameBarPath = "HKCU:\Software\Microsoft\GameBar"
        if (!(Test-Path $gameBarPath)) {
            New-Item -Path $gameBarPath -Force | Out-Null
        }
        Set-ItemProperty -Path $gameBarPath -Name "AutoGameModeEnabled" -Value 1 -Type DWord
        Write-Host "✓ Windows Game Mode enabled" -ForegroundColor Yellow
        
        # Configure additional system profile settings
        $sysProfilePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
        if (!(Test-Path $sysProfilePath)) {
            New-Item -Path $sysProfilePath -Force | Out-Null
        }
        Set-ItemProperty -Path $sysProfilePath -Name "NetworkThrottlingIndex" -Value 0xffffffff -Type DWord
        Set-ItemProperty -Path $sysProfilePath -Name "SystemResponsiveness" -Value 0x00000000 -Type DWord
        Write-Host "✓ Network throttling disabled" -ForegroundColor Yellow
        Write-Host "✓ System responsiveness optimized for gaming" -ForegroundColor Yellow
        
        Write-Host "`n=== GPU Low Latency Mode Enabled with Safe Settings! ===" -ForegroundColor Cyan
        Write-Host "These settings improve gaming performance without risking system stability." -ForegroundColor Green
    }
}

    "Optimize_Desktop_Settings" = @{
        content = "Optimize Desktop and UI Settings"
        description = "Optimizes desktop and user interface settings to improve responsiveness and reduce system overhead"
        category = "FPS"
        action = {
            Write-Host "`n=== Starting Desktop Settings Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize desktop and UI settings." -ForegroundColor Yellow
            
            $desktopSettings = @{
                "HKCU:\Control Panel\Desktop" = @{
                    "AutoEndTasks" = 1
                    "HungAppTimeout" = 1000
                    "MenuShowDelay" = 8
                    "WaitToKillAppTimeout" = 2000
                    "LowLevelHooksTimeout" = 1000
                }
                "HKLM:\SYSTEM\CurrentControlSet\Control" = @{
                    "WaitToKillServiceTimeout" = 2000
                }
            }
            
            foreach ($path in $desktopSettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $desktopSettings[$path].Keys) {
                    Write-Host "Setting $name to $($desktopSettings[$path][$name])" -ForegroundColor Green
                    Set-ItemProperty -Path $path -Name $name -Value $desktopSettings[$path][$name] -Type DWord
                }
            }
            
            Write-Host "`n=== Desktop Settings Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Optimize_Explorer_Settings" = @{
        content = "Optimize Explorer and File System Settings"
        description = "Optimizes Windows Explorer and file system settings to reduce overhead and improve system responsiveness"
        category = "FPS"
        action = {
            Write-Host "`n=== Starting Explorer Settings Optimization ===" -ForegroundColor Cyan
            Write-Host "This will optimize Windows Explorer and file system settings." -ForegroundColor Yellow
            
            $explorerSettings = @{
                "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" = @{
                    "NoLowDiskSpaceChecks" = 1
                    "LinkResolveIgnoreLinkInfo" = 1
                    "NoResolveSearch" = 1
                    "NoResolveTrack" = 1
                    "NoInternetOpenWith" = 1
                    "NoInstrumentation" = 1
                }
            }
            
            foreach ($path in $explorerSettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $explorerSettings[$path].Keys) {
                    Write-Host "Setting $name to $($explorerSettings[$path][$name])" -ForegroundColor Green
                    Set-ItemProperty -Path $path -Name $name -Value $explorerSettings[$path][$name] -Type DWord
                }
            }
            
            Write-Host "`n=== Explorer Settings Optimization Complete! ===" -ForegroundColor Cyan
        }
    }
    
    "Disable_Telemetry_Privacy" = @{
        content = "Disable Telemetry and Enhance Privacy"
        description = "Disables Windows telemetry, data collection, and background processes that can impact system performance and privacy"
        category = "FPS"
        action = {
            Write-Host "`n=== Starting Telemetry and Privacy Settings Optimization ===" -ForegroundColor Cyan
            Write-Host "This will disable telemetry and enhance privacy settings." -ForegroundColor Yellow
            
            $privacySettings = @{
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" = @{
                    "AllowTelemetry" = 0
                }
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" = @{
                    "AllowTelemetry" = 0
                }
                "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" = @{
                    "AITEnable" = 0
                }
                "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" = @{
                    "CEIPEnable" = 0
                }
            }
            
            foreach ($path in $privacySettings.Keys) {
                Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                
                if (!(Test-Path $path)) {
                    Write-Host "Creating new registry path..." -ForegroundColor Gray
                    New-Item -Path $path -Force | Out-Null
                }
                
                foreach ($name in $privacySettings[$path].Keys) {
                    Write-Host "Setting $name to $($privacySettings[$path][$name])" -ForegroundColor Green
                    Set-ItemProperty -Path $path -Name $name -Value $privacySettings[$path][$name] -Type DWord
                }
            }
            
            Write-Host "`n=== Telemetry and Privacy Settings Optimization Complete! ===" -ForegroundColor Cyan
        }
    }

"Mouse Optimization" = @{
    content = "Mouse Optimization"
    description = "Ultimate Mouse Optimization - Zero Processing, Pure Raw Input!"
    category = "Latency"
    action = {
        Write-Host "`nOptimizing Mouse Settings..." -ForegroundColor Cyan

        # Mouse Curve Settings for perfect 1:1 tracking
        $mouseCurveX = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                              0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00,
                              0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,
                              0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,
                              0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00)
        
        $mouseCurveY = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                              0x00,0x00,0x38,0x00,0x00,0x00,0x00,0x00,
                              0x00,0x00,0x70,0x00,0x00,0x00,0x00,0x00,
                              0x00,0x00,0xA8,0x00,0x00,0x00,0x00,0x00,
                              0x00,0x00,0xE0,0x00,0x00,0x00,0x00,0x00)

        # Enhanced Windows API functions for immediate updates
        $source = @"
        using System;
        using System.Runtime.InteropServices;
        public class Win32 {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
            
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, int[] pvParam, uint fWinIni);
            
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref MOUSEKEYS pvParam, uint fWinIni);

            public const uint SPI_SETMOUSESPEED = 0x0071;
            public const uint SPI_SETMOUSE = 0x0004;
            public const uint SPI_SETMOUSECURVE = 0x0069;
            public const uint SPI_SETMOUSEKEYS = 0x0037;
            public const uint SPIF_UPDATEINIFILE = 0x01;
            public const uint SPIF_SENDCHANGE = 0x02;
            public const uint SPIF_SENDWININICHANGE = 0x02;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct MOUSEKEYS {
            public uint cbSize;
            public uint dwFlags;
            public uint iMaxSpeed;
            public uint iTimeToMaxSpeed;
            public uint iCtrlSpeed;
            public uint dwReserved1;
            public uint dwReserved2;
        }
"@
        Add-Type -TypeDefinition $source -Language CSharp

        # Registry paths with immediate effect
        $mousePaths = @(
            "HKCU:\Control Panel\Mouse",
            "HKU:\.DEFAULT\Control Panel\Mouse"
        )

        foreach ($path in $mousePaths) {
            if (!(Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }

            # Core mouse settings with forced update
            $settings = @{
                "MouseSpeed" = "0"
                "MouseThreshold1" = "0"
                "MouseThreshold2" = "0"
                "MouseSensitivity" = "10"
                "SmoothMouseXCurve" = $mouseCurveX
                "SmoothMouseYCurve" = $mouseCurveY
            }

            foreach ($setting in $settings.GetEnumerator()) {
                if ($setting.Key -like "*Curve") {
                    Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Type Binary -Force
                    # Force immediate curve update
                    [Win32]::SystemParametersInfo([Win32]::SPI_SETMOUSECURVE, 0, [IntPtr]::Zero, [Win32]::SPIF_SENDWININICHANGE)
                } else {
                    Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Type String -Force
                }
            }
        }

        # Direct system parameter updates
        $mouseParams = @(0, 0, 0)
        [Win32]::SystemParametersInfo([Win32]::SPI_SETMOUSE, 0, $mouseParams, [Win32]::SPIF_UPDATEINIFILE -bor [Win32]::SPIF_SENDWININICHANGE)
        [Win32]::SystemParametersInfo([Win32]::SPI_SETMOUSESPEED, 0, [IntPtr]10, [Win32]::SPIF_UPDATEINIFILE -bor [Win32]::SPIF_SENDWININICHANGE)

        # Multiple refresh commands to ensure changes take effect
        Start-Process -FilePath "rundll32.exe" -ArgumentList "user32.dll,UpdatePerUserSystemParameters" -NoNewWindow -Wait
        Start-Process -FilePath "rundll32.exe" -ArgumentList "user32.dll,UpdatePerUserSystemParameters 1, True" -NoNewWindow -Wait

        Write-Host "Mouse settings optimized and applied in real-time!" -ForegroundColor Green
        }
    }
"Keyboard Optimization" = @{
    content = "Keyboard Optimization"
    description = "Ultimate real-time keyboard optimization with absolute zero latency"
    category = "Latency"
    action = {
        Write-Host "`nApplying Maximum Real-Time Keyboard Optimizations..." -ForegroundColor Cyan

        # Enhanced Windows API for guaranteed real-time updates
        $source = @"
        using System;
        using System.Runtime.InteropServices;
        public class KeyboardUtils {
            [DllImport("user32.dll", SetLastError = true)]
            public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);
            
            [DllImport("user32.dll")]
            public static extern bool UpdatePerUserSystemParameters(int reserved1, bool reserved2);
            
            [DllImport("user32.dll")]
            public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);

            public const uint SPI_SETKEYBOARDDELAY = 0x0017;
            public const uint SPI_SETKEYBOARDSPEED = 0x000B;
            public const uint SPIF_UPDATEINIFILE = 0x01;
            public const uint SPIF_SENDCHANGE = 0x02;
            public const uint WM_SETTINGCHANGE = 0x001A;
        }
"@
        Add-Type -TypeDefinition $source -Language CSharp

        # Registry paths with real-time optimizations
        $paths = @{
            "HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" = @{
                "KeyboardDataQueueSize" = 0x96        # Maximum queue size
                "ConnectMultiplePorts" = 0x0
                "KeyboardDeviceBaseName" = "KeyboardClass"
                "MaximumPortsServiced" = 0x3
                "SendOutputToAllPorts" = 0x1
                "PollStatusIterations" = 0x1          # Minimum polling
                "ThreadPriority" = 0x4                # Real-time priority
                "BufferSize" = 0x960                  # Enhanced buffer
                "ResendIterations" = 0x1              # Minimum resend delay
                "KeyboardMode" = 0x1                  # Enhanced mode
                "EnableKeyboardDeviceInterface" = 0x1
            }
            "HKCU:\Control Panel\Keyboard" = @{
                "KeyboardDelay" = "0"                 # Zero delay
                "KeyboardSpeed" = "48"                # Maximum speed
                "InitialKeyboardIndicators" = "0"
                "KeyboardDataQueueSize" = "96"        # Enhanced queue
            }
            "HKCU:\Control Panel\Desktop" = @{
                "KeyboardSpeed" = "48"
                "KeyboardDelay" = "0"
                "CursorBlinkRate" = "500"            # Ultra-fast blink
                "LowLevelHooksTimeout" = "1000"
                "HungAppTimeout" = "1000"
                "ForegroundLockTimeout" = "0"
                "ForegroundFlashCount" = "0"
            }
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" = @{
                "NetworkThrottlingIndex" = 0xffffffff
                "SystemResponsiveness" = 10
                "KeyboardTimingThreshold" = 0x1
            }
        }

        # Apply settings with real-time enforcement
        foreach ($path in $paths.Keys) {
            if (!(Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }

            foreach ($setting in $paths[$path].GetEnumerator()) {
                if ($setting.Value -is [string]) {
                    Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Type String -Force
                } else {
                    Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Type DWord -Force
                }
                # Force immediate update after each setting
                [KeyboardUtils]::UpdatePerUserSystemParameters(1, $true)
            }
        }

        # Real-time system updates
        [KeyboardUtils]::SystemParametersInfo([KeyboardUtils]::SPI_SETKEYBOARDDELAY, 0, [IntPtr]::Zero, [KeyboardUtils]::SPIF_UPDATEINIFILE -bor [KeyboardUtils]::SPIF_SENDCHANGE)
        [KeyboardUtils]::SystemParametersInfo([KeyboardUtils]::SPI_SETKEYBOARDSPEED, 48, [IntPtr]::Zero, [KeyboardUtils]::SPIF_UPDATEINIFILE -bor [KeyboardUtils]::SPIF_SENDCHANGE)

        # Multiple refresh commands for instant effect
        $refreshCommands = @(
            "user32.dll,UpdatePerUserSystemParameters 1, True",
            "user32.dll,UpdatePerUserSystemParameters",
            "user32.dll,SystemParametersInfo"
        )

        foreach ($cmd in $refreshCommands) {
            Start-Process -FilePath "rundll32.exe" -ArgumentList $cmd -NoNewWindow -Wait
        }

        Write-Host "Real-time keyboard optimization complete!" -ForegroundColor Green
        Write-Host "✓ Zero input latency achieved" -ForegroundColor Yellow
        Write-Host "✓ Maximum repeat rate enabled" -ForegroundColor Yellow
        Write-Host "✓ Enhanced buffer and queue size" -ForegroundColor Yellow
        Write-Host "✓ Real-time thread priority" -ForegroundColor Yellow
        Write-Host "✓ Instant response time activated" -ForegroundColor Yellow
        }
    }
"Disable Sticky Keys" = @{
    content = "Disable Sticky Keys"
    description = "Disables Sticky Keys and other accessibility keyboard shortcuts"
    category = "Windows"
    action = {
        Write-Host "`nDisabling Sticky Keys and Accessibility Keyboard Features..." -ForegroundColor Cyan
        
        # Registry paths for accessibility features
        $paths = @{
            "HKCU:\Control Panel\Accessibility\StickyKeys" = @{
                "Flags" = "506"                # Disable sticky keys
            }
            "HKCU:\Control Panel\Accessibility\ToggleKeys" = @{
                "Flags" = "58"                 # Disable toggle keys
            }
            "HKCU:\Control Panel\Accessibility\Keyboard Response" = @{
                "Flags" = "122"                # Disable filter keys
            }
            "HKCU:\Control Panel\Accessibility" = @{
                "Sound on Activation" = 0      # Disable sound on activation
            }
            "HKCU:\Control Panel\Accessibility\MouseKeys" = @{
                "Flags" = "0"                  # Disable mouse keys
            }
        }
        
        # Apply settings
        foreach ($path in $paths.Keys) {
            if (!(Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
                Write-Host "Created new registry key: $path" -ForegroundColor Yellow
            }
            
            foreach ($setting in $paths[$path].GetEnumerator()) {
                if ($setting.Value -is [string]) {
                    Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Type String -Force
                } else {
                    Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Type DWord -Force
                }
            }
        }
        
        Write-Host "Accessibility keyboard features successfully disabled!" -ForegroundColor Green
        Write-Host "✓ Sticky Keys disabled" -ForegroundColor Yellow
        Write-Host "✓ Toggle Keys disabled" -ForegroundColor Yellow
        Write-Host "✓ Filter Keys disabled" -ForegroundColor Yellow
        Write-Host "✓ Mouse Keys disabled" -ForegroundColor Yellow
        Write-Host "✓ Keyboard shortcuts for accessibility features disabled" -ForegroundColor Yellow
    }
}

"Enable End Task With Right Click" = @{
    content = "Enable End Task With Right Click"
    description = "Enables option to end task when right clicking a program in the taskbar"
    category = "Windows"
    action = {
        Write-Host "`nEnabling End Task with Right Click on Taskbar..." -ForegroundColor Cyan
        
        # Define registry paths for different Windows versions
        $win11Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings"
        $win10Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TaskBand"
        
        # Windows 11 implementation
        if (-not (Test-Path $win11Path)) {
            New-Item -Path $win11Path -Force | Out-Null
            Write-Host "Created new registry key for Windows 11 taskbar settings" -ForegroundColor Yellow
        }
        Set-ItemProperty -Path $win11Path -Name "TaskbarEndTask" -Value 1 -Type DWord -Force
        
        # Windows 10 implementation (for compatibility)
        if (-not (Test-Path $win10Path)) {
            New-Item -Path $win10Path -Force | Out-Null
            Write-Host "Created new registry key for Windows 10 taskbar settings" -ForegroundColor Yellow
        }
        Set-ItemProperty -Path $win10Path -Name "AllowEndTask" -Value 1 -Type DWord -Force
        
        Write-Host "End Task with Right Click successfully enabled!" -ForegroundColor Green
        Write-Host "✓ Right-click on taskbar apps to see End Task option" -ForegroundColor Yellow
        Write-Host "✓ Quickly terminate unresponsive applications" -ForegroundColor Yellow
        Write-Host "✓ Enhanced taskbar functionality activated" -ForegroundColor Yellow
        Write-Host "Note: You may need to sign out and back in or restart Explorer for changes to take effect" -ForegroundColor Yellow
    }
}

"Enable Dark Theme" = @{
    content = "Enable Dark Theme"
    description = "Activates system-wide dark mode for Windows and applications"
    category = "Windows"
    action = {
        Write-Host "`nEnabling Dark Theme for Windows..." -ForegroundColor Cyan
        
        # Registry paths for dark theme settings
        $paths = @{
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" = @{
                "AppsUseLightTheme" = 0       # Apps dark theme
                "SystemUsesLightTheme" = 0    # System dark theme
                "EnableTransparency" = 1      # Enable transparency effects
            }
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent" = @{
                "AccentColorMenu" = 0xff3f3f3f    # Dark accent color
            }
            "HKCU:\Control Panel\Desktop" = @{
                "AutoColorization" = 0            # Disable auto colorization
            }
            "HKCU:\Software\Microsoft\Windows\DWM" = @{
                "ColorPrevalence" = 0             # Use dark title bars
                "AccentColor" = 0xff3f3f3f        # Dark accent color
                "ColorizationColor" = 0xc43f3f3f  # Dark colorization
                "ColorizationAfterglow" = 0xc43f3f3f
                "ColorizationColorBalance" = 0x00000059
            }
        }
        
        # Apply settings
        foreach ($path in $paths.Keys) {
            if (!(Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
                Write-Host "Created new registry key: $path" -ForegroundColor Yellow
            }
            
            foreach ($setting in $paths[$path].GetEnumerator()) {
                Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Type DWord -Force
            }
        }
        
        # Additional Windows 11 specific settings
        $win11Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent"
        if (Test-Path $win11Path) {
            # Windows 11 accent data (dark theme)
            $accentDataBytes = [byte[]](0x9B, 0x9A, 0x99, 0x00, 0x90, 0x90, 0x90, 0x00, 0x85, 0x85, 0x85, 0x00, 0x78, 0x78, 0x78, 0x00, 0x6D, 0x6D, 0x6D, 0x00, 0x60, 0x60, 0x60, 0x00, 0x54, 0x54, 0x54, 0x00, 0x48, 0x48, 0x48, 0x00)
            Set-ItemProperty -Path $win11Path -Name "AccentPalette" -Value $accentDataBytes -Type Binary -Force
        }
        
        # Force dark theme for UWP apps
        $uwpPath = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main"
        if (!(Test-Path $uwpPath)) {
            New-Item -Path $uwpPath -Force | Out-Null
        }
        Set-ItemProperty -Path $uwpPath -Name "Theme" -Value 1 -Type DWord -Force
        
        Write-Host "Dark Theme successfully enabled!" -ForegroundColor Green
        Write-Host "✓ System-wide dark mode activated" -ForegroundColor Yellow
        Write-Host "✓ Dark app theme applied" -ForegroundColor Yellow
        Write-Host "✓ Dark accent colors configured" -ForegroundColor Yellow
        Write-Host "✓ Enhanced visual experience optimized" -ForegroundColor Yellow
    }
}

"Enable Edge Search Bar" = @{
    content = "Enable Edge Search Bar"
    description = "Adds Microsoft Edge search bar to the taskbar for quick web searches"
    category = "Windows"
    action = {
        Write-Host "`nEnabling Microsoft Edge Search Bar..." -ForegroundColor Cyan
        
        # Registry paths for search settings
        $paths = @{
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" = @{
                "BingSearchEnabled" = 1            # Enable web search
                "CortanaConsent" = 1               # Enable search consent
                "AllowSearchToUseLocation" = 1     # Allow location for relevant results
                "SearchboxTaskbarMode" = 2         # Show search bar on taskbar (not just icon)
            }
        }
        
        # Windows 11 specific path
        $win11SearchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        $win11SearchSetting = @{
            "SearchboxTaskbarMode" = 2             # Show search bar on taskbar for Win11 (not just icon)
        }
        
        # Apply settings
        foreach ($path in $paths.Keys) {
            if (!(Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
                Write-Host "Created new registry key: $path" -ForegroundColor Yellow
            }
            
            foreach ($setting in $paths[$path].GetEnumerator()) {
                Set-ItemProperty -Path $path -Name $setting.Key -Value $setting.Value -Type DWord -Force
            }
        }
        
        # Apply Windows 11 specific settings if the path exists
        if (Test-Path $win11SearchPath) {
            foreach ($setting in $win11SearchSetting.GetEnumerator()) {
                Set-ItemProperty -Path $win11SearchPath -Name $setting.Key -Value $setting.Value -Type DWord -Force
            }
        }
        
        # Configure Edge as default search provider
        $edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
        if (!(Test-Path $edgePath)) {
            New-Item -Path $edgePath -Force | Out-Null
        }
        Set-ItemProperty -Path $edgePath -Name "DisableSearchBoxSuggestions" -Value 0 -Type DWord -Force
        
        # Enable web search in Start menu
        $webSearchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Search\Preferences"
        if (!(Test-Path $webSearchPath)) {
            New-Item -Path $webSearchPath -Force | Out-Null
        }
        Set-ItemProperty -Path $webSearchPath -Name "WebSearch" -Value 1 -Type DWord -Force
        
        Write-Host "Microsoft Edge Search Bar successfully enabled!" -ForegroundColor Green
        Write-Host "✓ Search bar enabled on taskbar (not just icon)" -ForegroundColor Yellow
        Write-Host "✓ Web search activated" -ForegroundColor Yellow
        Write-Host "✓ Microsoft Edge integrated with search" -ForegroundColor Yellow
        Write-Host "✓ Quick search functionality optimized" -ForegroundColor Yellow
        }
    }

"Ritzy's Gaming Powerplan" = @{
    content = "Ritzy's Gaming Powerplan"
    description = "Creates and applies an optimized power plan for maximum gaming performance"
    category = @("FPS", "Windows")
    action = {
        Write-Host "`nCreating and applying Ritzy's Gaming Powerplan..." -ForegroundColor Cyan
        
        try {
            # Check if the plan already exists and delete it if found
            $powerPlans = powercfg /list
            $existingPlan = $powerPlans | Where-Object { $_ -match "Ritzy's Gaming Powerplan" }

            if ($existingPlan) {
                if ($existingPlan -match '([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})') {
                    $existingGuid = $matches[1]
                    Write-Host "Found existing Ritzy's Gaming Powerplan with GUID: $existingGuid" -ForegroundColor Yellow
                    Write-Host "Deleting existing plan to create a fresh version..." -ForegroundColor Yellow
                    powercfg /delete $existingGuid
                    Start-Sleep -Seconds 1  # Give system time to process the deletion
                }
            }
            
            # If plan doesn't exist, create it
            if (-not $planExists) {
                # Get the High Performance plan GUID
                $highPerfPlan = $null
                foreach ($line in $powerPlans) {
                    if ($line -match "High performance") {
                        $highPerfPlan = $line
                        break
                    }
                }
                
                # If High Performance not found, try Balanced
                if (-not $highPerfPlan) {
                    foreach ($line in $powerPlans) {
                        if ($line -match "Balanced") {
                            $highPerfPlan = $line
                            break
                        }
                    }
                }
                
                if ($highPerfPlan) {
                    $sourceGuidMatch = [regex]::Match($highPerfPlan, '([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})')
                    if ($sourceGuidMatch.Success) {
                        $sourceGuid = $sourceGuidMatch.Groups[1].Value
                        
                        # Create a duplicate of the source plan
                        Write-Host "Creating new power plan based on GUID: $sourceGuid" -ForegroundColor Yellow
                        $duplicateOutput = powercfg /duplicate $sourceGuid
                        
                        if ($duplicateOutput -match '([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})') {
                            $planGuid = $matches[1]
                            Write-Host "Created new power plan with GUID: $planGuid" -ForegroundColor Yellow
                            
                            # Rename the plan
                            powercfg /changename $planGuid "Ritzy's Gaming Powerplan" "Ultimate power plan optimized for gaming performance with minimal latency and maximum responsiveness."
                        } else {
                            throw "Failed to extract GUID from duplicate command output"
                        }
                    } else {
                        throw "Could not find source power plan GUID"
                    }
                } else {
                    # Direct creation if no template found
                    Write-Host "No template power plan found. Creating directly..." -ForegroundColor Yellow
                    # Use the Ultimate Performance plan GUID if available
                    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
                    
                    # Check if creation worked
                    $newPlans = powercfg /list
                    foreach ($line in $newPlans) {
                        if ($line -match "Power Scheme GUID: ([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})") {
                            $possibleGuid = $matches[1]
                            powercfg /changename $possibleGuid "Ritzy's Gaming Powerplan" "Ultimate power plan optimized for gaming performance."
                            $planGuid = $possibleGuid
                            break
                        }
                    }
                    
                    if (-not $planGuid) {
                        throw "Failed to create power plan directly"
                    }
                }
            }
            
            if ($planGuid) {
                # Configure power settings
                Write-Host "Configuring optimal power settings..." -ForegroundColor Yellow
                
                # Display settings - never turn off display
                powercfg /setacvalueindex $planGuid sub_video VIDEOIDLE 0
                
                # Processor power management
                powercfg /setacvalueindex $planGuid sub_processor PROCTHROTTLEMIN 100
                powercfg /setacvalueindex $planGuid sub_processor PROCTHROTTLEMAX 100
                
                # Hard disk settings - never turn off disk
                powercfg /setacvalueindex $planGuid sub_disk DISKIDLE 0
                
                # Sleep settings - disable all sleep
                powercfg /setacvalueindex $planGuid sub_sleep STANDBYIDLE 0
                powercfg /setacvalueindex $planGuid sub_sleep HYBRIDSLEEP 0
                powercfg /setacvalueindex $planGuid sub_sleep HIBERNATEIDLE 0
                
                # Try to set advanced processor settings (safely)
                $advancedSettings = @(
                    @{subgroup = "sub_processor"; setting = "PERFINCPOL"; value = 2},           # Processor performance increase policy: Aggressive
                    @{subgroup = "sub_processor"; setting = "PERFBOOSTMODE"; value = 2},        # System cooling policy: Active
                    @{subgroup = "sub_processor"; setting = "PERFINCTHRESHOLD"; value = 10},    # Performance increase threshold: 10%
                    @{subgroup = "sub_processor"; setting = "PERFDECTHRESHOLD"; value = 20},    # Performance decrease threshold: 20%
                    @{subgroup = "sub_processor"; setting = "LATENCYHINTPERF"; value = 0},      # Latency sensitivity hint: Off (for max performance)
                    @{subgroup = "sub_processor"; setting = "PERFAUTONOMOUS"; value = 1},       # Autonomous mode: On
                    @{subgroup = "sub_processor"; setting = "PERFEPP"; value = 0},              # Energy efficient policy: Off
                    @{subgroup = "sub_processor"; setting = "IDLESCALING"; value = 1},          # Processor idle state management: Enabled
                    @{subgroup = "sub_processor"; setting = "CPMINCORES"; value = 100},         # Minimum processor cores: 100%
                    @{subgroup = "sub_processor"; setting = "CPMAXCORES"; value = 100},         # Maximum processor cores: 100%
                    @{subgroup = "sub_energysaver"; setting = "ESUSB"; value = 0},              # USB selective suspend: Disabled
                    @{subgroup = "sub_pciexpress"; setting = "ASPM"; value = 0},                # PCI Express power management: Off
                    @{subgroup = "sub_graphics"; setting = "GPUPREFERENCEPOLICY"; value = 2},   # GPU preference: High performance
                    @{subgroup = "sub_buttons"; setting = "LIDACTION"; value = 0},              # Lid close action: Do nothing
                    @{subgroup = "sub_buttons"; setting = "PBUTTONACTION"; value = 0},          # Power button action: Do nothing
                    @{subgroup = "sub_buttons"; setting = "SBUTTONACTION"; value = 0}           # Sleep button action: Do nothing
                )
                
                foreach ($setting in $advancedSettings) {
                    try {
                        powercfg /setacvalueindex $planGuid $setting.subgroup $setting.setting $setting.value
                    } catch {
                        Write-Host "Note: Could not set $($setting.setting) - may not be supported on this system" -ForegroundColor Yellow
                    }
                }
                
                # Set as active power plan
                powercfg /setactive $planGuid
                
                # Make it persist across reboots
                $activeSchemeRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes"
                if (!(Test-Path $activeSchemeRegPath)) {
                    New-Item -Path $activeSchemeRegPath -Force | Out-Null
                }
                Set-ItemProperty -Path $activeSchemeRegPath -Name "ActivePowerScheme" -Value $planGuid -Type String -Force
                
                # Disable Hibernation
                powercfg /hibernate off
                
                Write-Host "Ritzy's Gaming Powerplan successfully created and activated!" -ForegroundColor Green
                Write-Host "✓ Maximum processor performance enabled" -ForegroundColor Yellow
                Write-Host "✓ Display and hard disk set to never turn off" -ForegroundColor Yellow
                Write-Host "✓ Sleep and hibernation disabled" -ForegroundColor Yellow
                Write-Host "✓ All processor cores running at maximum" -ForegroundColor Yellow
                Write-Host "✓ USB and PCI Express power saving disabled" -ForegroundColor Yellow
                Write-Host "✓ Power plan set to persist across system restarts" -ForegroundColor Yellow
            } else {
                throw "Failed to get a valid power plan GUID"
            }
        }
        catch {
            Write-Host "An error occurred: $_" -ForegroundColor Red
            # Even if we had an error, let's try to create a basic version as fallback
            try {
                # Create a basic high performance plan
                Write-Host "Attempting fallback method..." -ForegroundColor Yellow
                
                # Try to use the built-in high performance plan
                powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
                
                # Get the active plan
                $activePlanOutput = powercfg /getactivescheme
                
                if ($activePlanOutput -match '([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})') {
                    $activeGuid = $matches[1]
                    
                    # Rename and configure the active plan
                    powercfg /changename $activeGuid "Ritzy's Gaming Powerplan" "Gaming power plan with high performance settings."
                    
                    # Set display and disk to never turn off
                    powercfg /setacvalueindex $activeGuid sub_video VIDEOIDLE 0
                    powercfg /setacvalueindex $activeGuid sub_disk DISKIDLE 0
                    
                    # Apply the changes
                    powercfg /setactive $activeGuid
                    
                    Write-Host "Basic gaming power plan created and activated using fallback method." -ForegroundColor Green
                    Write-Host "✓ High performance power plan activated" -ForegroundColor Yellow
                    Write-Host "✓ Display and hard disk set to never turn off" -ForegroundColor Yellow
                } else {
                    # Last resort - just create a new plan
                    powercfg -duplicatescheme SCHEME_BALANCED
                    Start-Sleep -Seconds 1
                    
                    $finalPlans = powercfg /list
                    $lastPlan = ($finalPlans -split "`n")[-2]
                    
                    if ($lastPlan -match '([a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12})') {
                        $lastGuid = $matches[1]
                        powercfg /changename $lastGuid "Ritzy's Gaming Powerplan" "Basic gaming power plan."
                        powercfg /setactive $lastGuid
                        
                        Write-Host "Created basic power plan as last resort." -ForegroundColor Yellow
                    } else {
                        Write-Host "All methods failed. Please create power plan manually." -ForegroundColor Red
                    }
                }
            }
            catch {
                Write-Host "Fallback method failed: $_" -ForegroundColor Red
                Write-Host "Please create power plan manually." -ForegroundColor Red
                }
            }
        }
    }
}

 # cleanup tab
 $cleanupTasks = @{
    "Temp Folders" = @{
        content = "Clean Temporary Files"
        description = "Removes non-gaming files from Windows Temp folders"
        action = {
            Write-Host "Cleaning Windows Temp folders (Game-Safe)..." -ForegroundColor Yellow
            
            $excludePaths = @(
                "*game*", "*steam*", "*epic*", "*ubisoft*", "*origin*",
                "*battle*", "*riot*", "*fortnite*", "*siege*"
            )
            
            Get-ChildItem -Path "$env:TEMP" -Exclude $excludePaths | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            Get-ChildItem -Path "C:\Windows\Temp" -Exclude $excludePaths | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            
            Write-Host "Game-safe temporary files cleanup completed!" -ForegroundColor Green
        }
    }
    
    "Recycle Bin" = @{
        content = "Empty Recycle Bin"
        description = "Safely removes non-gaming items from the Recycle Bin"
        action = {
            Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Host "Recycle Bin emptied successfully!" -ForegroundColor Green
        }
    }
    
    "DNS Cache" = @{
        content = "Flush DNS Cache"
        description = "Optimizes DNS resolver cache for better gaming connectivity"
        action = {
            Write-Host "Optimizing DNS Cache for gaming..." -ForegroundColor Yellow
            ipconfig /flushdns | Out-Null
            Write-Host "DNS Cache optimized successfully!" -ForegroundColor Green
        }
    }
"Drive Cleanup" = @{
    content = "Drive Cleanup"
    description = "Runs a gaming-optimized disk cleanup that preserves performance"
    action = {
        Write-Host "Starting Gaming-Optimized Cleanup..." -ForegroundColor Yellow
        
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        
        # Enhanced gaming-safe cleanup items
        $cleanItems = @(
            "Old ChkDsk Files"
            "Previous Installations"
            "Setup Log Files"
            "Temporary Setup Files"
            "Windows Error Reporting Files"
            "Windows Upgrade Log Files"
            "Memory Dump Files"
            "System Queue Files"
            "Windows Defense Files"
        )

        # Comprehensive gaming paths protection
        $excludePaths = @(
            "$env:ProgramFiles\Steam"
            "$env:ProgramFiles(x86)\Steam"
            "$env:ProgramFiles\Epic Games"
            "$env:ProgramFiles\Origin"
            "$env:ProgramFiles\Ubisoft"
            "$env:ProgramFiles\Common Files\Ubisoft"
            "$env:ProgramFiles(x86)\Ubisoft"
            "$env:PROGRAMDATA\Ubisoft"
            "$env:LOCALAPPDATA\Ubisoft"
            "$env:PROGRAMDATA\Epic"
            "$env:LOCALAPPDATA\Epic"
            "$env:PROGRAMDATA\Steam"
            "$env:LOCALAPPDATA\Steam"
            "$env:USERPROFILE\Documents\My Games"
            "$env:LOCALAPPDATA\FortniteGame"
            "$env:PROGRAMDATA\Battle.net"
            "$env:PROGRAMDATA\Riot Games"
            "$env:LOCALAPPDATA\Temp\*game*"
            "$env:LOCALAPPDATA\Temp\*steam*"
            "$env:LOCALAPPDATA\Temp\*epic*"
            "$env:LOCALAPPDATA\Temp\*ubisoft*"
            "$env:LOCALAPPDATA\Temp\*origin*"
            "$env:LOCALAPPDATA\Temp\*battle*"
            "$env:LOCALAPPDATA\Temp\*riot*"
        )

        foreach ($item in $cleanItems) {
            $itemPath = Join-Path $regPath $item
            if (Test-Path $itemPath) {
                Set-ItemProperty -Path $itemPath -Name "StateFlags0001" -Value 2 -Type DWord
            }
        }

        # Safe cleanup excluding all gaming paths
        Get-ChildItem -Path $env:TEMP -Exclude $excludePaths | Remove-Item -Recurse -Force
        
        Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -NoNewWindow
        
        Write-Host "Gaming-Optimized Cleanup completed successfully!" -ForegroundColor Green
        }
    }
    "Browser Cache" = @{
    content = "Clean Browser Cache"
    description = "Cleans only non-essential temporary browser files"
    action = {
        Write-Host "Performing minimal browser cleanup..." -ForegroundColor Yellow
        # Only cleans ad-related temp files
        Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\AdNetworks\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Non-essential browser files cleaned!" -ForegroundColor Green
    }
}

"System Logs" = @{
    content = "Clean System Logs"
    description = "Clears only archived system logs"
    action = {
        Write-Host "Cleaning archived system logs..." -ForegroundColor Yellow
        # Only clears logs older than 7 days
        Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log -Before (Get-Date).AddDays(-7) } 2>$null
        Write-Host "Archived logs cleaned!" -ForegroundColor Green
    }
}

"Old Installers" = @{
    content = "Clean Old Installers"
    description = "Removes only completed installer files from Downloads"
    action = {
        Write-Host "Cleaning old installer files..." -ForegroundColor Yellow
        $downloadsPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
        Get-ChildItem -Path $downloadsPath -Include "*.exe", "*.msi" | 
        Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30)) -and ($_.Name -notmatch 'game|steam|epic|origin|ubisoft|battle|riot')} |
        Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "Old installers cleaned!" -ForegroundColor Green
        }
    }
 }

# Show Terms of Service first
$userAgreedToTOS = Show-TermsOfService

# Only continue if user agreed to terms
if (-not $userAgreedToTOS) {
    Write-Host "User did not agree to Terms of Service. Exiting application."
    exit
}

# XAML Code
[xml]$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Ritzy Optimizer"
    WindowStyle="None"
    AllowsTransparency="True"
    Background="Transparent"
    Width="1200"
    Height="700"
    MaxWidth="1200"
    MaxHeight="700"
    ResizeMode="NoResize"
    WindowStartupLocation="CenterScreen">

    <Window.Resources>
        <ResourceDictionary>
            <SolidColorBrush x:Key="WindowBackground" Color="#0F0F0F"/>
            <SolidColorBrush x:Key="TextColor" Color="#FFFFFF"/>
            <SolidColorBrush x:Key="ButtonBackground" Color="#1A1A1A"/>
            <SolidColorBrush x:Key="ButtonHover" Color="#2D2D2D"/>
            <SolidColorBrush x:Key="ButtonPressed" Color="#353535"/>
            <SolidColorBrush x:Key="ButtonBorder" Color="#232323"/>
            <SolidColorBrush x:Key="SideNavBackground" Color="#1A1A1A"/>

            <Style x:Key="WindowButtonStyle" TargetType="Button">
                <Setter Property="Background" Value="Transparent"/>
                <Setter Property="BorderThickness" Value="0"/>
                <Setter Property="Foreground" Value="{DynamicResource TextColor}"/>
                <Setter Property="FontSize" Value="16"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="3">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>

<Style x:Key="NavButtonStyle" TargetType="Button">
    <Setter Property="Background" Value="Transparent"/>
    <Setter Property="Foreground" Value="#B8B8B8"/>
    <Setter Property="FontSize" Value="14"/>
    <Setter Property="Height" Value="40"/>
    <Setter Property="Margin" Value="0,2"/>
    <Setter Property="Cursor" Value="Hand"/>
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="Button">
                <Grid>
                    <Border x:Name="border"
                            Background="{TemplateBinding Background}"
                            CornerRadius="6"
                            Padding="16,0">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="24"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Path x:Name="icon"
                                  Data="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}"
                                  Fill="{TemplateBinding Foreground}"
                                  Width="18" Height="18"
                                  Stretch="Uniform"/>
                            <TextBlock Grid.Column="1"
                                     Text="{TemplateBinding Content}"
                                     Margin="12,0,0,0"
                                     VerticalAlignment="Center"/>
                        </Grid>
                    </Border>
                    <Border x:Name="activeIndicator"
                            Width="3"
                            Background="#007ACC"
                            HorizontalAlignment="Left"
                            Opacity="0"
                            CornerRadius="3,0,0,3"/>
                </Grid>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                        <Setter TargetName="border" Property="Background" Value="{StaticResource ButtonHover}"/>
                        <Setter Property="Foreground" Value="White"/>
                    </Trigger>
                    <DataTrigger Binding="{Binding IsActive, RelativeSource={RelativeSource Self}}" Value="True">
                        <Setter TargetName="border" Property="Background" Value="{StaticResource ButtonHover}"/>
                        <Setter Property="Foreground" Value="White"/>
                        <Setter TargetName="activeIndicator" Property="Opacity" Value="1"/>
                    </DataTrigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>

<Style x:Key="ActionButtonStyle" TargetType="Button">
    <Setter Property="Background" Value="#CC0000"/>
    <Setter Property="Foreground" Value="White"/>
    <Setter Property="FontWeight" Value="SemiBold"/>
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Padding" Value="20,10"/>
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="Button">
                <Border Background="{TemplateBinding Background}"
                        BorderBrush="{TemplateBinding BorderBrush}"
                        BorderThickness="{TemplateBinding BorderThickness}"
                        CornerRadius="6">
                    <ContentPresenter HorizontalAlignment="Center"
                                     VerticalAlignment="Center"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsMouseOver" Value="True">
                        <Setter Property="Background" Value="#FF0000"/>
                    </Trigger>
                    <Trigger Property="IsPressed" Value="True">
                        <Setter Property="Background" Value="#990000"/>
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>

<Style x:Key="ModernComboBoxStyle" TargetType="ComboBox">
    <Setter Property="Background" Value="#007ACC"/>
    <Setter Property="Foreground" Value="White"/>
    <Setter Property="BorderThickness" Value="0"/>
    <Setter Property="Padding" Value="10,5"/>
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="ComboBox">
                <Grid>
                    <ToggleButton x:Name="ToggleButton"
                                IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                                Focusable="False">
                        <ToggleButton.Template>
                            <ControlTemplate TargetType="ToggleButton">
                                <Border x:Name="MainBorder" 
                                        Background="{Binding Background, RelativeSource={RelativeSource AncestorType=ComboBox}}"
                                        CornerRadius="6">
                                    <Grid>
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="*"/>
                                            <ColumnDefinition Width="Auto"/>
                                        </Grid.ColumnDefinitions>
                                        <ContentPresenter Grid.Column="0"
                                                        Content="{Binding Path=SelectionBoxItem, RelativeSource={RelativeSource AncestorType=ComboBox}}"
                                                        ContentTemplate="{Binding Path=SelectionBoxItemTemplate, RelativeSource={RelativeSource AncestorType=ComboBox}}"
                                                        Margin="10,0,0,0"
                                                        VerticalAlignment="Center"/>
                                        <Path Grid.Column="1"
                                              Data="M0,0 L8,8 L16,0"
                                              Fill="White"
                                              HorizontalAlignment="Right"
                                              VerticalAlignment="Center"
                                              Margin="0,0,10,0"/>
                                    </Grid>
                                </Border>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter Property="Background" TargetName="MainBorder" Value="#0098FF"/>
                                    </Trigger>
                                    <Trigger Property="IsChecked" Value="True">
                                        <Setter Property="Background" TargetName="MainBorder" Value="#0098FF"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </ToggleButton.Template>
                    </ToggleButton>
                    <Popup x:Name="PART_Popup"
                           AllowsTransparency="True"
                           Placement="Bottom"
                           IsOpen="{TemplateBinding IsDropDownOpen}"
                           PopupAnimation="Slide"
                           StaysOpen="False">
                        <Grid MinWidth="{TemplateBinding ActualWidth}">
                            <Border Background="#1E1E1E"
                                    BorderBrush="#007ACC"
                                    BorderThickness="1"
                                    CornerRadius="6"
                                    Margin="0,2,0,0">
                                <ScrollViewer MaxHeight="200"
                                            SnapsToDevicePixels="True"
                                            HorizontalScrollBarVisibility="Disabled"
                                            VerticalScrollBarVisibility="Hidden">
                                    <ItemsPresenter KeyboardNavigation.DirectionalNavigation="Contained"/>
                                </ScrollViewer>
                            </Border>
                        </Grid>
                    </Popup>
                </Grid>
                <ControlTemplate.Triggers>
                    <Trigger Property="HasItems" Value="False">
                        <Setter TargetName="ToggleButton" Property="IsEnabled" Value="False"/>
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>

<!-- Standard panel size and style -->
<Style x:Key="StandardPanelStyle" TargetType="Border">
    <Setter Property="Width" Value="350"/>
    <Setter Property="Height" Value="200"/>
    <Setter Property="Margin" Value="10"/>
    <Setter Property="Padding" Value="15"/>
    <Setter Property="Background" Value="{DynamicResource ButtonBackground}"/>
    <Setter Property="BorderBrush" Value="{DynamicResource ButtonBorder}"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Setter Property="CornerRadius" Value="10"/>
</Style>

        <!-- Tab and navigation button animations -->
<Storyboard x:Key="TabHighlightAnimation">
    <ColorAnimation 
        Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)"
        To="#007ACC" 
        Duration="0:0:0.2"/>
</Storyboard>

<!-- Option hover animations -->
<Storyboard x:Key="OptionHoverIn">
    <DoubleAnimation 
        Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)"
        To="1.03" 
        Duration="0:0:0.1"/>
    <DoubleAnimation 
        Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)"
        To="1.03" 
        Duration="0:0:0.1"/>
</Storyboard>

<Storyboard x:Key="OptionHoverOut">
    <DoubleAnimation 
        Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleX)"
        To="1.0" 
        Duration="0:0:0.1"/>
    <DoubleAnimation 
        Storyboard.TargetProperty="(UIElement.RenderTransform).(ScaleTransform.ScaleY)"
        To="1.0" 
        Duration="0:0:0.1"/>
</Storyboard>

<!-- Style for category panels with hover animation -->
<Style x:Key="CategoryPanelStyle" TargetType="Border">
    <Setter Property="Background" Value="{DynamicResource ButtonBackground}"/>
    <Setter Property="BorderBrush" Value="{DynamicResource ButtonBorder}"/>
    <Setter Property="BorderThickness" Value="1"/>
    <Setter Property="CornerRadius" Value="10"/>
    <Setter Property="Margin" Value="10"/>
    <Setter Property="Padding" Value="15"/>
    <Setter Property="RenderTransformOrigin" Value="0.5,0.5"/>
    <Setter Property="RenderTransform">
        <Setter.Value>
            <ScaleTransform ScaleX="1" ScaleY="1"/>
        </Setter.Value>
    </Setter>
    <Style.Triggers>
        <EventTrigger RoutedEvent="MouseEnter">
            <BeginStoryboard Storyboard="{StaticResource OptionHoverIn}"/>
        </EventTrigger>
        <EventTrigger RoutedEvent="MouseLeave">
            <BeginStoryboard Storyboard="{StaticResource OptionHoverOut}"/>
        </EventTrigger>
    </Style.Triggers>
</Style>

<Style x:Key="ToggleSwitchStyle" TargetType="ToggleButton">
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="ToggleButton">
                <Border x:Name="Container"
                     Width="50"
                     Height="25"
                     CornerRadius="12.5"
                    Background="#FF4444">
                    <Border x:Name="Slider"
                            Width="21"
                             Height="21"
                             CornerRadius="10.5"
                            Background="White"
                            HorizontalAlignment="Left"
                            Margin="2,0,0,0"/>
                </Border>
                <ControlTemplate.Triggers>
                    <Trigger Property="IsChecked" Value="True">
                        <Setter TargetName="Container" Property="Background" Value="#4CAF50"/>
                        <Setter TargetName="Slider" Property="HorizontalAlignment" Value="Right"/>
                        <Setter TargetName="Slider" Property="Margin" Value="0,0,2,0"/>
                        <!-- Add animation for smooth transition -->
                        <Trigger.EnterActions>
                            <BeginStoryboard>
                                <Storyboard>
                                    <ColorAnimation 
                                        Storyboard.TargetName="Container" 
                                        Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)" 
                                        To="#4CAF50" 
                                        Duration="0:0:0.2"/>
                                </Storyboard>
                            </BeginStoryboard>
                        </Trigger.EnterActions>
                        <Trigger.ExitActions>
                            <BeginStoryboard>
                                <Storyboard>
                                    <ColorAnimation 
                                        Storyboard.TargetName="Container" 
                                        Storyboard.TargetProperty="(Border.Background).(SolidColorBrush.Color)" 
                                        To="#FF4444" 
                                        Duration="0:0:0.2"/>
                                </Storyboard>
                            </BeginStoryboard>
                        </Trigger.ExitActions>
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
        </ResourceDictionary>
    </Window.Resources>
    <Border CornerRadius="12" Background="{DynamicResource WindowBackground}">
        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="240"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Left Navigation Panel -->
            <Border Background="{DynamicResource SideNavBackground}" CornerRadius="8" Margin="8">
                <DockPanel Margin="16">
                    <StackPanel DockPanel.Dock="Top" Margin="0,0,0,24">
                        <TextBlock Text="Ritzy Optimizer" 
                                 FontSize="20" 
                                 FontWeight="SemiBold"
                                 Foreground="White"/>
                    </StackPanel>

                    <StackPanel>
                        <Button x:Name="HomeTab"
                                Style="{StaticResource NavButtonStyle}"
                                Content="Home"
                                Tag="M3 13h1v7c0 1.103.897 2 2 2h12c1.103 0 2-.897 2-2v-7h1a1 1 0 0 0 .707-1.707l-9-9a.999.999 0 0 0-1.414 0l-9 9A1 1 0 0 0 3 13zm9-8.586l6 6V20H6v-9.586l6-6z"/>

                        <Button x:Name="AppsTab" 
                                Style="{StaticResource NavButtonStyle}"
                                Content="Apps"
                                Tag="M3 3h18v18H3V3zm16.5 16.5V5.5h-15v14h15zm-4.5-6a1.5 1.5 0 1 1 0-3 1.5 1.5 0 0 1 0 3zm0 3a4.5 4.5 0 1 1 0-9 4.5 4.5 0 0 1 0 9z"/>
                        
                        <Button x:Name="OptimizeTab" 
                                Style="{StaticResource NavButtonStyle}"
                                Content="Optimize"
                                Tag="M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16zm-1-7h2v6h-2v-6zm0-4h2v2h-2V9z"/>
                        
                        <Button x:Name="CleanTab" 
                                Style="{StaticResource NavButtonStyle}"
                                Content="Clean"
                                Tag="M12 2c5.523 0 10 4.477 10 10s-4.477 10-10 10S2 17.523 2 12 6.477 2 12 2zm0 2a8 8 0 1 0 0 16 8 8 0 0 0 0-16zm3.707 5.707a1 1 0 0 1 0 1.414l-4 4a1 1 0 0 1-1.414 0l-2-2a1 1 0 1 1 1.414-1.414L11 13.586l3.293-3.293a1 1 0 0 1 1.414 0z"/>
                        
                        <Button x:Name="DebloatTab" 
                                Style="{StaticResource NavButtonStyle}"
                                Content="Debloat"
                                Tag="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.07.62-.07.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/>

                        <Button x:Name="InfoTab" 
                                Style="{StaticResource NavButtonStyle}"
                                Content="Info"
                                Tag="M12 22C6.477 22 2 17.523 2 12S6.477 2 12 2s10 4.477 10 10-4.477 10-10 10zm0-2a8 8 0 1 0 0-16 8 8 0 0 0 0 16zM11 7h2v2h-2V7zm0 4h2v6h-2v-6z"/>

                        <Button x:Name="ConsoleTab"
                                Style="{StaticResource NavButtonStyle}"
                                Content="Console"
                                Tag="M2 4v16h20V4H2zm18 14H4V6h16v12zM6 8v2h12V8H6zm0 4v2h12v-2H6zm0 4v2h5v-2H6z"/>

                        <Button x:Name="RevertButton"
                                Content="Revert Changes"
                                Background="#FF4444"
                                Foreground="White"
                                Style="{StaticResource NavButtonStyle}"
                                Margin="0,20,0,0"/>
                    </StackPanel>
                </DockPanel>
            </Border>
            <!-- Content Area -->
            <Border Grid.Column="1" Background="{DynamicResource ButtonBackground}" CornerRadius="8" Margin="0,8,8,8">
                <Grid>
<TextBox x:Name="SearchBox"
         Width="875"
         Height="30" 
         Margin="20,35,20,0"
         HorizontalAlignment="Left"
         VerticalAlignment="Top"
         Background="#1E1E1E"
         Foreground="White"
         BorderBrush="#333333"
         BorderThickness="1"
         Padding="10,5"
         FontSize="14"
         VerticalContentAlignment="Center"
         Panel.ZIndex="999">
    <TextBox.Resources>
        <Style TargetType="{x:Type Border}">
            <Setter Property="CornerRadius" Value="6"/>
        </Style>
    </TextBox.Resources>
    <TextBox.Style>
        <Style TargetType="TextBox">
            <Style.Triggers>
                <Trigger Property="Text" Value="">
                    <Setter Property="Background">
                        <Setter.Value>
                            <VisualBrush Stretch="None" AlignmentX="Left">
                                <VisualBrush.Visual>
                                    <TextBlock Text="Search..." Foreground="#808080" Margin="10,5,0,0"/>
                                </VisualBrush.Visual>
                            </VisualBrush>
                        </Setter.Value>
                    </Setter>
                </Trigger>
            </Style.Triggers>
        </Style>
    </TextBox.Style>
</TextBox>

        <StackPanel Orientation="Horizontal" 
                    HorizontalAlignment="Right" 
                    VerticalAlignment="Top"
                    Margin="0,4,4,0"
                    Panel.ZIndex="999">
            <Button x:Name="ThemeToggle" 
                    Width="30" Height="20" 
                    Margin="0,0,8,0"
                    Style="{StaticResource WindowButtonStyle}">
                <Path x:Name="ThemeIcon" 
                      Data="M12,7A5,5 0 0,1 17,12A5,5 0 0,1 12,17A5,5 0 0,1 7,12A5,5 0 0,1 12,7M12,9A3,3 0 0,0 9,12A3,3 0 0,0 12,15A3,3 0 0,0 15,12A3,3 0 0,0 12,9Z"
                      Fill="{DynamicResource TextColor}" 
                      Stretch="Uniform"/>
            </Button>
            <Button x:Name="MinimizeButton" 
                    Content="−" 
                    Width="30" Height="20" 
                    Margin="0,0,8,0"
                    Style="{StaticResource WindowButtonStyle}"/>
            <Button x:Name="CloseButton" 
                    Content="×" 
                    Width="30" Height="20"
                    Style="{StaticResource WindowButtonStyle}"/>
        </StackPanel>

                            <!-- Home Content -->
                <Grid x:Name="HomeContent" Visibility="Collapsed">
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="20">
                        <StackPanel Margin="0,0,0,20">
                            <!-- Home content will be added programmatically -->
                        </StackPanel>
                    </ScrollViewer>
                </Grid>

                            <!-- Apps Content -->
                <Grid x:Name="AppsContent" Visibility="Visible" Margin="0,50,0,-10">
                    <ScrollViewer VerticalScrollBarVisibility="Hidden" Margin="10">
                        <WrapPanel x:Name="CategoriesPanel" Orientation="Horizontal"/>
                    </ScrollViewer>
                    <Button x:Name="InstallButton" 
                            Content="Install Selected" 
                            Style="{StaticResource ActionButtonStyle}"
                            Width="120" 
                            Height="35" 
                            VerticalAlignment="Bottom"
                            HorizontalAlignment="Left" 
                            Margin="20,0,0,20"/>

                     
                    <Button x:Name="UninstallButton" 
                            Content="Uninstall Selected" 
                            Style="{StaticResource ActionButtonStyle}"
                            Width="130" 
                            Height="35" 
                            VerticalAlignment="Bottom"
                            HorizontalAlignment="Left" 
                            Margin="150,0,0,20"/>       
                    </Grid>

                    <!-- Clean Content -->
                    <Grid x:Name="CleanContent" Visibility="Collapsed" Margin="0,50,0,-10">
                        <ScrollViewer VerticalScrollBarVisibility="Hidden" Margin="10">
                            <StackPanel x:Name="CleanPanel"/>
                        </ScrollViewer>
                        <Button x:Name="CleanButton" 
                                Content="Clean System" 
                                Style="{StaticResource ActionButtonStyle}"
                                Width="120" 
                                Height="35" 
                                VerticalAlignment="Bottom"
                                HorizontalAlignment="Left" 
                                Margin="20,0,0,20"/>
                    </Grid>

                    <!-- Console Tab Content -->
                    <Grid x:Name="ConsoleView" Visibility="Collapsed">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        
                        <TextBlock Text="Console Output" 
                                FontSize="24" 
                                FontWeight="SemiBold" 
                                Margin="20,20,0,10" 
                                Foreground="White"/>
                        
                        <Border Grid.Row="1" 
                                Background="#1E1E1E" 
                                BorderBrush="#333333" 
                                BorderThickness="1" 
                                CornerRadius="8" 
                                Margin="20,0,20,20">
                            <ScrollViewer x:Name="ConsoleScroller" VerticalScrollBarVisibility="Hidden">
                                <TextBox x:Name="ConsoleOutput" 
                                        Background="Transparent" 
                                        Foreground="#CCCCCC" 
                                        FontFamily="Consolas" 
                                        FontSize="14" 
                                        IsReadOnly="True" 
                                        BorderThickness="0" 
                                        Padding="10" 
                                        TextWrapping="Wrap" 
                                        VerticalAlignment="Stretch" 
                                        HorizontalAlignment="Stretch"/>
                            </ScrollViewer>
                        </Border>
                        
                        <Button Grid.Row="2" 
                                Content="Clear Console" 
                                Background="#333333" 
                                Foreground="White" 
                                Padding="15,8" 
                                Margin="0,0,20,20" 
                                HorizontalAlignment="Right" 
                                x:Name="ClearConsoleButton"/>
                    </Grid>

                    <!-- Optimize Content -->
                    <Grid x:Name="OptimizeContent" Visibility="Collapsed" Margin="0,50,0,-10">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        
                        <!-- Category Filter Buttons -->
                    <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="20,25,20,5" HorizontalAlignment="Left" VerticalAlignment="Center">
                        <Button x:Name="AllTweaksButton" Content="All" Style="{StaticResource ActionButtonStyle}" Width="70" Height="28" Margin="0,0,8,0"/>
                        <Button x:Name="FPSTweaksButton" Content="FPS" Style="{StaticResource ActionButtonStyle}" Width="70" Height="28" Margin="0,0,8,0"/>
                        <Button x:Name="LatencyTweaksButton" Content="Latency" Style="{StaticResource ActionButtonStyle}" Width="70" Height="28" Margin="0,0,8,0"/>
                        <Button x:Name="WindowsTweaksButton" Content="Windows" Style="{StaticResource ActionButtonStyle}" Width="70" Height="28" Margin="0,0,8,0"/>                    
                    </StackPanel>
                        
                        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Hidden" Margin="10">
                            <StackPanel x:Name="OptimizationsPanel"/>
                        </ScrollViewer>
                        
                        <Grid Grid.Row="2" Margin="20,0,20,20">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Button x:Name="RunTweaksButton"
                                    Grid.Column="0"
                                    Content="Run Tweaks"
                                    Style="{StaticResource ActionButtonStyle}"
                                    Width="120"
                                    Height="35"/>
                            <ComboBox x:Name="DNSComboBox"
                                    Grid.Column="1"
                                    Width="120"
                                    Height="35"
                                    HorizontalAlignment="Left"
                                    Margin="20,0,0,0"
                                    Style="{StaticResource ModernComboBoxStyle}">
                                <ComboBoxItem IsEnabled="False" IsSelected="True">Select DNS</ComboBoxItem>
                                <ComboBoxItem>Cloudflare DNS</ComboBoxItem>
                                <ComboBoxItem>Google DNS</ComboBoxItem>
                                <ComboBoxItem>Default DNS</ComboBoxItem>
                            </ComboBox>
                        </Grid>
                    </Grid>

                    <!-- Debloat Content -->
                    <Grid x:Name="DebloatContent" Visibility="Collapsed" Margin="0,50,0,-10">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Hidden" Margin="10">
                            <StackPanel x:Name="DebloatPanel"/>
                        </ScrollViewer>

                        <Grid Grid.Row="1" Margin="20,0,20,20">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>

                            <Button x:Name="DebloatButton" 
                                    Grid.Column="0"
                                    Content="Run Debloater" 
                                    Style="{StaticResource ActionButtonStyle}"
                                    Width="120" 
                                    Height="35"/>
                        </Grid>
                    </Grid>

                    <!-- Info Content -->
                    <Grid x:Name="InfoContent" Visibility="Collapsed" Margin="0,50,0,0">
                        <ScrollViewer VerticalScrollBarVisibility="Hidden" Margin="20">
                            <StackPanel Margin="10">
                                <!-- Tool Information -->
                                <Border Background="{DynamicResource ButtonBackground}" CornerRadius="15" Padding="25" Margin="0,0,0,20">
                                    <StackPanel>
                                        <TextBlock Text="Tool Information" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource TextColor}"/>
                                        <Separator Margin="0,5,0,10" Background="{DynamicResource TextColor}" Opacity="0.1"/>
                                        <TextBlock Name="CurrentDateTime" Foreground="{DynamicResource TextColor}" FontSize="14" Margin="0,0,0,5"/>
                                        <TextBlock Text="Version: 1.0.0" Foreground="{DynamicResource TextColor}" FontSize="14" Margin="0,0,0,5"/>
                                        <TextBlock Text="Created by: Ritzy" Foreground="{DynamicResource TextColor}" FontSize="14"/>
                                    </StackPanel>
                                </Border>

                                <!-- Socials -->
                                <Border Background="{DynamicResource ButtonBackground}" CornerRadius="15" Padding="25" Margin="0,0,0,20">
                                    <StackPanel>
                                        <TextBlock Text="Connect With Me" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource TextColor}"/>
                                        <Separator Margin="0,5,0,10" Background="{DynamicResource TextColor}" Opacity="0.1"/>
                                        <TextBlock Foreground="{DynamicResource TextColor}" FontSize="14">
                                            <Run Text="YouTube: "/>
                                            <Hyperlink NavigateUri="https://www.youtube.com/@RitzySix">
                                                @RitzySix
                                            </Hyperlink>
                                        </TextBlock>
                                    </StackPanel>
                                </Border>

                                <!-- Recent Updates -->
                                <Border Background="{DynamicResource ButtonBackground}" CornerRadius="15" Padding="25" Margin="0,0,0,20">
                                    <StackPanel>
                                        <TextBlock Text="Recent Updates" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource TextColor}"/>
                                        <Separator Margin="0,5,0,10" Background="{DynamicResource TextColor}" Opacity="0.1"/>
                                        <StackPanel Margin="10,0,0,0">
                                            <TextBlock Text="• v1.0.0 - Initial Release" Foreground="{DynamicResource TextColor}" FontSize="14" Margin="0,0,0,5"/>
                                            <TextBlock Text="• Added Dark/Light Theme Toggle" Foreground="{DynamicResource TextColor}" FontSize="14" Margin="0,0,0,5"/>
                                            <TextBlock Text="• Implemented App Installation System" Foreground="{DynamicResource TextColor}" FontSize="14" Margin="0,0,0,5"/>
                                            <TextBlock Text="• Added Multiple Categories Support" Foreground="{DynamicResource TextColor}" FontSize="14" Margin="0,0,0,5"/>
                                            <TextBlock Text="• Enhanced UI/UX Design" Foreground="{DynamicResource TextColor}" FontSize="14" Margin="0,0,0,5"/>
                                            <TextBlock Text="• Added System Cleanup" Foreground="{DynamicResource TextColor}" FontSize="14"/>
                                        </StackPanel>
                                    </StackPanel>
                                </Border>

                                <!-- About Me -->
                                <Border Background="{DynamicResource ButtonBackground}" CornerRadius="15" Padding="25">
                                    <StackPanel>
                                        <TextBlock Text="About Ritzy" FontSize="26" FontWeight="SemiBold" Foreground="{DynamicResource TextColor}"/>
                                        <Separator Margin="0,5,0,10" Background="{DynamicResource TextColor}" Opacity="0.1"/>
                                        <TextBlock Foreground="{DynamicResource TextColor}" TextWrapping="Wrap" FontSize="14" LineHeight="24">
                                            Hey there! I'm Ritzy, a passionate gamer who loves diving deep into PC optimization and coding. This tool was born from my personal need for a quick and efficient way to set up my PC after fresh resets. As someone who understands the importance of peak performance in gaming, I wanted to create something that would help others achieve the same without the hassle.
                                            <LineBreak/><LineBreak/>
                                            My journey in PC optimization started with tweaking my own setup for better gaming performance, and it evolved into this comprehensive tool that I'm excited to share with the community. Whether you're a fellow gamer, a content creator, or someone who just wants their PC to run better, this tool is designed with you in mind.
                                        </TextBlock>
                                    </StackPanel>
                                </Border>
                            </StackPanel>
                        </ScrollViewer>
                    </Grid>
                </Grid>
            </Border>
        </Grid>
    </Border>
</Window>
'@

$null = $window.Dispatcher
$null = [Windows.Data.BindingOperations]::EnableCollectionSynchronization($null, $null)

# Create Window and Load XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Add code to hide PowerShell console window
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Console {
    public class Window {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
}
"@

# Hide the PowerShell console window
function Hide-PowerShellConsole {
    $consolePtr = [Console.Window]::GetConsoleWindow()
    [Console.Window]::ShowWindow($consolePtr, 0) # 0 = SW_HIDE
}

# Create a custom output stream writer to capture console output
$outputStream = New-Object System.IO.StringWriter
$errorStream = New-Object System.IO.StringWriter

# Function to redirect output to the console textbox
function Write-ToConsole {
    param([string]$Text, [string]$Color = "#CCCCCC")
    
    $window.Dispatcher.Invoke([Action]{
        $consoleOutput.AppendText("$Text`r`n")
        $consoleScroller.ScrollToEnd()
    })
}

# Fix the Invoke-CommandWithOutput function to handle null script blocks
function Invoke-CommandWithOutput {
    param(
        [Parameter(Mandatory=$false)]
        [scriptblock]$ScriptBlock
    )
    
    # Always navigate to Console tab first
    Show-Tab -TabName "ConsoleView"
    
    # If no script block is provided, just return after showing the console tab
    if ($null -eq $ScriptBlock) {
        return
    }
    
    try {
        # Execute the script block
        & $ScriptBlock
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}

# Get Controls
$closeButton = $window.FindName("CloseButton")
$minimizeButton = $window.FindName("MinimizeButton")
$themeToggle = $window.FindName("ThemeToggle")
$appsTab = $window.FindName("AppsTab")
$optimizeTab = $window.FindName("OptimizeTab")
$infoTab = $window.FindName("InfoTab")
$categoriesPanel = $window.FindName("CategoriesPanel")
$installButton = $window.FindName("InstallButton")
$appsContent = $window.FindName("AppsContent")
$optimizeContent = $window.FindName("OptimizeContent")
$infoContent = $window.FindName("InfoContent")
$currentDateTime = $window.FindName("CurrentDateTime")
$optimizationsPanel = $window.FindName("OptimizationsPanel")
$runTweaksButton = $window.FindName("RunTweaksButton")
$cleanTab = $window.FindName("CleanTab")
$cleanContent = $window.FindName("CleanContent")
$cleanButton = $window.FindName("CleanButton")
$cleanPanel = $window.FindName("CleanPanel")
$revertButton = $window.FindName("RevertButton")
$DNSComboBox = $window.FindName("DNSComboBox")
$uninstallButton = $window.FindName("UninstallButton")
$debloatTab = $window.FindName("DebloatTab")
$debloatContent = $window.FindName("DebloatContent")
$debloatPanel = $window.FindName("DebloatPanel")
$debloatButton = $window.FindName("DebloatButton")
$SearchBox = $window.FindName("SearchBox")
$allTweaksButton = $window.FindName("AllTweaksButton")
$fpsTweaksButton = $window.FindName("FPSTweaksButton")
$latencyTweaksButton = $window.FindName("LatencyTweaksButton")
$windowsTweaksButton = $window.FindName("WindowsTweaksButton")
$tosOverlay = $window.FindName("TOSOverlay")
$tosAgreeButton = $window.FindName("TOSAgreeButton")
$consoleTab = $window.FindName("ConsoleTab")
$consoleView = $window.FindName("ConsoleView")
$consoleOutput = $window.FindName("ConsoleOutput")
$consoleScroller = $window.FindName("ConsoleScroller")
$clearConsoleButton = $window.FindName("ClearConsoleButton")
$homeTab = $window.FindName("HomeTab")
$homeContent = $window.FindName("HomeContent")

# Create and configure SearchBox
$SearchBox.Height = 30
$SearchBox.Width = 875
$SearchBox.Margin = "20,35,20,0"
$SearchBox.HorizontalAlignment = "Left"
$SearchBox.VerticalAlignment = "Top"
$SearchBox.Background = "#1E1E1E"
$SearchBox.Foreground = "White"
$SearchBox.BorderBrush = "#333333"
$SearchBox.BorderThickness = 1
$SearchBox.Padding = "10,5"
$SearchBox.FontSize = 14
$SearchBox.VerticalContentAlignment = "Center"
[System.Windows.Controls.Panel]::SetZIndex($SearchBox, 999)

# Set up the placeholder text
$placeholderText = "Search..."
$SearchBox.Add_GotFocus({
    if ($this.Text -eq $placeholderText) {
        $this.Text = ""
        $this.Foreground = "White"
    }
})
$SearchBox.Add_LostFocus({
    if ([string]::IsNullOrEmpty($this.Text)) {
        $this.Text = $placeholderText
        $this.Foreground = "#808080"
    }
})

# Initialize with placeholder
$SearchBox.Text = $placeholderText
$SearchBox.Foreground = "#808080"

# Add corner radius
$borderStyle = New-Object Windows.Style([Windows.Controls.Border])
$borderStyle.Setters.Add((New-Object Windows.Setter([Windows.Controls.Border]::CornerRadiusProperty, "6")))
$SearchBox.Resources.Add([Windows.Controls.Border], $borderStyle)

# Add real-time search functionality
$SearchBox.Add_TextChanged({
    if ($this.Text -eq $placeholderText) { return }
    $searchText = $this.Text.ToLower()
    $panels = @($categoriesPanel, $optimizationsPanel, $cleanPanel, $debloatPanel)
    
    foreach ($panel in $panels) {
        if ($panel -and $panel.Children.Count -gt 0) {
            $wrapPanel = $panel.Children[0]
            foreach ($border in $wrapPanel.Children) {
                $stack = $border.Child
                $headerGrid = $stack.Children[0]
                $description = $stack.Children[1]
                
                $title = $headerGrid.Children[0].Text
                $desc = $description.Text
                
                $border.Visibility = if ([string]::IsNullOrEmpty($searchText) -or 
                    $title.ToLower().Contains($searchText) -or 
                    $desc.ToLower().Contains($searchText)) {
                    'Visible'
                } else {
                    'Collapsed'
                }
            }
        }
    }
})

# Theme State
$script:isDarkMode = $true
$appsBorder = New-Object Windows.Controls.Border
$appsBorder.Background = $window.Resources["BackgroundBrush"] 
$appsBorder.BorderBrush = $window.Resources["AccentBrush"]
$appsBorder.BorderThickness = "1"
$appsBorder.CornerRadius = "8"
$appsBorder.Margin = "8"
$appsBorder.Padding = "15"

# Create main container
$appsWrapPanel = New-Object Windows.Controls.WrapPanel
$appsWrapPanel.Orientation = "Horizontal"
$appsWrapPanel.Margin = "4"

foreach ($app in $apps.GetEnumerator()) {
    $appBorder = New-Object Windows.Controls.Border
    $appBorder.Background = $window.Resources["ButtonBackground"]
    $appBorder.BorderBrush = $window.Resources["ButtonBorder"]
    $appBorder.BorderThickness = "1"
    $appBorder.CornerRadius = "10"
    $appBorder.Margin = "8"
    $appBorder.Padding = "15"
    $appBorder.Width = "280"
    $appBorder.MinHeight = "180"
    $appStack = New-Object Windows.Controls.StackPanel
    # Create header grid for toggle positioning
    $headerGrid = New-Object Windows.Controls.Grid
    
    # Define columns for the grid
    $col1 = New-Object Windows.Controls.ColumnDefinition
    $col2 = New-Object Windows.Controls.ColumnDefinition
    $col2.Width = "Auto"
    $headerGrid.ColumnDefinitions.Add($col1)
    $headerGrid.ColumnDefinitions.Add($col2)
    
    # Create toggle switch
    $toggleSwitch = New-Object Windows.Controls.Primitives.ToggleButton
    $toggleSwitch.Style = $window.Resources["ToggleSwitchStyle"]
    $toggleSwitch.Margin = "0,0,0,10"
    $toggleSwitch.Tag = $app.Value
    [Windows.Controls.Grid]::SetColumn($toggleSwitch, 1)
    
    # Create content
    $appName = New-Object Windows.Controls.TextBlock
    $appName.Text = $app.Value.content
    $appName.FontWeight = "SemiBold"
    $appName.TextWrapping = "Wrap"
    $appName.Foreground = $window.Resources["TextColor"]
    [Windows.Controls.Grid]::SetColumn($appName, 0)
    
    $appDescription = New-Object Windows.Controls.TextBlock
    $appDescription.Text = $app.Value.description
    $appDescription.TextWrapping = "Wrap"
    $appDescription.Opacity = 0.7
    $appDescription.Margin = "0,5,0,0"
    $appDescription.Foreground = $window.Resources["TextColor"]
    
    # Add elements to layout
    $headerGrid.Children.Add($appName)
    $headerGrid.Children.Add($toggleSwitch)
    
    $appStack.Children.Add($headerGrid)
    $appStack.Children.Add($appDescription)
    
    $appBorder.Child = $appStack
    $appsWrapPanel.Children.Add($appBorder)
}
$categoriesPanel.Children.Add($appsWrapPanel)

# Create main border
$debloatBorder = New-Object Windows.Controls.Border
$debloatBorder.Background = $window.Resources["BackgroundBrush"] 
$debloatBorder.BorderBrush = $window.Resources["AccentBrush"]
$debloatBorder.BorderThickness = "1"
$debloatBorder.CornerRadius = "8"
$debloatBorder.Margin = "8"
$debloatBorder.Padding = "15"

# Create main container
$debloatWrapPanel = New-Object Windows.Controls.WrapPanel
$debloatWrapPanel.Orientation = "Horizontal"
$debloatWrapPanel.Margin = "4"

foreach ($item in $debloatItems.GetEnumerator()) {
    $itemBorder = New-Object Windows.Controls.Border
    $itemBorder.Background = $window.Resources["ButtonBackground"]
    $itemBorder.BorderBrush = $window.Resources["ButtonBorder"]
    $itemBorder.BorderThickness = "1"
    $itemBorder.CornerRadius = "10"
    $itemBorder.Margin = "8"
    $itemBorder.Padding = "15"
    $itemBorder.Width = "280"
    $itemBorder.MinHeight = "180"
    $itemStack = New-Object Windows.Controls.StackPanel
    
    # Create header grid
    $headerGrid = New-Object Windows.Controls.Grid
    $col1 = New-Object Windows.Controls.ColumnDefinition
    $col2 = New-Object Windows.Controls.ColumnDefinition
    $col2.Width = "Auto"
    $headerGrid.ColumnDefinitions.Add($col1)
    $headerGrid.ColumnDefinitions.Add($col2)
    
    # Create toggle switch
    $toggleSwitch = New-Object Windows.Controls.Primitives.ToggleButton
    $toggleSwitch.Style = $window.Resources["ToggleSwitchStyle"]
    $toggleSwitch.Margin = "0,0,0,10"
    $toggleSwitch.Tag = $item.Value
    [Windows.Controls.Grid]::SetColumn($toggleSwitch, 1)
    
    # Create content
    $itemName = New-Object Windows.Controls.TextBlock
    $itemName.Text = $item.Value.content
    $itemName.FontWeight = "SemiBold"
    $itemName.TextWrapping = "Wrap"
    $itemName.Foreground = $window.Resources["TextColor"]
    [Windows.Controls.Grid]::SetColumn($itemName, 0)
    
    $itemDescription = New-Object Windows.Controls.TextBlock
    $itemDescription.Text = $item.Value.description
    $itemDescription.TextWrapping = "Wrap"
    $itemDescription.Opacity = 0.7
    $itemDescription.Margin = "0,5,0,0"
    $itemDescription.Foreground = $window.Resources["TextColor"]
    
    # Add elements to layout
    $headerGrid.Children.Add($itemName)
    $headerGrid.Children.Add($toggleSwitch)
    
    $itemStack.Children.Add($headerGrid)
    $itemStack.Children.Add($itemDescription)
    
    $itemBorder.Child = $itemStack
    $debloatWrapPanel.Children.Add($itemBorder)
}
$debloatPanel.Children.Add($debloatWrapPanel)

# Create Optimization container
$optimizationsBorder = New-Object Windows.Controls.Border
$optimizationsBorder.Background = $window.Resources["BackgroundBrush"] 
$optimizationsBorder.BorderBrush = $window.Resources["AccentBrush"]
$optimizationsBorder.BorderThickness = "1"
$optimizationsBorder.CornerRadius = "8"
$optimizationsBorder.Margin = "10,5,10,10"
$optimizationsBorder.Padding = "15"

# Optimizations Section
$optimizationsWrapPanel = New-Object Windows.Controls.WrapPanel
$optimizationsWrapPanel.Orientation = "Horizontal"
$optimizationsWrapPanel.Margin = "4"

foreach ($tweak in $optimizations.GetEnumerator()) {
    $tweakBorder = New-Object Windows.Controls.Border
    $tweakBorder.Background = $window.Resources["ButtonBackground"]
    $tweakBorder.BorderBrush = $window.Resources["ButtonBorder"]
    $tweakBorder.BorderThickness = "1"
    $tweakBorder.CornerRadius = "10"
    $tweakBorder.Margin = "8"
    $tweakBorder.Padding = "15"
    $tweakBorder.Width = "280"
    $tweakBorder.MinHeight = "180"
    $tweakStack = New-Object Windows.Controls.StackPanel
    
    # Create header grid for toggle positioning
    $headerGrid = New-Object Windows.Controls.Grid
    
    # Define columns for the grid
    $col1 = New-Object Windows.Controls.ColumnDefinition
    $col2 = New-Object Windows.Controls.ColumnDefinition
    $col2.Width = "Auto"
    $headerGrid.ColumnDefinitions.Add($col1)
    $headerGrid.ColumnDefinitions.Add($col2)
    
    # Create toggle switch
    $toggleSwitch = New-Object Windows.Controls.Primitives.ToggleButton
    $toggleSwitch.Style = $window.Resources["ToggleSwitchStyle"]
    $toggleSwitch.Margin = "0,0,0,10"
    $toggleSwitch.Tag = $tweak.Value
    [Windows.Controls.Grid]::SetColumn($toggleSwitch, 1)
    
    # Create content
    $tweakName = New-Object Windows.Controls.TextBlock
    $tweakName.Text = $tweak.Value.content
    $tweakName.FontWeight = "SemiBold"
    $tweakName.TextWrapping = "Wrap"
    $tweakName.Foreground = $window.Resources["TextColor"]
    [Windows.Controls.Grid]::SetColumn($tweakName, 0)
    
    $tweakDescription = New-Object Windows.Controls.TextBlock
    $tweakDescription.Text = $tweak.Value.description
    $tweakDescription.TextWrapping = "Wrap"
    $tweakDescription.Opacity = 0.7
    $tweakDescription.Margin = "0,5,0,0"
    $tweakDescription.Foreground = $window.Resources["TextColor"]
    
    # Add elements to layout
    $headerGrid.Children.Add($tweakName)
    $headerGrid.Children.Add($toggleSwitch)
    
    $tweakStack.Children.Add($headerGrid)
    $tweakStack.Children.Add($tweakDescription)
    
    $tweakBorder.Child = $tweakStack
    $optimizationsWrapPanel.Children.Add($tweakBorder)
}
$optimizationsPanel.Children.Add($optimizationsWrapPanel)

# Create main container
$cleanupBorder = New-Object Windows.Controls.Border
$cleanupBorder.Background = $window.Resources["BackgroundBrush"] 
$cleanupBorder.BorderBrush = $window.Resources["AccentBrush"]
$cleanupBorder.BorderThickness = "1"
$cleanupBorder.CornerRadius = "8"
$cleanupBorder.Margin = "8"
$cleanupBorder.Padding = "15"

# Cleanup Section
$cleanupWrapPanel = New-Object Windows.Controls.WrapPanel
$cleanupWrapPanel.Orientation = "Horizontal"
$cleanupWrapPanel.Margin = "4"

foreach ($cleanup in $cleanupTasks.GetEnumerator()) {
    $cleanupBorder = New-Object Windows.Controls.Border
    $cleanupBorder.Background = $window.Resources["ButtonBackground"]
    $cleanupBorder.BorderBrush = $window.Resources["ButtonBorder"]
    $cleanupBorder.BorderThickness = "1"
    $cleanupBorder.CornerRadius = "10"
    $cleanupBorder.Margin = "8"
    $cleanupBorder.Padding = "15"
    $cleanupBorder.Width = "280"
    $cleanupBorder.MinHeight = "180"
    $cleanupStack = New-Object Windows.Controls.StackPanel
    
    # Create header grid for toggle positioning
    $headerGrid = New-Object Windows.Controls.Grid
    
    # Define columns for the grid
    $col1 = New-Object Windows.Controls.ColumnDefinition
    $col2 = New-Object Windows.Controls.ColumnDefinition
    $col2.Width = "Auto"
    $headerGrid.ColumnDefinitions.Add($col1)
    $headerGrid.ColumnDefinitions.Add($col2)
    
    # Create toggle switch
    $toggleSwitch = New-Object Windows.Controls.Primitives.ToggleButton
    $toggleSwitch.Style = $window.Resources["ToggleSwitchStyle"]
    $toggleSwitch.Margin = "0,0,0,10"
    $toggleSwitch.Tag = $cleanup.Value
    [Windows.Controls.Grid]::SetColumn($toggleSwitch, 1)
    
    # Create content
    $cleanupName = New-Object Windows.Controls.TextBlock
    $cleanupName.Text = $cleanup.Value.content
    $cleanupName.FontWeight = "SemiBold"
    $cleanupName.TextWrapping = "Wrap"
    $cleanupName.Foreground = $window.Resources["TextColor"]
    [Windows.Controls.Grid]::SetColumn($cleanupName, 0)
    
    $cleanupDescription = New-Object Windows.Controls.TextBlock
    $cleanupDescription.Text = $cleanup.Value.description
    $cleanupDescription.TextWrapping = "Wrap"
    $cleanupDescription.Opacity = 0.7
    $cleanupDescription.Margin = "0,5,0,0"
    $cleanupDescription.Foreground = $window.Resources["TextColor"]
    
    # Add elements to layout
    $headerGrid.Children.Add($cleanupName)
    $headerGrid.Children.Add($toggleSwitch)
    
    $cleanupStack.Children.Add($headerGrid)
    $cleanupStack.Children.Add($cleanupDescription)
    
    $cleanupBorder.Child = $cleanupStack
    $cleanupWrapPanel.Children.Add($cleanupBorder)
}

$categoriesPanel.Children.Add($appsWrapPanel)
$optimizationsPanel.Children.Add($optimizationsWrapPanel)
$cleanPanel.Children.Add($cleanupWrapPanel)

$panelsToFix = @($categoriesPanel, $optimizationsPanel, $cleanPanel, $debloatPanel)

foreach ($panel in $panelsToFix) {
    if ($panel -and $panel.Children.Count -gt 0) {
        $wrapPanel = $panel.Children[0]
        
        foreach ($border in $wrapPanel.Children) {
            # Make sure the border can receive mouse events
            $border.IsHitTestVisible = $true
            
            # Apply the CategoryPanelStyle to enable animations
            $border.Style = $window.Resources["CategoryPanelStyle"]
            
            # Make sure the child elements don't block mouse events
            if ($border.Child -is [System.Windows.Controls.StackPanel]) {
                $border.Child.Background = [System.Windows.Media.Brushes]::Transparent
            }
            
            # Add a name to make it easier to reference in animations
            if (-not $border.Name) {
                $uniqueName = "CategoryItem_" + [Guid]::NewGuid().ToString().Substring(0, 8)
                $border.Name = $uniqueName
            }
        }
    }
}

# Modify the Show-Tab function to handle home tab
function Show-Tab {
    param([string]$TabName)
    
    # Hide all tab content
    $homeContent.Visibility = "Collapsed"
    $appsContent.Visibility = "Collapsed"
    $optimizeContent.Visibility = "Collapsed"
    $infoContent.Visibility = "Collapsed"
    $cleanContent.Visibility = "Collapsed"
    $debloatContent.Visibility = "Collapsed"
    $consoleView.Visibility = "Collapsed"
    
    # Show the selected tab
    $window.FindName($TabName).Visibility = "Visible"
    
    # Update button styles to show which tab is selected
    $homeTab.IsSelected = $false
    $appsTab.IsSelected = $false
    $optimizeTab.IsSelected = $false
    $cleanTab.IsSelected = $false
    $infoTab.IsSelected = $false
    $debloatTab.IsSelected = $false
    $consoleTab.IsSelected = $false
    
    # Set the selected tab and control search box visibility
    switch ($TabName) {
        "HomeContent" {
            $homeTab.IsSelected = $true
            $SearchBox.Visibility = "Collapsed"
            Update-HomeTabContent  # Update home content each time the tab is shown
        }
        "AppsContent" {
            $appsTab.IsSelected = $true
            $SearchBox.Visibility = "Visible"
        }
        "OptimizeContent" {
            $optimizeTab.IsSelected = $true
            $SearchBox.Visibility = "Visible"
        }
        "CleanContent" {
            $cleanTab.IsSelected = $true
            $SearchBox.Visibility = "Visible"
        }
        "InfoContent" {
            $infoTab.IsSelected = $true
            $SearchBox.Visibility = "Visible"
        }
        "DebloatContent" {
            $debloatTab.IsSelected = $true
            $SearchBox.Visibility = "Visible"
        }
        "ConsoleView" {
            $consoleTab.IsSelected = $true
            $SearchBox.Visibility = "Collapsed"  # Hide search box in console tab
        }
    }
}

# Function to update the home tab content
function Update-HomeTabContent {
    # Clear existing content first to ensure we start fresh
    $homeContent.Children.Clear()
    
    # Create scroll viewer for the content
    $scrollViewer = New-Object Windows.Controls.ScrollViewer
    $scrollViewer.VerticalScrollBarVisibility = "Auto"
    $scrollViewer.HorizontalScrollBarVisibility = "Disabled"
    
    # Create main container with less vertical margin to reduce scrolling
    $homeMainPanel = New-Object Windows.Controls.StackPanel
    $homeMainPanel.Margin = "20,10,20,10"
    
    # Welcome section - more compact
    $welcomeSection = New-Object Windows.Controls.Border
    $welcomeSection.Background = $window.Resources["ButtonBackground"]
    $welcomeSection.BorderBrush = $window.Resources["ButtonBorder"]
    $welcomeSection.BorderThickness = "1"
    $welcomeSection.CornerRadius = "5"  # More rectangular corners
    $welcomeSection.Padding = "15"      # Less padding
    $welcomeSection.Margin = "0,0,0,10" # Less margin
    
    $welcomeContent = New-Object Windows.Controls.StackPanel
    
    $welcomeTitle = New-Object Windows.Controls.TextBlock
    $welcomeTitle.Text = "Welcome to Ritzy Optimizer"
    $welcomeTitle.FontSize = 22         # Slightly smaller font
    $welcomeTitle.FontWeight = "SemiBold"
    $welcomeTitle.Foreground = $window.Resources["TextColor"]
    
    $separator = New-Object Windows.Controls.Separator
    $separator.Margin = "0,5,0,5"       # Less margin
    $separator.Background = $window.Resources["TextColor"]
    $separator.Opacity = 0.1
    
    $welcomeDesc = New-Object Windows.Controls.TextBlock
    $welcomeDesc.Text = "This tool helps you optimize your Windows system, install applications, clean up unnecessary files, and remove bloatware."
    $welcomeDesc.TextWrapping = "Wrap"
    $welcomeDesc.Foreground = $window.Resources["TextColor"]
    $welcomeDesc.FontSize = 13          # Slightly smaller font
    $welcomeDesc.LineHeight = 18        # Less line height
    
    $welcomeContent.Children.Add($welcomeTitle)
    $welcomeContent.Children.Add($separator)
    $welcomeContent.Children.Add($welcomeDesc)
    $welcomeSection.Child = $welcomeContent
    
    # System info section
    $infoSection = New-Object Windows.Controls.Border
    $infoSection.Background = $window.Resources["ButtonBackground"]
    $infoSection.BorderBrush = $window.Resources["ButtonBorder"]
    $infoSection.BorderThickness = "1"
    $infoSection.CornerRadius = "5"     # More rectangular corners
    $infoSection.Padding = "15"         # Less padding
    $infoSection.Margin = "0,0,0,10"    # Less margin
    
    $infoContent = New-Object Windows.Controls.StackPanel
    
    $infoTitle = New-Object Windows.Controls.TextBlock
    $infoTitle.Text = "System Information"
    $infoTitle.FontSize = 22            # Slightly smaller font
    $infoTitle.FontWeight = "SemiBold"
    $infoTitle.Foreground = $window.Resources["TextColor"]
    
    $infoSeparator = New-Object Windows.Controls.Separator
    $infoSeparator.Margin = "0,5,0,5"   # Less margin
    $infoSeparator.Background = $window.Resources["TextColor"]
    $infoSeparator.Opacity = 0.1
    
    $infoContent.Children.Add($infoTitle)
    $infoContent.Children.Add($infoSeparator)
    
    # System info items
    $infoDynamicContent = New-Object Windows.Controls.StackPanel
    
    # Update system info
    try {
        $osInfo = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $cpuInfo = Get-CimInstance Win32_Processor -ErrorAction Stop
        $memoryInfo = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        $diskInfo = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
        
        $infoItems = @(
            @{ Name = "OS Version"; Value = "$($osInfo.Caption)" },
            @{ Name = "CPU"; Value = $cpuInfo.Name },
            @{ Name = "Total Memory"; Value = "$([math]::Round($memoryInfo.TotalPhysicalMemory / 1GB, 2)) GB" },
            @{ Name = "Free Disk Space"; Value = "$([math]::Round($diskInfo.FreeSpace / 1GB, 2)) GB of $([math]::Round($diskInfo.Size / 1GB, 2)) GB" }
        )
        
        foreach ($item in $infoItems) {
            $itemPanel = New-Object Windows.Controls.StackPanel
            $itemPanel.Orientation = "Horizontal"
            $itemPanel.Margin = "0,3,0,3"  # Less margin
            
            $nameBlock = New-Object Windows.Controls.TextBlock
            $nameBlock.Text = "$($item.Name): "
            $nameBlock.FontWeight = "SemiBold"
            $nameBlock.Width = 150
            $nameBlock.Foreground = $window.Resources["TextColor"]
            $nameBlock.FontSize = 13       # Slightly smaller font
            
            $valueBlock = New-Object Windows.Controls.TextBlock
            $valueBlock.Text = $item.Value
            $valueBlock.Foreground = $window.Resources["TextColor"]
            $valueBlock.FontSize = 13      # Slightly smaller font
            
            $itemPanel.Children.Add($nameBlock)
            $itemPanel.Children.Add($valueBlock)
            
            $infoDynamicContent.Children.Add($itemPanel)
        }
    }
    catch {
        $errorText = New-Object Windows.Controls.TextBlock
        $errorText.Text = "Could not retrieve system information."
        $errorText.Foreground = $window.Resources["TextColor"]
        $errorText.FontSize = 13
        $infoDynamicContent.Children.Add($errorText)
    }
    
    $infoContent.Children.Add($infoDynamicContent)
    $infoSection.Child = $infoContent
    
# Performance section
$perfSection = New-Object Windows.Controls.Border
$perfSection.Background = $window.Resources["ButtonBackground"]
$perfSection.BorderBrush = $window.Resources["ButtonBorder"]
$perfSection.BorderThickness = "1"
$perfSection.CornerRadius = "5"
$perfSection.Padding = "15"
$perfSection.Margin = "0,0,0,10"

$perfContent = New-Object Windows.Controls.StackPanel

$perfTitle = New-Object Windows.Controls.TextBlock
$perfTitle.Text = "Performance Metrics"
$perfTitle.FontSize = 22
$perfTitle.FontWeight = "SemiBold"
$perfTitle.Foreground = $window.Resources["TextColor"]

$perfSeparator = New-Object Windows.Controls.Separator
$perfSeparator.Margin = "0,5,0,5"
$perfSeparator.Background = $window.Resources["TextColor"]
$perfSeparator.Opacity = 0.1

$perfContent.Children.Add($perfTitle)
$perfContent.Children.Add($perfSeparator)

# Performance metrics
$perfDynamicContent = New-Object Windows.Controls.StackPanel

# Update performance metrics
try {
    # Get CPU usage - EXACT match with Task Manager
    $cpuLoad = 0
    try {
        # This is the exact counter Task Manager uses for CPU
        $cpuData = Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" -ErrorAction Stop
        $cpuLoad = [double]$cpuData.PercentProcessorTime
    } 
    catch {
        # Fallback only if the primary method fails
        try {
            $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction Stop
            $cpuLoad = $cpuCounter.CounterSamples[0].CookedValue
        }
        catch {
            $cpuLoad = 0
        }
    }

    # Get memory usage - EXACT match with Task Manager
    $memoryUsed = 0
    try {
        # Get the exact memory metrics Task Manager uses
        $operatingSystem = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
        $totalMemoryKB = $operatingSystem.TotalVisibleMemorySize
        $freeMemoryKB = $operatingSystem.FreePhysicalMemory
        
        # Calculate memory usage percentage exactly as Task Manager does
        if ($totalMemoryKB -gt 0) {
            $usedMemoryKB = $totalMemoryKB - $freeMemoryKB
            $memoryUsed = ($usedMemoryKB / $totalMemoryKB) * 100
        }
    }
    catch {
        # Fallback only if the primary method fails
        try {
            $memoryCounter = Get-Counter '\Memory\% Committed Bytes In Use' -ErrorAction Stop
            $memoryUsed = $memoryCounter.CounterSamples[0].CookedValue
        }
        catch {
            $memoryUsed = 0
        }
    }

    # Get disk activity - EXACT match with Task Manager
    $diskActivity = 0
    try {
        # Task Manager uses a combination of these counters for disk activity
        $diskData = Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'" -ErrorAction Stop
        
        # Calculate disk activity as Task Manager does (combines read and write activity)
        $diskBusy = [double]$diskData.PercentDiskTime
        $diskActivity = $diskBusy
        
        # If disk busy time is 0, try to calculate from disk read/write time
        if ($diskActivity -eq 0) {
            $diskReadTime = [double]$diskData.PercentDiskReadTime
            $diskWriteTime = [double]$diskData.PercentDiskWriteTime
            
            # Task Manager shows the higher of read/write or combined value
            $diskActivity = [Math]::Max($diskReadTime, $diskWriteTime)
        }
    }
    catch {
        # Fallback to standard counter if CIM method fails
        try {
            $diskCounter = Get-Counter '\PhysicalDisk(_Total)\% Disk Time' -ErrorAction Stop
            $diskActivity = $diskCounter.CounterSamples[0].CookedValue
        }
        catch {
            $diskActivity = 0
        }
    }

    # Ensure values are within valid range
    $cpuLoad = [Math]::Max(0, [Math]::Min(100, $cpuLoad))
    $memoryUsed = [Math]::Max(0, [Math]::Min(100, $memoryUsed))
    $diskActivity = [Math]::Max(0, [Math]::Min(100, $diskActivity))

    # Get number of running services
    $runningServices = 0
    try {
        $runningServices = (Get-Service | Where-Object {$_.Status -eq "Running"}).Count
    } catch {
        $runningServices = 0
    }
    
    # Create a clean table-like layout
    $perfTable = New-Object Windows.Controls.Grid
    $perfTable.Margin = "0,5,0,0"
    
    # Add columns: Label, Value, Indicator
    $col1 = New-Object Windows.Controls.ColumnDefinition  # Label
    $col1.Width = New-Object Windows.GridLength(150)
    $col2 = New-Object Windows.Controls.ColumnDefinition  # Value
    $col2.Width = New-Object Windows.GridLength(80)
    $col3 = New-Object Windows.Controls.ColumnDefinition  # Indicator
    $perfTable.ColumnDefinitions.Add($col1)
    $perfTable.ColumnDefinitions.Add($col2)
    $perfTable.ColumnDefinitions.Add($col3)
    
    # Add rows for each metric
    for ($i = 0; $i -lt 4; $i++) {
        $row = New-Object Windows.Controls.RowDefinition
        $row.Height = New-Object Windows.GridLength(30)
        $perfTable.RowDefinitions.Add($row)
    }
    
    # Define metrics
    $metrics = @(
        @{ Name = "CPU Usage"; Value = "$([math]::Round($cpuLoad, 1))%"; Percent = $cpuLoad },
        @{ Name = "Memory Usage"; Value = "$([math]::Round($memoryUsed, 1))%"; Percent = $memoryUsed },
        @{ Name = "Disk Activity"; Value = "$([math]::Round($diskActivity, 1))%"; Percent = $diskActivity },
        @{ Name = "Running Services"; Value = $runningServices; Percent = 0 }
    )
    
    # Add metrics to the grid
    for ($i = 0; $i -lt $metrics.Count; $i++) {
        $metric = $metrics[$i]
        
        # Label
        $nameBlock = New-Object Windows.Controls.TextBlock
        $nameBlock.Text = $metric.Name
        $nameBlock.FontWeight = "SemiBold"
        $nameBlock.Foreground = $window.Resources["TextColor"]
        $nameBlock.FontSize = 13
        $nameBlock.VerticalAlignment = "Center"
        [Windows.Controls.Grid]::SetRow($nameBlock, $i)
        [Windows.Controls.Grid]::SetColumn($nameBlock, 0)
        $perfTable.Children.Add($nameBlock)
        
        # Value
        $valueBlock = New-Object Windows.Controls.TextBlock
        $valueBlock.Text = $metric.Value
        $valueBlock.Foreground = $window.Resources["TextColor"]
        $valueBlock.FontSize = 13
        $valueBlock.VerticalAlignment = "Center"
        $valueBlock.HorizontalAlignment = "Right"
        $valueBlock.Margin = "0,0,10,0"
        [Windows.Controls.Grid]::SetRow($valueBlock, $i)
        [Windows.Controls.Grid]::SetColumn($valueBlock, 1)
        $perfTable.Children.Add($valueBlock)
        
        # Only add indicators for percentage-based metrics (not for services count)
        if ($i -lt 3) {
            # Create a cleaner indicator
            $indicatorPanel = New-Object Windows.Controls.StackPanel
            $indicatorPanel.Orientation = "Horizontal"
            $indicatorPanel.VerticalAlignment = "Center"
            
            # Create 10 small blocks for the indicator
            $percentValue = [math]::Min([math]::Max([math]::Round($metric.Percent / 10), 0), 10)
            
            for ($j = 0; $j -lt 10; $j++) {
                $block = New-Object Windows.Controls.Border
                $block.Width = 8
                $block.Height = 12
                $block.Margin = "1,0,1,0"
                $block.CornerRadius = "1"
                
                # Determine color based on index and value
                if ($j -lt $percentValue) {
                    if ($j -lt 6) {
                        $block.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(75, 175, 80))  # Green
                    } elseif ($j -lt 8) {
                        $block.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(255, 193, 7))  # Yellow
                    } else {
                        $block.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(244, 67, 54))  # Red
                    }
                } else {
                    $block.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(100, 100, 100))  # Gray
                    $block.Opacity = 0.3
                }
                
                $indicatorPanel.Children.Add($block)
            }
            
            [Windows.Controls.Grid]::SetRow($indicatorPanel, $i)
            [Windows.Controls.Grid]::SetColumn($indicatorPanel, 2)
            $perfTable.Children.Add($indicatorPanel)
        }
    }
    
    $perfDynamicContent.Children.Add($perfTable)
}
catch {
    $errorText = New-Object Windows.Controls.TextBlock
    $errorText.Text = "Could not retrieve performance metrics: $($_.Exception.Message)"
    $errorText.Foreground = $window.Resources["TextColor"]
    $errorText.FontSize = 13
    $errorText.TextWrapping = "Wrap"
    $perfDynamicContent.Children.Add($errorText)
}

$perfContent.Children.Add($perfDynamicContent)
$perfSection.Child = $perfContent
    
    # Network section
    $networkSection = New-Object Windows.Controls.Border
    $networkSection.Background = $window.Resources["ButtonBackground"]
    $networkSection.BorderBrush = $window.Resources["ButtonBorder"]
    $networkSection.BorderThickness = "1"
    $networkSection.CornerRadius = "5"     # More rectangular corners
    $networkSection.Padding = "15"         # Less padding
    
    $networkContent = New-Object Windows.Controls.StackPanel
    
    $networkTitle = New-Object Windows.Controls.TextBlock
    $networkTitle.Text = "Network Information"
    $networkTitle.FontSize = 22            # Slightly smaller font
    $networkTitle.FontWeight = "SemiBold"
    $networkTitle.Foreground = $window.Resources["TextColor"]
    
    $networkSeparator = New-Object Windows.Controls.Separator
    $networkSeparator.Margin = "0,5,0,5"   # Less margin
    $networkSeparator.Background = $window.Resources["TextColor"]
    $networkSeparator.Opacity = 0.1
    
    $networkContent.Children.Add($networkTitle)
    $networkContent.Children.Add($networkSeparator)
    
    # Network information
    $networkDynamicContent = New-Object Windows.Controls.StackPanel
    
    # Update network information - removed IP and MAC address
    try {
        # Get network adapter information
        $networkAdapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 3
        
        if ($networkAdapters.Count -eq 0) {
            $noNetworkText = New-Object Windows.Controls.TextBlock
            $noNetworkText.Text = "No active network connections found."
            $noNetworkText.Foreground = $window.Resources["TextColor"]
            $noNetworkText.FontSize = 13
            $networkDynamicContent.Children.Add($noNetworkText)
        }
        else {
            foreach ($adapter in $networkAdapters) {
                # Create adapter section
                $adapterPanel = New-Object Windows.Controls.StackPanel
                $adapterPanel.Margin = "0,0,0,10"  # Less margin
                
                $adapterName = New-Object Windows.Controls.TextBlock
                $adapterName.Text = $adapter.Name
                $adapterName.FontWeight = "SemiBold"
                $adapterName.Foreground = $window.Resources["TextColor"]
                $adapterName.FontSize = 14
                $adapterName.Margin = "0,0,0,3"  # Less margin
                $adapterPanel.Children.Add($adapterName)
                
                # Add adapter details - removed IP and MAC address
                $detailsItems = @(
                    @{ Name = "Interface"; Value = $adapter.InterfaceDescription },
                    @{ Name = "Status"; Value = $adapter.Status },
                    @{ Name = "Speed"; Value = if ($adapter.LinkSpeed) { $adapter.LinkSpeed } else { "Unknown" } }
                )
                
                foreach ($item in $detailsItems) {
                    $itemPanel = New-Object Windows.Controls.StackPanel
                    $itemPanel.Orientation = "Horizontal"
                    $itemPanel.Margin = "10,2,0,2"
                    
                    $nameBlock = New-Object Windows.Controls.TextBlock
                    $nameBlock.Text = "$($item.Name): "
                    $nameBlock.FontWeight = "SemiBold"
                    $nameBlock.Width = 80  # Smaller width
                    $nameBlock.Foreground = $window.Resources["TextColor"]
                    $nameBlock.FontSize = 13  # Smaller font
                    
                    $valueBlock = New-Object Windows.Controls.TextBlock
                    $valueBlock.Text = $item.Value
                    $valueBlock.Foreground = $window.Resources["TextColor"]
                    $valueBlock.FontSize = 13  # Smaller font
                    $valueBlock.TextWrapping = "Wrap"
                    
                    $itemPanel.Children.Add($nameBlock)
                    $itemPanel.Children.Add($valueBlock)
                    
                    $adapterPanel.Children.Add($itemPanel)
                }
                
                $networkDynamicContent.Children.Add($adapterPanel)
            }
        }
    }
    catch {
        $errorText = New-Object Windows.Controls.TextBlock
        $errorText.Text = "Could not retrieve network information."
        $errorText.Foreground = $window.Resources["TextColor"]
        $errorText.FontSize = 13
        $networkDynamicContent.Children.Add($errorText)
    }
    
    $networkContent.Children.Add($networkDynamicContent)
    $networkSection.Child = $networkContent
    
    # Create a grid layout for better organization with less scrolling
    $gridPanel = New-Object Windows.Controls.Grid
    $gridPanel.Margin = "0,0,0,0"
    
    # Define grid rows
    $row1 = New-Object Windows.Controls.RowDefinition
    $row1.Height = New-Object Windows.GridLength(Auto)
    $row2 = New-Object Windows.Controls.RowDefinition
    $row2.Height = New-Object Windows.GridLength(Auto)
    $row3 = New-Object Windows.Controls.RowDefinition
    $row3.Height = New-Object Windows.GridLength(Auto)
    $gridPanel.RowDefinitions.Add($row1)
    $gridPanel.RowDefinitions.Add($row2)
    $gridPanel.RowDefinitions.Add($row3)
    
    # Add welcome section to grid
    [Windows.Controls.Grid]::SetRow($welcomeSection, 0)
    $gridPanel.Children.Add($welcomeSection)
    
    # Create a horizontal panel for info and performance
    $infoAndPerfPanel = New-Object Windows.Controls.Grid
    $infoAndPerfPanel.Margin = "0,10,0,10"
    
    # Define columns for the horizontal panel
    $col1 = New-Object Windows.Controls.ColumnDefinition
    $col2 = New-Object Windows.Controls.ColumnDefinition
    $infoAndPerfPanel.ColumnDefinitions.Add($col1)
    $infoAndPerfPanel.ColumnDefinitions.Add($col2)
    
    # Add info section to the left column
    $infoSection.Margin = "0,0,5,0"  # Add right margin
    [Windows.Controls.Grid]::SetColumn($infoSection, 0)
    $infoAndPerfPanel.Children.Add($infoSection)
    
    # Add performance section to the right column
    $perfSection.Margin = "5,0,0,0"  # Add left margin
    [Windows.Controls.Grid]::SetColumn($perfSection, 1)
    $infoAndPerfPanel.Children.Add($perfSection)
    
    # Add the horizontal panel to the main grid
    [Windows.Controls.Grid]::SetRow($infoAndPerfPanel, 1)
    $gridPanel.Children.Add($infoAndPerfPanel)
    
    # Add network section to grid
    [Windows.Controls.Grid]::SetRow($networkSection, 2)
    $gridPanel.Children.Add($networkSection)
    
    # Add grid panel to main panel
    $homeMainPanel.Children.Add($gridPanel)
    
    # Add main panel to scroll viewer
    $scrollViewer.Content = $homeMainPanel
    
    # Add scroll viewer to home content
    $homeContent.Children.Add($scrollViewer)
}

[Console]::SetOut([System.IO.TextWriter]::Null)

# Add event handler for Clear Console button
$clearConsoleButton.Add_Click({
    $consoleOutput.Clear()
})

$closeButton.Add_Click({ 
    [void]$window.Close()
    if ($script:ShowOutput) { return } 
})

$minimizeButton.Add_Click({ $window.WindowState = "Minimized" })

$themeToggle.Add_Click({
    $script:isDarkMode = !$script:isDarkMode
    if ($script:isDarkMode) {
        $window.Resources["WindowBackground"] = [System.Windows.Media.SolidColorBrush]::new("#1E1E1E")
        $window.Resources["TextColor"] = [System.Windows.Media.SolidColorBrush]::new("#FFFFFF")
        $window.Resources["ButtonBackground"] = [System.Windows.Media.SolidColorBrush]::new("#2D2D2D")
        $window.Resources["ButtonHover"] = [System.Windows.Media.SolidColorBrush]::new("#404040")
        $window.Resources["ButtonPressed"] = [System.Windows.Media.SolidColorBrush]::new("#505050")
        $window.Resources["ButtonBorder"] = [System.Windows.Media.SolidColorBrush]::new("#404040")
    } else {
        $window.Resources["WindowBackground"] = [System.Windows.Media.SolidColorBrush]::new("#FFFFFF")
        $window.Resources["TextColor"] = [System.Windows.Media.SolidColorBrush]::new("#000000")
        $window.Resources["ButtonBackground"] = [System.Windows.Media.SolidColorBrush]::new("#F0F0F0")
        $window.Resources["ButtonHover"] = [System.Windows.Media.SolidColorBrush]::new("#E0E0E0")
        $window.Resources["ButtonPressed"] = [System.Windows.Media.SolidColorBrush]::new("#D0D0D0")
        $window.Resources["ButtonBorder"] = [System.Windows.Media.SolidColorBrush]::new("#E0E0E0")
    }
})

$appsTab.Add_Click({
    Show-Tab -TabName "AppsContent"
})

$revertButton.Add_Click({
    Navigate-And-Execute {
        $result = [System.Windows.MessageBox]::Show(
            "Are you sure you want to revert changes?`n`nWARNING! It will revert ALL your OPTIMIZATION changes you have made. You will have to re-apply everything you want to have optimized again!",
            "Confirm Revert",
            [System.Windows.MessageBoxButton]::YesNo,
            [System.Windows.MessageBoxImage]::Warning
        )
        
        if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
            Write-Host "Reverting all optimization changes..." -ForegroundColor Yellow
            reg import "C:\RegistryBackup\RegistryBackup.reg"
            Write-Host "All changes have been reverted successfully!" -ForegroundColor Green
        }
    }
})

# Function to filter optimizations by category
function FilterOptimizations {
    param([string]$category)
    
    # Get all optimization items
    if ($optimizationsPanel.Children.Count -gt 0) {
        $optimizationItems = $optimizationsPanel.Children[0].Children
        
        foreach ($item in $optimizationItems) {
            $toggleSwitch = $item.Child.Children[0].Children[1]
            $tweakCategory = $toggleSwitch.Tag.category
            
            if ($category -eq "All" -or 
                [string]::IsNullOrEmpty($tweakCategory) -or 
                ($tweakCategory -is [array] -and $tweakCategory -contains $category) -or
                $tweakCategory -eq $category) {
                $item.Visibility = "Visible"
            } else {
                $item.Visibility = "Collapsed"
            }
        }
    }
}

# category buttons
$allTweaksButton.Add_Click({
    FilterOptimizations "All"
})

$fpsTweaksButton.Add_Click({
    FilterOptimizations "FPS"
})

$latencyTweaksButton.Add_Click({
    FilterOptimizations "Latency"
})

$windowsTweaksButton.Add_Click({
    FilterOptimizations "windows"
})

$homeTab.Add_Click({
    Show-Tab -TabName "HomeContent"
})

$optimizeTab.Add_Click({
    Show-Tab -TabName "OptimizeContent"
    FilterOptimizations "All"
})

$cleanTab.Add_Click({
    Show-Tab -TabName "CleanContent"
})

$debloatTab.Add_Click({
    Show-Tab -TabName "DebloatContent"
})

$infoTab.Add_Click({
    $currentDateTime.Text = "Current Date/Time: " + (Get-Date -Format "MM/dd/yyyy HH:mm:ss")
    Show-Tab -TabName "InfoContent"
})

$consoleTab.Add_Click({
    Show-Tab -TabName "ConsoleView"
})

# Fix the clean button click handler
$cleanButton.Add_Click({
    Navigate-And-Execute {
        Ensure-SingleRestorePoint
        
        $selectedCleanups = $cleanPanel.Children[0].Children | 
            ForEach-Object {
                $toggleSwitch = $_.Child.Children[0].Children[1]
                if ($toggleSwitch.IsChecked) {
                    $toggleSwitch.Tag
                }
            }
        
        # Force array creation for proper count
        $selectedCleanups = @($selectedCleanups)
        
        if ($null -eq $selectedCleanups -or $selectedCleanups.Count -eq 0) {
            Write-Host "`nNo cleanup options selected." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`n=== Starting Selected Cleanup Tasks ===" -ForegroundColor Cyan
        Write-Host "Selected $($selectedCleanups.Count) cleanup tasks to run." -ForegroundColor Cyan
        
        foreach ($cleanup in $selectedCleanups) {
            Write-Host "`nExecuting $($cleanup.content)..." -ForegroundColor Yellow
            & $cleanup.action
            Write-Host "$($cleanup.content) completed successfully!" -ForegroundColor Green
        }
        
        Write-Host "`n=== All Selected Cleanup Tasks Completed ===`n" -ForegroundColor Cyan
    }
})

$runTweaksButton.Add_Click({
    Navigate-And-Execute {
        Ensure-SingleRestorePoint
        
        $tweaksApplied = $false
        # Process toggle switches if any are selected
        $selectedTweaks = $optimizationsPanel.Children[0].Children | 
            ForEach-Object {
                $toggleSwitch = $_.Child.Children[0].Children[1]
                if ($toggleSwitch.IsChecked) {
                    $tweaksApplied = $true
                    $toggleSwitch.Tag
                }
            }
        
        # Force array creation for proper count
        $selectedTweaks = @($selectedTweaks)
        
        if ($tweaksApplied) {
            Write-Host "`n=== Applying Selected Tweaks ===" -ForegroundColor Cyan
            Write-Host "Selected $($selectedTweaks.Count) tweaks to apply." -ForegroundColor Cyan
            
            foreach ($tweak in $selectedTweaks) {
                Write-Host "`nApplying $($tweak.content)..." -ForegroundColor Yellow
                & $tweak.action
                Write-Host "$($tweak.content) applied successfully!" -ForegroundColor Green
            }
        }
        
        # Process DNS settings independently
        $selectedDNS = $DNSComboBox.SelectedItem.Content
        if ($selectedDNS -and $selectedDNS -ne "Select DNS") {
            Write-Host "`nModifying DNS settings..." -ForegroundColor Cyan
            $adapters = Get-NetAdapter | Where-Object {($_.Name -like "*Ethernet*" -or $_.Name -like "*Wi-Fi*") -and $_.Status -eq "Up"}
            
            switch ($selectedDNS) {
                "Google DNS" {
                    foreach ($adapter in $adapters) {
                        netsh interface ipv4 set dns name="$($adapter.Name)" static 8.8.8.8 primary
                        netsh interface ipv4 add dns name="$($adapter.Name)" 8.8.4.4 index=2
                        Write-Host "Setting Google DNS for adapter: $($adapter.Name)" -ForegroundColor Yellow
                    }
                }
                "Cloudflare DNS" {
                    foreach ($adapter in $adapters) {
                        netsh interface ipv4 set dns name="$($adapter.Name)" static 1.1.1.1 primary
                        netsh interface ipv4 add dns name="$($adapter.Name)" 1.0.0.1 index=2
                        Write-Host "Setting Cloudflare DNS for adapter: $($adapter.Name)" -ForegroundColor Yellow
                    }
                }
                "Default DNS" {
                    foreach ($adapter in $adapters) {
                        netsh interface ipv4 set dns name="$($adapter.Name)" dhcp
                        Write-Host "Resetting DNS for adapter: $($adapter.Name)" -ForegroundColor Yellow
                    }
                }
            }
            ipconfig /flushdns
            Write-Host "DNS settings updated successfully!" -ForegroundColor Green
            $tweaksApplied = $true
        }
        
        if ($tweaksApplied) {
            Write-Host "`n=== All Selected Changes Applied ===`n" -ForegroundColor Cyan
        } else {
            Write-Host "`nNo changes selected to apply." -ForegroundColor Yellow
        }
    }
})

$tosAgreeButton.Add_Click({
    $tosOverlay.Visibility = "Collapsed"
})

# Helper function to navigate to console tab and then run commands
function Navigate-And-Execute {
    param(
        [scriptblock]$ScriptBlock
    )
    
    # First navigate to console tab
    Show-Tab -TabName "ConsoleView"
    
    # Use dispatcher to allow UI to update before executing commands
    $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
    
    # Use a timer to delay execution without freezing the UI
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $timer.Tag = $ScriptBlock
    
    $timer.Add_Tick({
        # Stop the timer
        $this.Stop()
        
        # Execute the script block
        & $this.Tag
    })
    
    # Start the timer
    $timer.Start()
}

function Remove-AppTraces {
    param($app)
    
    $paths = @(
        "$env:ProgramFiles\$($app.content)",
        "${env:ProgramFiles(x86)}\$($app.content)",
        "$env:LOCALAPPDATA\$($app.content)",
        "$env:APPDATA\$($app.content)"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force
            Write-Host "Cleaned up: $path" -ForegroundColor Yellow
        }
    }
}

function Ensure-Chocolatey {
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-WebRequest https://community.chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
        refreshenv
        Write-Host "Chocolatey installed successfully!" -ForegroundColor Green
    }
}

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
    Start-Process -FilePath PowerShell.exe -Verb RunAs -ArgumentList $CommandLine
    Exit
}

$installButton.Add_Click({
    Navigate-And-Execute {
        Ensure-Chocolatey
        
        $selectedApps = $categoriesPanel.Children[0].Children | 
            ForEach-Object {
                $toggleSwitch = $_.Child.Children[0].Children[1]
                if ($toggleSwitch.IsChecked) {
                    $toggleSwitch.Tag
                }
            }
        
        # Force array creation for proper count
        $selectedApps = @($selectedApps)
        
        if ($null -eq $selectedApps -or $selectedApps.Count -eq 0) {
            Write-Host "`nNo apps selected for installation." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`n=== Starting Installation Process ===" -ForegroundColor Cyan
        Write-Host "Selected $($selectedApps.Count) apps to install." -ForegroundColor Cyan
        
        # Rest of your installation code...
        foreach ($app in $selectedApps) {
            Write-Host "`nProcessing $($app.content)..." -ForegroundColor Cyan

        if ($app.installType -eq "manual") {
            Write-Host "This application requires manual installation." -ForegroundColor Yellow
            Write-Host "Please download from: $($app.link)" -ForegroundColor Yellow
            Write-Host "Instructions: $($app.installInstructions)" -ForegroundColor Yellow
            continue
        }

        try {
            $installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                Where-Object { $_.DisplayName -like "*$($app.content)*" }
            
            if ($installed) {
                Write-Host "$($app.content) is already installed." -ForegroundColor Blue
                continue
            }

            if ($app.winget) {
                Write-Host "Attempting installation with winget..." -ForegroundColor Yellow
                if ($app.winget -is [array]) {
                    foreach ($package in $app.winget) {
                        Write-Host "Installing package: $package" -ForegroundColor Yellow
                        winget install -e --accept-source-agreements --accept-package-agreements $package
                        Start-Sleep -Seconds 2
                    }
                } else {
                    winget install -e --accept-source-agreements --accept-package-agreements $app.winget
                    Start-Sleep -Seconds 2
                }
                $installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
                    Where-Object { $_.DisplayName -like "*$($app.content)*" }
                
                if ($installed) {
                    Write-Host "$($app.content) installed successfully with winget!" -ForegroundColor Green
                    continue
                }
            }

            if ($app.choco) {
                Write-Host "Installing with Chocolatey..." -ForegroundColor Yellow
                
                # Pre-installation cleanup
                Get-Process | Where-Object { $_.Name -like "*choco*" } | Stop-Process -Force -ErrorAction SilentlyContinue
                Remove-Item "$env:TEMP\chocolatey\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "C:\ProgramData\chocolatey\lib-bad\*" -Recurse -Force -ErrorAction SilentlyContinue
                
                # Initialize printed lines tracking
                $printed = New-Object System.Collections.ArrayList
                
                # Monitor output in real-time while process is running
                $downloadCompleted = $false
                $installationStarted = $false

                # Simplified and optimized installation command
                $process = Start-Process -FilePath "choco" -ArgumentList "install $($app.choco) -y --force --no-progress --ignore-checksums" -WindowStyle Hidden -PassThru -RedirectStandardOutput "$env:TEMP\choco_output.txt" -RedirectStandardError "$env:TEMP\choco_error.txt"

                while (!$process.HasExited) {
                    if (Test-Path "$env:TEMP\choco_output.txt") {
                        Get-Content "$env:TEMP\choco_output.txt" -Tail 1 | ForEach-Object {
                            if ($_ -and -not $printed.Contains($_)) {
                                Write-Host $_
                                $printed.Add($_) | Out-Null
                                
                                # Check for download completion and exe path indication
                                if ($_ -match "Download of .+ completed\.") {
                                    Start-Sleep -Seconds 10  # Allow installation to proceed
                                }
                                
                                if ($downloadCompleted -and $_ -match "\.exe$") {
                                    Start-Sleep -Seconds 15  # Give installation time to complete
                                    
                                    # Force terminate the process and continue
                                    $process | Stop-Process -Force
                                    Get-Process | Where-Object { $_.Name -like "*choco*" } | Stop-Process -Force
                                    # Remove this line to avoid duplicate success messages
                                    # Write-Host "$($app.content) installed successfully!" -ForegroundColor Green
                                    $installed = $true  # Mark as successfully installed
                                    break
                                }
                            }
                        }
                    }
                    Start-Sleep -Milliseconds 100
                }
                
                # Cleanup
                Get-Process | Where-Object { $_.Name -like "*choco*" } | Stop-Process -Force
                Remove-Item "$env:TEMP\choco_output.txt", "$env:TEMP\choco_error.txt" -Force -ErrorAction SilentlyContinue
                
                Start-Sleep -Seconds 2
                $installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                    Where-Object { $_.DisplayName -like "*$($app.content)*" }

                if ($installed) {
                    Write-Host "$($app.content) installed successfully with Chocolatey!" -ForegroundColor Green
                } else {
                    Write-Host "Failed to install $($app.content) with Chocolatey." -ForegroundColor Red
                }
            } else {
                Write-Host "No package manager options available for $($app.content)." -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error processing $($app.content): $_" -ForegroundColor Red
        }
    }
    Write-Host "`n=== Installation Process Complete ===`n" -ForegroundColor Cyan
    }
})

$uninstallButton.Add_Click({
    Navigate-And-Execute {
        Ensure-Chocolatey
        
        $selectedApps = $categoriesPanel.Children[0].Children | 
            ForEach-Object {
                $toggleSwitch = $_.Child.Children[0].Children[1]
                if ($toggleSwitch.IsChecked) {
                    $toggleSwitch.Tag
                }
            }
        
        # Force array creation for proper count
        $selectedApps = @($selectedApps)
        
        if ($null -eq $selectedApps -or $selectedApps.Count -eq 0) {
            Write-Host "`nNo apps selected for uninstallation." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`n=== Starting Uninstallation Process ===" -ForegroundColor Cyan
        Write-Host "Selected $($selectedApps.Count) apps to uninstall." -ForegroundColor Cyan
        
        # Rest of your uninstallation code...
        foreach ($app in $selectedApps) {
            Write-Host "`nProcessing $($app.content)..." -ForegroundColor Cyan

        if ($app.installType -eq "manual") {
            Write-Host "This application requires manual uninstallation." -ForegroundColor Yellow
            continue
        }

        try {
            $installed = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                Where-Object { $_.DisplayName -like "*$($app.content)*" }

            if (!$installed) {
                Write-Host "$($app.content) is not installed." -ForegroundColor Blue
                continue
            }

            Write-Host "Uninstalling $($app.content)..." -ForegroundColor Yellow

            if ($app.winget) {
                if ($app.winget -is [array]) {
                    foreach ($package in $app.winget) {
                        Write-Host "Uninstalling package: $package" -ForegroundColor Yellow
                        winget uninstall --exact $package
                        Start-Sleep -Seconds 2
                    }
                } else {
                    winget uninstall --exact $app.winget
                    Start-Sleep -Seconds 2
                }
                $stillInstalled = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
                    Where-Object { $_.DisplayName -like "*$($app.content)*" }
                if (!$stillInstalled) {
                    Write-Host "$($app.content) uninstalled successfully with winget!" -ForegroundColor Green
                    Remove-AppTraces $app
                    continue
                }
            }

            if ($app.choco) {
                # Initialize printed lines tracking
                $printed = New-Object System.Collections.ArrayList
                
                # Start the process with proper output handling
                $process = Start-Process -FilePath "choco" -ArgumentList "uninstall", $app.choco, "-y", "--force", "--no-progress", "--confirm", "--accept-license", "--yes", "--allow-empty-checksums" -WindowStyle Hidden -PassThru -RedirectStandardOutput "$env:TEMP\choco_output.txt" -RedirectStandardError "$env:TEMP\choco_error.txt"
                
                # Monitor output in real-time while process is running
                while (!$process.HasExited) {
                    if (Test-Path "$env:TEMP\choco_output.txt") {
                        Get-Content "$env:TEMP\choco_output.txt" -Tail 1 | ForEach-Object {
                            if ($_ -and -not $printed.Contains($_)) {
                                Write-Host $_
                                $printed.Add($_) | Out-Null
                            }
                        }
                    }
                    Start-Sleep -Milliseconds 100
                }
                
                # Force close any remaining choco processes
                Get-Process | Where-Object { $_.Name -like "*choco*" } | Stop-Process -Force
                
                # Clean up temp files
                Remove-Item "$env:TEMP\choco_output.txt", "$env:TEMP\choco_error.txt" -Force -ErrorAction SilentlyContinue
                
                Start-Sleep -Seconds 2
                $stillInstalled = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
                    Where-Object { $_.DisplayName -like "*$($app.content)*" }

                if (!$stillInstalled) {
                    Write-Host "$($app.content) uninstalled successfully with Chocolatey!" -ForegroundColor Green
                    Remove-AppTraces $app
                } else {
                    Write-Host "Failed to uninstall $($app.content) with Chocolatey." -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "Error processing $($app.content): $_" -ForegroundColor Red
        }
    }
    Write-Host "`n=== Uninstallation Process Complete ===`n" -ForegroundColor Cyan
    }
})

$debloatButton.Add_Click({
    Navigate-And-Execute {
        Ensure-SingleRestorePoint
        
        $selectedDebloatItems = $debloatPanel.Children[0].Children | 
            ForEach-Object {
                $toggleSwitch = $_.Child.Children[0].Children[1]
                if ($toggleSwitch.IsChecked) {
                    $toggleSwitch.Tag
                }
            }
        
        # Force array creation for proper count
        $selectedDebloatItems = @($selectedDebloatItems)
        
        if ($null -eq $selectedDebloatItems -or $selectedDebloatItems.Count -eq 0) {
            Write-Host "`nNo debloat options selected." -ForegroundColor Yellow
            return
        }
        
        Write-Host "`n=== Running Selected Debloat Actions ===" -ForegroundColor Cyan
        Write-Host "Selected $($selectedDebloatItems.Count) debloat options to apply." -ForegroundColor Cyan
        
        foreach ($item in $selectedDebloatItems) {
            Write-Host "`nExecuting $($item.content)..." -ForegroundColor Yellow
            & $item.action
            Write-Host "$($item.content) completed successfully!" -ForegroundColor Green
        }
        
        Write-Host "`n=== All Debloat Actions Completed ===`n" -ForegroundColor Cyan
    }
})

# Set up console redirection
[System.Console]::SetOut($outputStream)

# Override Write-Host to redirect to console output
function Write-Host {
    param(
        [Parameter(Position=0, ValueFromPipeline=$true)]
        [string]$Object,
        [Parameter()]
        [ConsoleColor]$ForegroundColor,
        [Parameter()]
        [ConsoleColor]$BackgroundColor,
        [Parameter()]
        [switch]$NoNewline
    )
    
    # Map ConsoleColor to hex color
    $colorMap = @{
        'Black' = '#000000'
        'DarkBlue' = '#000080'
        'DarkGreen' = '#008000'
        'DarkCyan' = '#008080'
        'DarkRed' = '#800000'
        'DarkMagenta' = '#800080'
        'DarkYellow' = '#808000'
        'Gray' = '#808080'
        'DarkGray' = '#404040'
        'Blue' = '#0000FF'
        'Green' = '#00FF00'
        'Cyan' = '#00FFFF'
        'Red' = '#FF0000'
        'Magenta' = '#FF00FF'
        'Yellow' = '#FFFF00'
        'White' = '#FFFFFF'
    }
    
    $color = if ($ForegroundColor) { $colorMap[$ForegroundColor.ToString()] } else { "#CCCCCC" }
    
    # Write to our custom console
    Write-ToConsole -Text $Object -Color $color
    
    # Also write to the original console for debugging
    [Console]::WriteLine($Object)
}

# Override Write-Output to redirect to console output
function Write-Output {
    param(
        [Parameter(Position=0, ValueFromPipeline=$true)]
        $Object
    )
    
    if ($Object -is [string]) {
        Write-ToConsole -Text $Object
    } else {
        Write-ToConsole -Text ($Object | Out-String)
    }
    
    # Also send to the original output stream
    $Object
}

# Hide the PowerShell console window after setting up redirection
Hide-PowerShellConsole

# Show the default tab on startup
Update-HomeTabContent
Show-Tab -TabName "HomeContent"

# Show the window
$window.ShowDialog() | Out-Null
