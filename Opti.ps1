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
        category = "Browsers"
        choco = "googlechrome"
        content = "Chrome"
        description = "Google Chrome is a widely used web browser known for its speed, simplicity, and seamless integration with Google services."
        link = "https://www.google.com/chrome/"
        winget = "Google.Chrome"
    }
    "Firefox" = @{
        category = "Browsers"
        choco = "firefox"
        content = "Firefox"
        description = "Mozilla Firefox is a fast, privacy-focused browser with extensive customization options."
        link = "https://www.mozilla.org/firefox/"
        winget = "Mozilla.Firefox"
    }
    "Brave" = @{
        category = "Browsers"
        choco = "brave"
        content = "Brave"
        description = "Brave is a privacy-focused web browser that blocks ads and trackers, offering a faster and safer browsing experience."
        link = "https://www.brave.com"
        winget = "Brave.Brave"
    }
    "Discord" = @{
        category = "Communications"
        choco = "discord"
        content = "Discord"
        description = "Discord is a popular platform for chat, voice, and video communication."
        link = "https://discord.com/"
        winget = "Discord.Discord"
    }
    "Steam" = @{
        category = "Games"
        choco = "steam"
        content = "Steam"
        description = "Steam is the ultimate destination for playing, discussing, and creating games."
        link = "https://store.steampowered.com/"
        winget = "Valve.Steam"
    }
    "7-Zip" = @{
        category = "Utilities"
        choco = "7zip"
        content = "7-Zip"
        description = "7-Zip is a file archiver with a high compression ratio and strong encryption."
        link = "https://7-zip.org/"
        winget = "7zip.7zip"
    }
    "WinRAR" = @{
        category = "Utilities"
        choco = "winrar"
        content = "WinRAR"
        description = "WinRAR is a powerful archive manager that allows you to create, manage, and extract compressed files."
        link = "https://www.win-rar.com/"
        winget = "RARLab.WinRAR"
    }
    "OneDrive" = @{
        category = "Microsoft Tools"
        choco = "onedrive"
        content = "OneDrive"
        description = "OneDrive is a cloud storage service provided by Microsoft, allowing users to store and share files securely across devices."
        link = "https://onedrive.live.com/"
        winget = "Microsoft.OneDrive"
    }
}

$optimizations = @{
    "Ping Optimization" = @{
        category = "Performance"
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
    category = "Performance"
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
        
"Remove OneDrive" = @{
    category = "Debloat Windows"
    content = "Remove OneDrive"
    description = "Completely removes OneDrive, migrates files to local folders, and prevents it from reinstalling"
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

    "services" = @{
    category = "Performance"
    content = "Set Services to Manual"
    description = "Sets various non-essential system services to manual, allowing them to start only when required. This helps free up resources without disrupting functionality, as needed services will launch automatically when required."
    action = {
        Write-Host "Setting services to their optimized state..." -ForegroundColor Cyan
        
        $services = @(
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
            @{ Name = "DoSvc"; StartupType = "AutomaticDelayedStart"; OriginalType = "Automatic" },
            @{ Name = "DsSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DsmSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "DusmSvc"; StartupType = "Automatic"; OriginalType = "Automatic" },
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
            @{ Name = "SgrmBroker"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SharedAccess"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "SharedRealitySvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "ShellHWDetection"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SmsRouter"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "Spooler"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SstpSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "StateRepository"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "StiSvc"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "StorSvc"; StartupType = "Manual"; OriginalType = "Automatic" },
            @{ Name = "SysMain"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "SystemEventsBroker"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "TabletInputService"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TapiSrv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "TermService"; StartupType = "Automatic"; OriginalType = "Automatic" },
            @{ Name = "TextInputManagementService"; StartupType = "Manual"; OriginalType = "Automatic" },
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
            @{ Name = "wuauserv"; StartupType = "Manual"; OriginalType = "Manual" },
            @{ Name = "wudfsvc"; StartupType = "Manual"; OriginalType = "Manual" }
        )
        foreach ($service in $services) {
            if ($service.Name.Contains("*")) {
                $baseServiceName = $service.Name.TrimEnd("*")
                Get-Service | Where-Object { $_.Name -like "$baseServiceName*" } | ForEach-Object {
                    Set-Service -Name $_.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue
                }
            } else {
                Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction SilentlyContinue
            }
        }
        
        Write-Host "Services have been optimized successfully!" -ForegroundColor Green
        }
    }
}
 # cleanup tab
$cleanupTasks = @{
    "Temp Folders" = @{
        category = "System Cleanup"
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
        category = "System Cleanup"
        content = "Empty Recycle Bin"
        description = "Permanently removes all items from the Recycle Bin"
        action = {
            Write-Host "Emptying Recycle Bin..." -ForegroundColor Yellow
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Host "Recycle Bin emptied successfully!" -ForegroundColor Green
        }
    }
    "DNS Cache" = @{
        category = "Network Cleanup"
        content = "Flush DNS Cache"
        description = "Clears DNS resolver cache to fix potential connectivity issues"
        action = {
            Write-Host "Flushing DNS Cache..." -ForegroundColor Yellow
            ipconfig /flushdns | Out-Null
            Write-Host "DNS Cache flushed successfully!" -ForegroundColor Green
        }
    }
"Drive Cleanup" = @{
    category = "System Cleanup"
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
    Width="1380"
    Height="800"
    MaxWidth="1380"
    MaxHeight="800"
    ResizeMode="NoResize"
    WindowStartupLocation="CenterScreen">
    
    <Window.Resources>
        <ResourceDictionary>
            <SolidColorBrush x:Key="WindowBackground" Color="#1E1E1E"/>
            <SolidColorBrush x:Key="TextColor" Color="#FFFFFF"/>
            <SolidColorBrush x:Key="ButtonBackground" Color="#2D2D2D"/>
            <SolidColorBrush x:Key="ButtonHover" Color="#404040"/>
            <SolidColorBrush x:Key="ButtonPressed" Color="#505050"/>
            <SolidColorBrush x:Key="ButtonBorder" Color="#404040"/>
            
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

    <Border CornerRadius="10" Background="{DynamicResource WindowBackground}">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="40"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Title Bar -->
            <Grid Grid.Row="0" Background="Transparent">
                <TextBlock Text="Ritzy Optimizer" 
                         Foreground="{DynamicResource TextColor}" 
                         HorizontalAlignment="Left" 
                         VerticalAlignment="Center"
                         Margin="15,0,0,0"
                         FontSize="16"/>
                         
                <StackPanel Orientation="Horizontal" 
                          HorizontalAlignment="Center" 
                          VerticalAlignment="Center">
                    <Button x:Name="AppsTab" 
                            Content="Apps" 
                            Style="{StaticResource TabButtonStyle}" 
                            Width="100"/>
                    <Button x:Name="OptimizeTab" 
                            Content="Optimize" 
                            Style="{StaticResource TabButtonStyle}" 
                            Width="100"/>
                    <Button x:Name="InfoTab" 
                            Content="Info" 
                            Style="{StaticResource TabButtonStyle}" 
                            Width="100"/>
                    <Button x:Name="CleanTab" 
                            Content="Clean" 
                            Style="{StaticResource TabButtonStyle}" 
                            Width="100"/>
                    <Button x:Name="RevertButton"
                            Content="Revert Changes"
                            Background="#FF4444"
                            Foreground="White"
                            FontWeight="Bold"
                            Width="135"
                            Height="30"
                            Style="{StaticResource TabButtonStyle}"
                            Margin="20,5,5,0"/>
                </StackPanel>

                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,5,0">
                    <Button x:Name="ThemeToggle" Width="30" Height="20" Margin="0,0,5,0"
                            Style="{StaticResource WindowButtonStyle}">
                        <Path x:Name="ThemeIcon" 
                              Data="M12,7A5,5 0 0,1 17,12A5,5 0 0,1 12,17A5,5 0 0,1 7,12A5,5 0 0,1 12,7M12,9A3,3 0 0,0 9,12A3,3 0 0,0 12,15A3,3 0 0,0 15,12A3,3 0 0,0 12,9Z"
                              Fill="{DynamicResource TextColor}" 
                              Stretch="Uniform"/>
                    </Button>
                    <Button x:Name="MinimizeButton" Content="−" Width="30" Height="20" Margin="0,0,5,0"
                            Style="{StaticResource WindowButtonStyle}"/>
                    <Button x:Name="CloseButton" Content="×" Width="30" Height="20"
                            Style="{StaticResource WindowButtonStyle}"/>
                </StackPanel>
            </Grid>

            <!-- Main Content -->
            <Grid Grid.Row="1">
                <!-- Apps Content -->
                <Grid x:Name="AppsContent" Visibility="Visible">
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="10">
                        <StackPanel x:Name="CategoriesPanel"/>
                    </ScrollViewer>
                    <Button x:Name="InstallButton" 
                            Content="Install Selected" 
                            Style="{StaticResource TabButtonStyle}"
                            Width="120" 
                            Height="35" 
                            VerticalAlignment="Bottom"
                            HorizontalAlignment="Left" 
                            Margin="20,0,0,20"/>
                </Grid>

        <!-- Clean Content -->
        <Grid x:Name="CleanContent" Visibility="Collapsed">
           <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="10">
             <StackPanel x:Name="CleanPanel"/>
          </ScrollViewer>
          <Button x:Name="CleanButton" 
                Content="Clean System" 
                Style="{StaticResource TabButtonStyle}"
                Width="120" 
                Height="35" 
                VerticalAlignment="Bottom"
                HorizontalAlignment="Left" 
                Margin="20,0,0,20"/>
        </Grid>

<!-- Optimize Content -->
<Grid x:Name="OptimizeContent" Visibility="Collapsed">
    <Grid.RowDefinitions>
        <RowDefinition Height="*"/>
        <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>
    
    <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto" Margin="10">
        <StackPanel x:Name="OptimizationsPanel"/>
    </ScrollViewer>
    
    <!-- Bottom Controls -->
    <Grid Grid.Row="1" Margin="20,0,20,20">
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="Auto"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- Run Tweaks Button -->
        <Button x:Name="RunTweaksButton" 
                Grid.Column="0"
                Content="Run Tweaks" 
                Style="{StaticResource TabButtonStyle}"
                Width="120" 
                Height="35"/>

        <!-- DNS ComboBox -->
        <ComboBox x:Name="DNSComboBox" 
                  Grid.Column="1"
                  Width="120" 
                  Height="35"
                  HorizontalAlignment="Left"
                  Margin="20,0,0,0">
            <ComboBox.Resources>
                <SolidColorBrush x:Key="{x:Static SystemColors.WindowBrushKey}" Color="#1E1E1E"/>
                <SolidColorBrush x:Key="{x:Static SystemColors.HighlightBrushKey}" Color="#3E3E3E"/>
            </ComboBox.Resources>
            <ComboBox.Style>
                <Style TargetType="ComboBox">
                    <Setter Property="Background" Value="#333333"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                    <Setter Property="BorderBrush" Value="#454545"/>
                    <Setter Property="BorderThickness" Value="1"/>
                    <Setter Property="Template">
                        <Setter.Value>
                            <ControlTemplate TargetType="ComboBox">
                                <Grid>
                                    <Border x:Name="Border"
                                            Background="{TemplateBinding Background}"
                                            BorderBrush="{TemplateBinding BorderBrush}"
                                            BorderThickness="{TemplateBinding BorderThickness}"
                                            CornerRadius="5">
                                        <Grid>
                                            <Grid.ColumnDefinitions>
                                                <ColumnDefinition Width="*"/>
                                                <ColumnDefinition Width="Auto"/>
                                            </Grid.ColumnDefinitions>
                                            <ContentPresenter 
                                                Content="{TemplateBinding SelectionBoxItem}"
                                                ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}"
                                                Margin="10,0,0,0"
                                                VerticalAlignment="Center"/>
                                            <Path Grid.Column="1"
                                                  Data="M0,0 L4,4 L8,0"
                                                  Stroke="White"
                                                  StrokeThickness="2"
                                                  Margin="0,0,10,0"
                                                  VerticalAlignment="Center"/>
                                            <ToggleButton Grid.ColumnSpan="2"
                                                        IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}"
                                                        Opacity="0"/>
                                        </Grid>
                                    </Border>
                                    <Popup IsOpen="{TemplateBinding IsDropDownOpen}"
                                           Placement="Bottom"
                                           AllowsTransparency="True"
                                           Focusable="False">
                                        <Border Background="#333333"
                                                BorderBrush="#454545"
                                                BorderThickness="1"
                                                CornerRadius="5"
                                                Margin="0,2,0,0">
                                            <ScrollViewer MaxHeight="200">
                                                <StackPanel IsItemsHost="True"
                                                            KeyboardNavigation.DirectionalNavigation="Contained"/>
                                            </ScrollViewer>
                                        </Border>
                                    </Popup>
                                </Grid>
                                <ControlTemplate.Triggers>
                                    <Trigger Property="IsMouseOver" Value="True">
                                        <Setter TargetName="Border" Property="Background" Value="#404040"/>
                                    </Trigger>
                                </ControlTemplate.Triggers>
                            </ControlTemplate>
                        </Setter.Value>
                    </Setter>
                </Style>
            </ComboBox.Style>
            <ComboBox.ItemContainerStyle>
                <Style TargetType="ComboBoxItem">
                    <Setter Property="Background" Value="Transparent"/>
                    <Setter Property="Foreground" Value="White"/>
                    <Setter Property="Padding" Value="10,5"/>
                    <Style.Triggers>
                        <Trigger Property="IsMouseOver" Value="True">
                            <Setter Property="Background" Value="#454545"/>
                        </Trigger>
                        <Trigger Property="IsSelected" Value="True">
                            <Setter Property="Background" Value="#505050"/>
                        </Trigger>
                    </Style.Triggers>
                </Style>
            </ComboBox.ItemContainerStyle>
            
            <ComboBoxItem IsEnabled="False" IsSelected="True">Select DNS</ComboBoxItem>
            <ComboBoxItem>Cloudflare DNS</ComboBoxItem>
            <ComboBoxItem>Google DNS</ComboBoxItem>
            <ComboBoxItem>Default DNS</ComboBoxItem>
        </ComboBox>
    </Grid>
</Grid>

                <!-- Info Content -->
                <Grid x:Name="InfoContent" Visibility="Collapsed">
                    <ScrollViewer VerticalScrollBarVisibility="Auto" Margin="20">
                        <StackPanel Margin="10">
                            <!-- Tool Information -->
                            <Border Background="{DynamicResource ButtonBackground}" CornerRadius="10" Padding="20" Margin="0,0,0,20">
                                <StackPanel>
                                    <TextBlock Text="Tool Information" FontSize="24" FontWeight="Bold" Foreground="{DynamicResource TextColor}" Margin="0,0,0,15"/>
                                    <TextBlock Text="Current Date/Time: " Name="CurrentDateTime" Foreground="{DynamicResource TextColor}"/>
                                    <TextBlock Text="Version: 1.0.0" Foreground="{DynamicResource TextColor}"/>
                                    <TextBlock Text="Created by: Ritzy" Foreground="{DynamicResource TextColor}"/>
                                </StackPanel>
                            </Border>

                            <!-- Socials -->
                            <Border Background="{DynamicResource ButtonBackground}" CornerRadius="10" Padding="20" Margin="0,0,0,20">
                                <StackPanel>
                                    <TextBlock Text="Connect With Me" FontSize="24" FontWeight="Bold" Foreground="{DynamicResource TextColor}" Margin="0,0,0,15"/>
                                    <TextBlock Margin="0,0,0,10" Foreground="{DynamicResource TextColor}">
                                        <Run Text="YouTube: "/>
                                        <Run Text="https://www.youtube.com/@RitzySix"/>
                                    </TextBlock>
                                </StackPanel>
                            </Border>

                            <!-- Recent Updates -->
                            <Border Background="{DynamicResource ButtonBackground}" CornerRadius="10" Padding="20" Margin="0,0,0,20">
                                <StackPanel>
                                    <TextBlock Text="Recent Updates" FontSize="24" FontWeight="Bold" Foreground="{DynamicResource TextColor}" Margin="0,0,0,15"/>
                                    <TextBlock Foreground="{DynamicResource TextColor}" TextWrapping="Wrap">
                                        • v1.0.0 - Initial Release<LineBreak/>
                                        • Added Dark/Light Theme Toggle<LineBreak/>
                                        • Implemented App Installation System<LineBreak/>
                                        • Added Multiple Categories Support<LineBreak/>
                                        • Enhanced UI/UX Design
                                    </TextBlock>
                                </StackPanel>
                            </Border>

                            <!-- About Me -->
                            <Border Background="{DynamicResource ButtonBackground}" CornerRadius="10" Padding="20">
                                <StackPanel>
                                    <TextBlock Text="About Ritzy" FontSize="24" FontWeight="Bold" Foreground="{DynamicResource TextColor}" Margin="0,0,0,15"/>
                                    <TextBlock Foreground="{DynamicResource TextColor}" TextWrapping="Wrap">
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

# Theme State
$script:isDarkMode = $true

# Apps UI and GUI Pannelp
$wrapPanel = New-Object Windows.Controls.WrapPanel
$wrapPanel.Orientation = "Horizontal"
$wrapPanel.HorizontalAlignment = "Center"
$categoriesPanel.Children.Add($wrapPanel)

$categories = ($apps.Values | ForEach-Object { $_['category'] }) | Select-Object -Unique

foreach ($category in $categories) {
    $categoryBorder = New-Object Windows.Controls.Border
    $categoryBorder.Background = $window.Resources["ButtonBackground"]
    $categoryBorder.BorderBrush = $window.Resources["ButtonBorder"]
    $categoryBorder.BorderThickness = "1"
    $categoryBorder.CornerRadius = "10"
    $categoryBorder.Margin = "10,5,10,5"
    $categoryBorder.Padding = "15"
    $categoryBorder.Width = "225"
    $categoryBorder.MinHeight = "650"
    $categoryBorder.VerticalAlignment = "Stretch"

    $categoryStack = New-Object Windows.Controls.StackPanel
    $categoryStack.VerticalAlignment = "Stretch"
    
    $titleContainer = New-Object Windows.Controls.StackPanel
    $titleContainer.Orientation = "Horizontal"
    $titleContainer.Margin = "0,0,0,15"

    $categoryTitle = New-Object Windows.Controls.TextBlock
    $categoryTitle.Text = $category
    $categoryTitle.FontSize = "20"
    $categoryTitle.FontWeight = "Bold"
    $categoryTitle.Foreground = $window.Resources["TextColor"]
    
    $infoText = New-Object Windows.Controls.TextBlock
    $infoText.Text = "?"
    $infoText.Foreground = "#1E90FF"
    $infoText.FontSize = "16"
    $infoText.Margin = "5,0,0,0"
    $infoText.TextDecorations = "Underline"
    $infoText.VerticalAlignment = "Center"
    $infoText.Cursor = "Hand"

    $titleContainer.Children.Add($categoryTitle)
    $titleContainer.Children.Add($infoText)
    $categoryStack.Children.Add($titleContainer)

    $categoryApps = $apps.GetEnumerator() | Where-Object { $_.Value.category -eq $category }
    foreach ($app in $categoryApps) {
        $checkbox = New-Object Windows.Controls.CheckBox
        $checkbox.Foreground = $window.Resources["TextColor"]
        $checkbox.Margin = "0,5"
        $checkbox.Tag = $app.Value

        $checkboxContent = New-Object Windows.Controls.StackPanel
        $checkboxContent.Margin = "5,0,0,0"

        $appName = New-Object Windows.Controls.TextBlock
        $appName.Text = $app.Value.content
        $appName.FontWeight = "SemiBold"
        
        $checkboxContent.Children.Add($appName)
        $checkbox.Content = $checkboxContent

        $categoryStack.Children.Add($checkbox)
    }

    $categoryBorder.Child = $categoryStack
    $wrapPanel.Children.Add($categoryBorder)
}

# Create Optimization Categories UI
$optCategories = ($optimizations.Values | ForEach-Object { $_['category'] }) | Select-Object -Unique

foreach ($category in $optCategories) {
    $categoryBorder = New-Object Windows.Controls.Border
    $categoryBorder.Background = $window.Resources["ButtonBackground"]
    $categoryBorder.BorderBrush = $window.Resources["ButtonBorder"]
    $categoryBorder.BorderThickness = "1"
    $categoryBorder.CornerRadius = "5"
    $categoryBorder.Margin = "0,0,0,10"
    $categoryBorder.Padding = "10"

    $categoryStack = New-Object Windows.Controls.StackPanel
    $categoryTitle = New-Object Windows.Controls.TextBlock
    $categoryTitle.Text = $category
    $categoryTitle.FontSize = 18
    $categoryTitle.FontWeight = "Bold"
    $categoryTitle.Foreground = $window.Resources["TextColor"]
    $categoryTitle.Margin = "0,0,0,10"
    
    $categoryStack.Children.Add($categoryTitle)

    $categoryTweaks = $optimizations.GetEnumerator() | Where-Object { $_.Value.category -eq $category }
    foreach ($tweak in $categoryTweaks) {
        $checkbox = New-Object Windows.Controls.CheckBox
        $checkbox.Foreground = $window.Resources["TextColor"]
        $checkbox.Margin = "0,5"
        $checkbox.Tag = $tweak.Value

        $checkboxContent = New-Object Windows.Controls.StackPanel
        $tweakName = New-Object Windows.Controls.TextBlock
        $tweakName.Text = $tweak.Value.content
        $tweakName.FontWeight = "SemiBold"
        
        $tweakDescription = New-Object Windows.Controls.TextBlock
        $tweakDescription.Text = $tweak.Value.description
        $tweakDescription.TextWrapping = "Wrap"
        $tweakDescription.Opacity = 0.7

        $checkboxContent.Children.Add($tweakName)
        $checkboxContent.Children.Add($tweakDescription)
        $checkbox.Content = $checkboxContent

        $categoryStack.Children.Add($checkbox)
    }

    $categoryBorder.Child = $categoryStack
    $optimizationsPanel.Children.Add($categoryBorder)
}

# Create Cleanup Categories UI
$cleanCategories = ($cleanupTasks.Values | ForEach-Object { $_['category'] }) | Select-Object -Unique

foreach ($category in $cleanCategories) {
    $categoryBorder = New-Object Windows.Controls.Border
    $categoryBorder.Background = $window.Resources["ButtonBackground"]
    $categoryBorder.BorderBrush = $window.Resources["ButtonBorder"]
    $categoryBorder.BorderThickness = "1"
    $categoryBorder.CornerRadius = "5"
    $categoryBorder.Margin = "0,0,0,10"
    $categoryBorder.Padding = "10"

    $categoryStack = New-Object Windows.Controls.StackPanel
    $categoryTitle = New-Object Windows.Controls.TextBlock
    $categoryTitle.Text = $category
    $categoryTitle.FontSize = 18
    $categoryTitle.FontWeight = "Bold"
    $categoryTitle.Foreground = $window.Resources["TextColor"]
    $categoryTitle.Margin = "0,0,0,10"
    
    $categoryStack.Children.Add($categoryTitle)

    $categoryCleanups = $cleanupTasks.GetEnumerator() | Where-Object { $_.Value.category -eq $category }
    foreach ($cleanup in $categoryCleanups) {
        $checkbox = New-Object Windows.Controls.CheckBox
        $checkbox.Foreground = $window.Resources["TextColor"]
        $checkbox.Margin = "0,5"
        $checkbox.Tag = $cleanup.Value

        $checkboxContent = New-Object Windows.Controls.StackPanel
        $cleanupName = New-Object Windows.Controls.TextBlock
        $cleanupName.Text = $cleanup.Value.content
        $cleanupName.FontWeight = "SemiBold"
        
        $cleanupDescription = New-Object Windows.Controls.TextBlock
        $cleanupDescription.Text = $cleanup.Value.description
        $cleanupDescription.TextWrapping = "Wrap"
        $cleanupDescription.Opacity = 0.7

        $checkboxContent.Children.Add($cleanupName)
        $checkboxContent.Children.Add($cleanupDescription)
        $checkbox.Content = $checkboxContent

        $categoryStack.Children.Add($checkbox)
    }

    $categoryBorder.Child = $categoryStack
    $cleanPanel.Children.Add($categoryBorder)
}

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
})

$cleanTab.Add_Click({
    $appsContent.Visibility = "Collapsed"
    $optimizeContent.Visibility = "Collapsed"
    $infoContent.Visibility = "Collapsed"
    $cleanContent.Visibility = "Visible"
})

$cleanButton.Add_Click({
    Ensure-SingleRestorePoint
    $selectedCleanups = $cleanPanel.Children | 
        ForEach-Object { ($_.Child.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] -and $_.IsChecked }) } |
        ForEach-Object { $_.Tag }

    if ($selectedCleanups.Count -eq 0) {
        Write-Host "`nNo cleanup options selected." -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Starting Selected Cleanup Tasks ===" -ForegroundColor Cyan

    foreach ($cleanup in $selectedCleanups) {
        Write-Host "`nExecuting $($cleanup.name)..." -ForegroundColor Yellow
        & $cleanup.action
        Write-Host "$($cleanup.name) completed successfully!" -ForegroundColor Green
    }

    Write-Host "`n=== All Selected Cleanup Tasks Completed ===`n" -ForegroundColor Cyan
})

$runTweaksButton.Add_Click({
    Ensure-SingleRestorePoint

    $selectedTweaks = $optimizationsPanel.Children | 
        ForEach-Object { ($_.Child.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] -and $_.IsChecked }) } |
        ForEach-Object { $_.Tag }

    Write-Host "`n=== Applying Selected Tweaks ===" -ForegroundColor Cyan

    foreach ($tweak in $selectedTweaks) {
        Write-Host "`nApplying $($tweak.name)..." -ForegroundColor Yellow
        & $tweak.action
        Write-Host "$($tweak.name) applied successfully!" -ForegroundColor Green
    }

    # Get the selected DNS option
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
    }

    # Process other selected tweaks
    $selectedTweaks = $optimizationsPanel.Children | 
        ForEach-Object { ($_.Child.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] -and $_.IsChecked }) } |
        ForEach-Object { $_.Tag }
    
    foreach ($tweak in $selectedTweaks) {
        Write-Host "`nApplying $($tweak.name)..." -ForegroundColor Yellow
        & $tweak.action
        Write-Host "$($tweak.name) applied successfully!" -ForegroundColor Green
    }

    Write-Host "`n=== All Selected Tweaks Applied ===`n" -ForegroundColor Cyan
})

$infoTab.Add_Click({
    $currentDateTime.Text = "Current Date/Time: " + (Get-Date -Format "MM/dd/yyyy HH:mm:ss")
    $appsContent.Visibility = "Collapsed"
    $optimizeContent.Visibility = "Collapsed"
    $infoContent.Visibility = "Visible"
    $cleanContent.Visibility = "Collapsed"
})

$installButton.Add_Click({
    $selectedApps = $categoriesPanel.Children | 
        ForEach-Object { ($_.Child.Children | Where-Object { $_ -is [Windows.Controls.CheckBox] -and $_.IsChecked }) } |
        ForEach-Object { $_.Tag }

    if ($selectedApps.Count -eq 0) {
        Write-Host "`nNo apps selected for installation." -ForegroundColor Yellow
        return
    }

    Write-Host "`n=== Starting Installation Process ===" -ForegroundColor Cyan

    foreach ($app in $selectedApps) {
        Write-Host "`nProcessing $($app.content)..." -ForegroundColor Cyan
        
        # Check if app is installed (suppressing all output)
        $null = winget list --exact -q $app.winget 2>&1
        $checkInstalled = winget list --exact -q $app.winget | Out-String
        
        if ($checkInstalled -notmatch $app.winget) {
            Write-Host "Installing $($app.content)..." -ForegroundColor Yellow
            
            # Run installation with suppressed output
            $null = Start-Process winget -ArgumentList "install -e --accept-source-agreements --accept-package-agreements $($app.winget)" -Wait -NoNewWindow -RedirectStandardOutput "NUL" -RedirectStandardError "NUL"
            
            # Verify installation (suppressing all output)
            $null = winget list --exact -q $app.winget 2>&1
            $verifyInstalled = winget list --exact -q $app.winget | Out-String
            
            if ($verifyInstalled -match $app.winget) {
                Write-Host "$($app.content) installed successfully!" -ForegroundColor Green
            } else {
                Write-Host "Failed to install $($app.content)." -ForegroundColor Red
            }
        } else {
            Write-Host "$($app.content) is already installed." -ForegroundColor Blue
        }
    }

    Write-Host "`n=== Installation Process Complete ===`n" -ForegroundColor Cyan
})

# Enable Window Dragging
$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# Enable console output for installation messages only
[Console]::SetOut([Console]::Out)

# Show Window
$window.ShowDialog()
