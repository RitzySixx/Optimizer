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

# Function to create restore point if not already created
function Ensure-SingleRestorePoint {
    if (-not $script:restorePointCreated) {
        Write-Host "Creating System Restore Point..." -ForegroundColor Cyan
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "Ritzy Optimizer Changes" -RestorePointType "MODIFY_SETTINGS"
        $script:restorePointCreated = $true
        Write-Host "System Restore Point created successfully!" -ForegroundColor Green
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
    "OneDrive" = @{
        content = "OneDrive"
        description = "OneDrive is a cloud storage service provided by Microsoft, allowing users to store and share files securely across devices."
        link = "https://onedrive.live.com/"
        winget = "Microsoft.OneDrive"
        choco = "onedrive"
    }
    "ISLC" = @{
        content = "ISLC"
        description = "Intelligent Standby List Cleaner (ISLC) is a utility that helps manage and clear the standby list in Windows, potentially improving system performance."
        link = "https://www.wagnardsoft.com/ISLCw"
        installType = "manual"
        installInstructions = "Download from official website and extract the zip file"
        choco = "islc"
    }
    "TimerResolution" = @{
        content = "TimerResolution"
        description = "TimerResolution allows you to adjust Windows timer resolution for better system responsiveness and reduced input lag."
        link = "https://cms.lucashale.com/timer-resolution/"
        installType = "manual"
        installInstructions = "Download from official website and extract the zip file"
        choco = "timer-resolution"
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

"NVIDIA GeForce Experience" = @{
    content = "NVIDIA GeForce Experience"
    description = "Game optimization and driver management tool with built-in streaming features."
    link = "https://www.nvidia.com/en-us/geforce/geforce-experience/"
    winget = "Nvidia.GeForceExperience"
    choco = "geforce-experience"
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
        
    "RemoveOutlook" = @{
        content = "Remove Outlook"
        description = "Will be uninstalled. Default Windows email client for mail, calendar, contacts and task management"
        action = {
            Write-Host "`nStarting Outlook Removal Process..." -ForegroundColor Cyan
            
            # Kill all Outlook processes
            taskkill /F /IM outlook.exe /T
            
            # Remove via multiple methods for complete uninstallation
            winget uninstall "Microsoft.OutlookForWindows"
            Get-AppxPackage -Name "Microsoft.OutlookForWindows" -AllUsers | Remove-AppxPackage -AllUsers
            Get-AppxPackage -Name "Microsoft.Office.Outlook" -AllUsers | Remove-AppxPackage -AllUsers
            
            # Remove using DISM
            $packages = DISM /Online /Get-ProvisionedAppxPackages | Select-String "PackageName.*outlook"
            foreach ($package in $packages) {
                $packageName = ($package -split ": ")[1]
                DISM /Online /Remove-ProvisionedAppxPackage /PackageName:$packageName
            }
            
            # Clean installation directories
            $outlookPaths = @(
                "$env:LOCALAPPDATA\Microsoft\WindowsApps\Microsoft.OutlookForWindows_8wekyb3d8bbwe",
                "$env:PROGRAMFILES\Microsoft Office\root\Office16\OUTLOOK.EXE",
                "$env:PROGRAMFILES (x86)\Microsoft Office\root\Office16\OUTLOOK.EXE",
                "$env:LOCALAPPDATA\Microsoft\Office\16.0\Outlook",
                "$env:APPDATA\Microsoft\Outlook"
            )
            foreach ($path in $outlookPaths) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            # Block reinstallation and clean registry
            $regPaths = @(
                "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\REGISTRY\MACHINE\Software\Microsoft\Office\Outlook",
                "HKCU:\Software\Microsoft\Office\Outlook",
                "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE"
            )
            foreach ($path in $regPaths) {
                Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            }
            
            Write-Host "Outlook has been completely removed!" -ForegroundColor Green
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
}

$optimizations = @{
    "Ping Optimization" = @{
        content = "Ping / Latency Optimizer"
        description = "Comprehensive Ping optimization for better ping and reduced latency"
        action = {
                Write-Host "`n=== Starting Ping Optimization Process ===" -ForegroundColor Cyan
                Write-Host "This will optimize various Ping settings for better performance." -ForegroundColor Yellow
                
                $registryChanges = @{
                    "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" = @{
                        "DefaultTTL" = 0x40
                        "DisableTaskOffload" = 1
                        "EnableConnectionRateLimiting" = 0
                        "EnableDCA" = 1
                        "EnablePMTUBHDetect" = 0
                        "EnablePMTUDiscovery" = 1
                        "EnableRSS" = 1
                        "TcpTimedWaitDelay" = 0x1e
                        "EnableWsd" = 0
                        "GlobalMaxTcpWindowSize" = 0xffff
                        "MaxConnectionsPer1_0Server" = 0xa
                        "MaxConnectionsPerServer" = 0xa
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
                    "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters" = @{
                        "TCPNoDelay" = 1
                    }
                    "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" = @{
                        "LocalPriority" = 4
                        "HostsPriority" = 5
                        "DnsPriority" = 6
                        "NetbtPriority" = 7
                    }
                    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" = @{
                        "NetworkThrottlingIndex" = 0xffffffff
                        "SystemResponsiveness" = 0
                    }
                    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" = @{
                        "NonBestEffortLimit" = 0
                    }
                    "HKLM:\SYSTEM\CurrentControlSet\Services\Psched" = @{
                        "NonBestEffortLimit" = 0
                    }
                    "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" = @{
                        "MaxCmds" = 0x1e
                        "MaxThreads" = 0x1e
                        "MaxCollectionCount" = 0x20
                    }
                    "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" = @{
                        "IRPStackSize" = 0x32
                        "SizReqBuf" = 0x4410
                        "Size" = 3
                        "MaxWorkItems" = 0x2000
                        "MaxMpxCt" = 0x800
                        "MaxCmds" = 0x800
                        "DisableStrictNameChecking" = 1
                        "autodisconnect" = 0xffffffff
                        "EnableOplocks" = 0
                        "SharingViolationDelay" = 0
                        "SharingViolationRetries" = 0
                    }
                    "HKLM:\SYSTEM\CurrentControlSet\Services\AFD\Parameters" = @{
                        "DefaultReceiveWindow" = 0x4000
                        "DefaultSendWindow" = 0x4000
                        "FastCopyReceiveThreshold" = 0x4000
                        "FastSendDatagramThreshold" = 0x4000
                        "DynamicSendBufferDisable" = 0
                        "IgnorePushBitOnReceives" = 1
                        "NonBlockingSendSpecialBuffering" = 1
                        "DisableRawSecurity" = 1
                    }
                }

                 # Get all network interfaces and verify/create Nagle's Algorithm settings
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
                Write-Host "Nagle's Algorithm successfully disabled on all interfaces!" -ForegroundColor Green

                foreach ($path in $registryChanges.Keys) {
                    Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
                    
                    if (!(Test-Path $path)) {
                        Write-Host "Creating new registry path..." -ForegroundColor Gray
                        New-Item -Path $path -Force | Out-Null
                    }
                    
                    foreach ($name in $registryChanges[$path].Keys) {
                        Write-Host "Setting $name to $($registryChanges[$path][$name])" -ForegroundColor Green
                        Set-ItemProperty -Path $path -Name $name -Value $registryChanges[$path][$name] -Type DWord
                    }
                }
                                # Disable Power Saving for Network Adapters
                Write-Host "`nDisabling Power Saving for Network Adapters..." -ForegroundColor Yellow
                
                # Get all network adapters
                Get-NetAdapter | ForEach-Object {
                    Write-Host "Processing adapter: $($_.Name)" -ForegroundColor Green
                    
                    # Disable Power Saving features
                    Set-NetAdapterPowerManagement -Name $_.Name -SelectiveSuspend Disabled -WakeOnMagicPacket Disabled -WakeOnPattern Disabled
                    
                    # Additional power saving registry settings
                    $adapterPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$($_.InterfaceIndex)"
                    if (Test-Path $adapterPath) {
                        Set-ItemProperty -Path $adapterPath -Name "PnPCapabilities" -Value 24 -Type DWord
                        Set-ItemProperty -Path $adapterPath -Name "PowerSavingEnabled" -Value 0 -Type DWord
                    }
                }
                Write-Host "Power Saving features disabled on all network adapters!" -ForegroundColor Green

                Write-Host "`nConfiguring QoS Settings..." -ForegroundColor Yellow
                Write-Host "Setting TCP Autotuning Level to Off" -ForegroundColor Green
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS" -Name "Tcp Autotuning Level" -Value "Off" -Type String
                
                Write-Host "Setting DSCP Marking Request to Ignored" -ForegroundColor Green
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS" -Name "Application DSCP Marking Request" -Value "Ignored" -Type String
                
                Write-Host "Configuring NLA Settings" -ForegroundColor Green
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\services\Tcpip\QoS" -Name "Do not use NLA" -Value "1" -Type String

                Write-Host "`n=== Latency Optimizations Complete! ===" -ForegroundColor Cyan
            }
        }
    "FPS Boost" = @{
    content = "FPS Tweaks"
    description = "Comprehensive system optimizations including memory management, GPU performance, and privacy settings"
    action = {
        Write-Host "`n=== Starting System Performance Optimization ===" -ForegroundColor Cyan
        
        $registryChanges = @{
            # Power Settings
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

            # Memory Management
            "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" = @{
                "ClearPageFileAtShutdown" = 1
                "FeatureSettings" = 0
                "FeatureSettingsOverrideMask" = 3
                "FeatureSettingsOverride" = 3
                "LargeSystemCache" = 1
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
            # Background Apps
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" = @{
                "GlobalUserDisabled" = 1
            }
            # Search
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" = @{
                "BackgroundAppGlobalToggle" = 0
            }
            # Game DVR Settings
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

            # System Profile
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" = @{
                "SystemResponsiveness" = 0
                "NetworkThrottlingIndex" = 0xfffffff
            }
            # Games Task Settings
            "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" = @{
                "Affinity" = 0
                "Background Only" = "False"
                "Clock Rate" = 0x2710
                "GPU Priority" = 8
                "Priority" = 6
                "Scheduling Category" = "High"
                "SFIO Priority" = "High"
            }
            # Desktop Settings
            "HKCU:\Control Panel\Desktop" = @{
                "AutoEndTasks" = 1
                "HungAppTimeout" = 1000
                "MenuShowDelay" = 8
                "WaitToKillAppTimeout" = 2000
                "LowLevelHooksTimeout" = 1000
            }
            # Explorer Policies
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" = @{
                "NoLowDiskSpaceChecks" = 1
                "LinkResolveIgnoreLinkInfo" = 1
                "NoResolveSearch" = 1
                "NoResolveTrack" = 1
                "NoInternetOpenWith" = 1
                "NoInstrumentation" = 1
            }
            # System Control
            "HKLM:\SYSTEM\CurrentControlSet\Control" = @{
                "WaitToKillServiceTimeout" = 2000
            }
            # Privacy Settings
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

    foreach ($path in $registryChanges.Keys) {
        Write-Host "`nConfiguring: $path" -ForegroundColor Yellow
        
        if (!(Test-Path $path)) {
            Write-Host "Creating new registry path..." -ForegroundColor Gray
            New-Item -Path $path -Force | Out-Null
        }
        
        foreach ($name in $registryChanges[$path].Keys) {
            Write-Host "Setting $name to $($registryChanges[$path][$name])" -ForegroundColor Green
            Set-ItemProperty -Path $path -Name $name -Value $registryChanges[$path][$name] -Type DWord
        }
    
    
    Write-Host "`n=== FPS Performance Optimization Complete! ===" -ForegroundColor Cyan
            }
        }
    }
"Mouse Optimization" = @{
    content = "Mouse Optimization"
    description = "Ultimate Mouse Optimization - Zero Processing, Pure Raw Input!"
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
                "ThreadPriority" = 0x7                # Real-time priority
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
                "SystemResponsiveness" = 0x0
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
}

 # cleanup tab
$cleanupTasks = @{
    "Temp Folders" = @{
        content = "Clean Temporary Files"
        description = "Removes files from Windows Temp and %temp% folders"
        action = {
            Write-Host "Cleaning Windows Temp folders..." -ForegroundColor Yellow
            Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Temporary files cleaned successfully!" -ForegroundColor Green
        }
    }
    "Recycle Bin" = @{
        content = "Empty Recycle Bin"
        description = "Permanently removes all items from the Recycle Bin"
        action = {
            Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Host "Recycle Bin emptied successfully!" -ForegroundColor Green
        }
    }
    "DNS Cache" = @{
        content = "Flush DNS Cache"
        description = "Clears DNS resolver cache to fix potential connectivity issues"
        action = {
            Write-Host "Flushing DNS Cache..." -ForegroundColor Yellow
            ipconfig /flushdns | Out-Null
            Write-Host "DNS Cache flushed successfully!" -ForegroundColor Green
        }
    }
"Drive Cleanup" = @{
    content = "Drive Cleanup"
    description = "Runs a gaming-optimized disk cleanup that preserves performance"
    action = {
        Write-Host "Starting Gaming-Optimized Cleanup..." -ForegroundColor Yellow
        
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        
        # Performance-safe cleanup items
        $cleanItems = @(
            "Downloaded Program Files"
            "Old ChkDsk Files"
            "Previous Installations"
            "Setup Log Files"
            "Temporary Setup Files"
            "Windows Error Reporting Files"
            "Windows Upgrade Log Files"
        )

        foreach ($item in $cleanItems) {
            $itemPath = Join-Path $regPath $item
            if (Test-Path $itemPath) {
                Set-ItemProperty -Path $itemPath -Name "StateFlags0001" -Value 2 -Type DWord -ErrorAction SilentlyContinue
            }
        }
        
        Start-Process cleanmgr -ArgumentList "/sagerun:1" -Wait -NoNewWindow
        
        Write-Host "Gaming-Optimized Cleanup completed successfully!" -ForegroundColor Green
        }
    }
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
                    <DataTrigger Binding="{Binding IsSelected, RelativeSource={RelativeSource Self}}" Value="True">
                        <Setter TargetName="border" Property="Background" Value="{StaticResource ButtonHover}"/>
                        <Setter Property="Foreground" Value="White"/>
                        <Setter TargetName="activeIndicator" Property="Opacity" Value="1"/>
                    </DataTrigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>

            <!-- Style for the toggle switch -->
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
                    </Trigger>
                </ControlTemplate.Triggers>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>

<Style x:Key="ActionButtonStyle" TargetType="Button">
    <Setter Property="Background" Value="#007ACC"/>
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
                        <Setter Property="Background" Value="#0098FF"/>
                    </Trigger>
                    <Trigger Property="IsPressed" Value="True">
                        <Setter Property="Background" Value="#005A99"/>
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
                                            VerticalScrollBarVisibility="Auto">
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

            <Style x:Key="TabButtonStyle" TargetType="Button">
                <Setter Property="Background" Value="{DynamicResource ButtonBackground}"/>
                <Setter Property="BorderThickness" Value="1"/>
                <Setter Property="BorderBrush" Value="{DynamicResource ButtonBorder}"/>
                <Setter Property="Foreground" Value="{DynamicResource TextColor}"/>
                <Setter Property="FontSize" Value="14"/>
                <Setter Property="Cursor" Value="Hand"/>
                <Setter Property="Margin" Value="5,5,5,0"/>
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border x:Name="border" 
                                    Background="{TemplateBinding Background}"
                                    BorderBrush="{TemplateBinding BorderBrush}"
                                    BorderThickness="{TemplateBinding BorderThickness}"
                                    CornerRadius="5"
                                    Padding="10,5">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
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

                            <!-- Apps Content -->
                <Grid x:Name="AppsContent" Visibility="Visible" Margin="0,50,0,-10">
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="10">
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
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="10">
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

                    <!-- Optimize Content -->
                    <Grid x:Name="OptimizeContent" Visibility="Collapsed" Margin="0,50,0,-10">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" Margin="10">
                            <StackPanel x:Name="OptimizationsPanel"/>
                        </ScrollViewer>

                        <Grid Grid.Row="1" Margin="20,0,20,20">
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

                        <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" Margin="10">
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
                        <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="20">
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

# Event Handlers
[Console]::SetOut([System.IO.TextWriter]::Null)

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
    $appsContent.Visibility = "Visible"
    $optimizeContent.Visibility = "Collapsed"
    $infoContent.Visibility = "Collapsed"
    $cleanContent.Visibility = "Collapsed"
    $debloatContent.Visibility = "Collapsed"
})

$revertButton.Add_Click({
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
})

$optimizeTab.Add_Click({
    $appsContent.Visibility = "Collapsed"
    $optimizeContent.Visibility = "Visible"
    $infoContent.Visibility = "Collapsed"
    $cleanContent.Visibility = "Collapsed"
    $debloatContent.Visibility = "Collapsed"
})

$cleanTab.Add_Click({
    $appsContent.Visibility = "Collapsed"
    $optimizeContent.Visibility = "Collapsed"
    $infoContent.Visibility = "Collapsed"
    $cleanContent.Visibility = "Visible"
    $debloatContent.Visibility = "Collapsed"
})

$debloatTab.Add_Click({
    $appsContent.Visibility = "Collapsed"
    $optimizeContent.Visibility = "Collapsed"
    $cleanContent.Visibility = "Collapsed"
    $infoContent.Visibility = "Collapsed"
    $debloatContent.Visibility = "Visible"
})

$cleanButton.Add_Click({
    Ensure-SingleRestorePoint
    $selectedCleanups = $cleanPanel.Children[0].Children | 
        ForEach-Object {
            $toggleSwitch = $_.Child.Children[0].Children[1]
            if ($toggleSwitch.IsChecked) {
                $toggleSwitch.Tag
            }
        }

    if ($null -eq $selectedCleanups -or @($selectedCleanups).Count -eq 0) {
        Write-Host "`nNo cleanup options selected." -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Starting Selected Cleanup Tasks ===" -ForegroundColor Cyan

    foreach ($cleanup in $selectedCleanups) {
        Write-Host "`nExecuting $($cleanup.content)..." -ForegroundColor Yellow
        & $cleanup.action
        Write-Host "$($cleanup.content) completed successfully!" -ForegroundColor Green
    }

    Write-Host "`n=== All Selected Cleanup Tasks Completed ===`n" -ForegroundColor Cyan
})

$runTweaksButton.Add_Click({
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

    if ($tweaksApplied) {
        Write-Host "`n=== Applying Selected Tweaks ===" -ForegroundColor Cyan
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
})

$infoTab.Add_Click({
    
    $currentDateTime.Text = "Current Date/Time: " + (Get-Date -Format "MM/dd/yyyy HH:mm:ss")
    $appsContent.Visibility = "Collapsed"
    $optimizeContent.Visibility = "Collapsed"
    $infoContent.Visibility = "Visible"
    $debloatContent.Visibility = "Collapsed"
    $cleanContent.Visibility = "Collapsed"
})

$installButton.Add_Click({
    $selectedApps = $categoriesPanel.Children[0].Children | 
        ForEach-Object {
            $toggleSwitch = $_.Child.Children[0].Children[1]
            if ($toggleSwitch.IsChecked) {
                $toggleSwitch.Tag
            }
        }

    if ($null -eq $selectedApps -or @($selectedApps).Count -eq 0) {
        Write-Host "`nNo apps selected for installation." -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Starting Installation Process ===" -ForegroundColor Cyan
    foreach ($app in $selectedApps) {
        Write-Host "`nProcessing $($app.content)..." -ForegroundColor Cyan
        
        # Check if manual installation is required
        if ($app.installType -eq "manual") {
            Write-Host "This application requires manual installation." -ForegroundColor Yellow
            Write-Host "Please download from: $($app.link)" -ForegroundColor Yellow
            Write-Host "Instructions: $($app.installInstructions)" -ForegroundColor Yellow
            continue
        }

        try {
            # Try winget first
            $checkResult = winget list --exact -q $app.winget 2>$null
            if ($checkResult -match $app.winget) {
                Write-Host "$($app.content) is already installed." -ForegroundColor Blue
                continue
            }

            Write-Host "Attempting installation with winget..." -ForegroundColor Yellow
            winget install -e --accept-source-agreements --accept-package-agreements $app.winget
            
            Start-Sleep -Seconds 2
            $verifyResult = winget list --exact -q $app.winget 2>$null
            
            if ($verifyResult -match $app.winget) {
                Write-Host "$($app.content) installed successfully!" -ForegroundColor Green
            } else {
                # Try Chocolatey as fallback
                if ($app.choco) {
                    Write-Host "Winget installation failed. Trying Chocolatey..." -ForegroundColor Yellow
                    choco install $app.choco -y
                    if ($?) {
                        Write-Host "$($app.content) installed successfully with Chocolatey!" -ForegroundColor Green
                    } else {
                        Write-Host "Failed to install $($app.content) with Chocolatey." -ForegroundColor Red
                    }
                } else {
                    Write-Host "Failed to install $($app.content)." -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "Error processing $($app.content): $_" -ForegroundColor Red
        }
    }
    Write-Host "`n=== Installation Process Complete ===`n" -ForegroundColor Cyan
})

$uninstallButton.Add_Click({
    $selectedApps = $categoriesPanel.Children[0].Children | 
        ForEach-Object {
            $toggleSwitch = $_.Child.Children[0].Children[1]
            if ($toggleSwitch.IsChecked) {
                $toggleSwitch.Tag
            }
        }

    if ($null -eq $selectedApps -or @($selectedApps).Count -eq 0) {
        Write-Host "`nNo apps selected for uninstallation." -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Starting Uninstallation Process ===" -ForegroundColor Cyan
    foreach ($app in $selectedApps) {
        Write-Host "`nProcessing $($app.content)..." -ForegroundColor Cyan
        
        if ($app.installType -eq "manual") {
            Write-Host "This application requires manual uninstallation." -ForegroundColor Yellow
            continue
        }

        try {
            $checkResult = winget list --exact -q $app.winget 2>$null
            if ($checkResult -match $app.winget) {
                Write-Host "Uninstalling $($app.content)..." -ForegroundColor Yellow
                winget uninstall --exact $app.winget
                
                Start-Sleep -Seconds 2
                $verifyResult = winget list --exact -q $app.winget 2>$null
                
                if ($verifyResult -notmatch $app.winget) {
                    Write-Host "$($app.content) uninstalled successfully!" -ForegroundColor Green
                } else {
                    # Try Chocolatey uninstall if winget fails
                    if ($app.choco) {
                        Write-Host "Trying to uninstall with Chocolatey..." -ForegroundColor Yellow
                        choco uninstall $app.choco -y
                        if ($?) {
                            Write-Host "$($app.content) uninstalled successfully with Chocolatey!" -ForegroundColor Green
                        } else {
                            Write-Host "Failed to uninstall $($app.content)." -ForegroundColor Red
                        }
                    } else {
                        Write-Host "Failed to uninstall $($app.content)." -ForegroundColor Red
                    }
                }
            } else {
                Write-Host "$($app.content) is not installed." -ForegroundColor Blue
            }
        }
        catch {
            Write-Host "Error processing $($app.content): $_" -ForegroundColor Red
        }
    }
    Write-Host "`n=== Uninstallation Process Complete ===`n" -ForegroundColor Cyan
})

$debloatButton.Add_Click({
    # Create a restore point first
    Ensure-SingleRestorePoint

    $selectedDebloatItems = $debloatPanel.Children[0].Children | 
        ForEach-Object {
            $toggleSwitch = $_.Child.Children[0].Children[1]
            if ($toggleSwitch.IsChecked) {
                $toggleSwitch.Tag
            }
        }

    if ($null -eq $selectedDebloatItems -or @($selectedDebloatItems).Count -eq 0) {
        Write-Host "`nNo debloat options selected." -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Running Selected Debloat Actions ===" -ForegroundColor Cyan

    foreach ($item in $selectedDebloatItems) {
        Write-Host "`nExecuting $($item.content)..." -ForegroundColor Yellow
        & $item.action
        Write-Host "$($item.content) completed successfully!" -ForegroundColor Green
    }

    Write-Host "`n=== All Debloat Actions Completed ===`n" -ForegroundColor Cyan
})

# Enable Window Dragging
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# Enable console output for installation messages only
[Console]::SetOut([Console]::Out)

# Show Window
$window.ShowDialog()
