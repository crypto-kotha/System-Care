[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [bool]$OptimizeCDrive = $true,          # Defragmentation, NTFS compression Default to true, its take time
    [Parameter(Mandatory=$false)]
    [bool]$Schedule = $false        # Enable or disable daily scheduling
)

# Function to set up a daily task in Task Scheduler
function Set-DailyTask {
    param (
        [string]$ScriptPath
    )
    Write-Host "Setting up a daily schedule for the script..." -ForegroundColor Yellow
    try {
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
        $trigger = New-ScheduledTaskTrigger -Daily -At "12:01AM"  # Set the time for the task
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        Register-ScheduledTask -TaskName "DailySystemOptimization" -Action $action -Trigger $trigger -Settings $settings -Force
        Write-Host "Daily schedule created successfully at 12.01 AM." -ForegroundColor Green
    } catch {
        Write-Host "Failed to create a scheduled task: $_" -ForegroundColor Red
    }
}

# Main script logic
if ($Schedule) {
    $currentScriptPath = $MyInvocation.MyCommand.Path
    Set-DailyTask -ScriptPath $currentScriptPath
    exit 0
}

# Script to optimize Dell Inspiron laptop with AMD Athlon Silver 3050U
Write-Host "Starting system optimization..." -ForegroundColor Green

# Function to check if running as administrator
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
    exit 1
}

# Function to get system information
function Get-SystemInfo {
    Write-Host "Computer Name: $($env:COMPUTERNAME)" -ForegroundColor Yellow
    $systemInfo = Get-WmiObject -Class Win32_ComputerSystem
    Write-Host "Processor: $($systemInfo.NumberOfProcessors) x $($systemInfo.NumberOfLogicalProcessors) cores" -ForegroundColor White
    Write-Host "Total RAM: $([Math]::Round($systemInfo.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor White
}
    Get-SystemInfo

# Function to handle Windows Update Service operations
function Manage-WindowsUpdate {
    Write-Host "Managing Windows Update Service..." -ForegroundColor White
    try {
        $service = Get-Service -Name wuauserv
        
        if ($service.Status -eq 'Running') {
            Write-Host "Attempting to stop Windows Update Service..." -ForegroundColor Yellow
            Stop-Service -Name wuauserv -Force -ErrorAction Stop
            Start-Sleep -Seconds 5 # Give the service time to stop
        }
        
        Write-Host "Clearing Windows Update Cache..." -ForegroundColor White
        Remove-Item -Path "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "Starting Windows Update Service..." -ForegroundColor Yellow
        Start-Service -Name wuauserv -ErrorAction Stop
        Start-Sleep -Seconds 3 # Give the service time to start
        
        if ((Get-Service -Name wuauserv).Status -eq 'Running') {
            Write-Host "Windows Update Service successfully managed" -ForegroundColor Green
        } else {
            throw "Service did not start properly"
        }
    }
    catch {
        Write-Host "Warning: Issues managing Windows Update Service. Continuing with other optimizations..." -ForegroundColor Yellow
        Write-Host "Error details: $_" -ForegroundColor Yellow
        # Don't exit - continue with other optimizations
    }
}

# Function to clean junk files with enhanced error handling
function Clean-JunkFiles {
    Write-Host "`nStarting junk file cleanup..." -ForegroundColor Cyan
    
    # Create a hashtable of cleanup locations
    $cleanupPaths = @{
        "Temp Files" = "$env:TEMP\*"
        "Windows Error Reports" = "C:\ProgramData\Microsoft\Windows\WER\*"
        "Thumbnail Cache" = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db"
    }
    
    foreach ($location in $cleanupPaths.GetEnumerator()) {
        try {
            $size = (Get-ChildItem $location.Value -Recurse -ErrorAction SilentlyContinue | 
                    Measure-Object -Property Length -Sum).Sum / 1MB
            
            Write-Host "Cleaning $($location.Key) (Size: $([Math]::Round($size, 2)) MB)..." -ForegroundColor White
            Remove-Item -Path $location.Value -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Warning: Could not clean $($location.Key): $_" -ForegroundColor Yellow
        }
    }
    
    # Handle Windows Update separately
    Manage-WindowsUpdate
    
    # Flush DNS cache
    try {
        Write-Host "Flushing DNS Cache..." -ForegroundColor White
        $dnsCacheOutput = ipconfig /flushdns
        Write-Host "$dnsCacheOutput" -ForegroundColor Green
    }
    catch {
        Write-Host "Warning: Could not flush DNS cache: $_" -ForegroundColor Yellow
    }
}

# Function to optimize C drive with improved error handling and timeout mechanisms
function Optimize-CDrive {
    Write-Host "Optimizing C drive..." -ForegroundColor Cyan
    
    # Run disk cleanup with timeout
    try {
        Write-Host "Starting disk cleanup..." -ForegroundColor White
        $cleanMgrProcess = Start-Process -FilePath cleanmgr -ArgumentList '/sagerun:1' -PassThru
        
        # Wait up to 30 minutes for disk cleanup
        $timeout = 1800
        if (-not $cleanMgrProcess.WaitForExit($timeout * 1000)) {
            Write-Host "Disk cleanup is taking too long, attempting to terminate..." -ForegroundColor Yellow
            Stop-Process -Id $cleanMgrProcess.Id -Force
            throw "Disk cleanup timed out after $timeout seconds"
        }
    }
    catch {
        Write-Host "Warning: Issue with disk cleanup: $_" -ForegroundColor Yellow
    }
    
    # Check drive type and optimize accordingly with timeout
    try {
        $systemDrive = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq "0" }
        
        if ($systemDrive.MediaType -eq "SSD") {
            Write-Host "SSD detected, running TRIM..." -ForegroundColor White
            $job = Start-Job -ScriptBlock { 
                Optimize-Volume -DriveLetter C -ReTrim -Verbose 
            }
            
            # Wait up to 10 minutes for TRIM
            if (-not (Wait-Job $job -Timeout 600)) {
                Remove-Job -Job $job -Force
                throw "TRIM operation timed out after 600 seconds"
            }
            
            Receive-Job -Job $job
            Remove-Job -Job $job
        }
        else {
            Write-Host "HDD detected, running defragmentation..." -ForegroundColor White
            $job = Start-Job -ScriptBlock { 
                Optimize-Volume -DriveLetter C -Defrag -Verbose 
            }
            
            # Wait up to 2 hours for defragmentation
            if (-not (Wait-Job $job -Timeout 7200)) {
                Remove-Job -Job $job -Force
                throw "Defragmentation timed out after 7200 seconds"
            }
            
            Receive-Job -Job $job
            Remove-Job -Job $job
        }
    }
    catch {
        Write-Host "Warning: Issue with drive optimization: $_" -ForegroundColor Yellow
    }
    
    # NTFS compression with timeout and error handling
    try {
        Write-Host "Applying NTFS compression to selected folders..." -ForegroundColor White
        $compressionJobs = @(
            Start-Job -ScriptBlock { compact /c /s:"C:\Windows\Help" /i /q },
            Start-Job -ScriptBlock { compact /c /s:"C:\Windows\assembly" /i /q }
        )
        
        # Wait up to 15 minutes for compression
        foreach ($job in $compressionJobs) {
            if (-not (Wait-Job $job -Timeout 900)) {
                Remove-Job -Job $job -Force
                Write-Host "Warning: NTFS compression timed out for some folders" -ForegroundColor Yellow
                continue
            }
            Receive-Job -Job $job
            Remove-Job -Job $job
        }
    }
    catch {
        Write-Host "Warning: Issue with NTFS compression: $_" -ForegroundColor Yellow
    }
    
    Write-Host "C drive optimization completed" -ForegroundColor Green
}

# Function for additional performance optimizations
function Add-PerformanceOptimizations {
    
    Write-Host "Diactivating unnecessary Windows services..." -ForegroundColor Cyan 
    $servicesToDisable = @(
        "DiagTrack",          # Connected User Experiences and Telemetry
        "WSearch",            # Windows Search (can be enabled if needed)
        "SysMain",            # Superfetch
        "TabletInputService"  # Tablet Input Service (not needed for non-touch devices)
        "Parental Controls",
        "wisvc",    # Windows Insider Service
        "MapsBroker", # Downloaded Maps Manager
        "WerSvc",   # Error Reporting Service
        "TabletInputService", # Touch Keyboard and Handwriting Panel Service
        "GameDVR"   # GameDVR and Broadcast (disabling via registry)
    )
    # Disable and stop services
    foreach ($service in $servicesToDisable) {
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Disabled service: $service"
    }
    # This disables the Xbox Game Bar recording and broadcasting features
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Name "Value" -Value 0
    Write-Host "Disabled GameDVR and Broadcast"
    
    foreach ($service in $servicesToDisable) {
        Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
    }
    
    # Optimize network settings
    netsh int tcp set global autotuninglevel=normal
    netsh int tcp set global dca=enabled
    
    # Disable Fast Startup (can cause issues)
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -Type DWord
    
    # Optimize AMD GPU-specific settings
    $amdRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
    if (Test-Path $amdRegistryPath) {
        # Enable hardware acceleration
        Set-ItemProperty -Path $amdRegistryPath -Name "KMD_EnableComputePreemption" -Value 1 -Type DWord -ErrorAction SilentlyContinue
        # Optimize power settings for AMD GPU
        Set-ItemProperty -Path $amdRegistryPath -Name "PP_ThermalAutoThrottlingEnable" -Value 0 -Type DWord -ErrorAction SilentlyContinue
    }
}

# Main execution block
try {
    # Check for administrator privileges
    if (-not (Test-Administrator)) {
        Write-Host "This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
        exit 1
    }

    # Configure Power Settings
    Write-Host "Configuring power settings..." -ForegroundColor Yellow
    powercfg /setactive SCHEME_BALANCED # don't change
    #powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a # don't remove
    Write-Host "Power Savings set BALANCED..." -ForegroundColor Cyan
 
    # Prevent the computer from sleeping #
    Write-Host "Disabling sleep mode to keep PC always on..."
    powercfg /change standby-timeout-ac 0  # No sleep when plugged in # don't change
    powercfg /change standby-timeout-dc 0  # No sleep on battery # don't change
    Write-Host "Always-ON Success..." -ForegroundColor Cyan

    # Configure processor power management
    Write-Host "Configuring CPU Process management..."
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 90   # don't change
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 90   # don't change
    Write-Host "Current CPU Usage set 90% Success..." -ForegroundColor Cyan

    Write-Host "Configuring CPU Idl Process management..."
    powercfg /setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 25   # don't change
    powercfg /setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMIN 25   # don't change
    Write-Host "Current CPU idl set 25% Success..." -ForegroundColor Cyan

    # Configure display timeouts
    Write-Host "Configuring Display Timeout..."
    powercfg /change monitor-timeout-ac 1  # don't change
    powercfg /change monitor-timeout-dc 1   # don't change
    Write-Host "Display Timeout setup 1minute Success..." -ForegroundColor Cyan

    # Configure hard disk timeouts
    Write-Host "Configuring SSD Timeout..."
    powercfg /change disk-timeout-ac 0 # don't change
    powercfg /change disk-timeout-dc 0 # don't change
    Write-Host "SSD Always-ON Success..." -ForegroundColor Cyan

    # Disable Hibernation
    Write-Host "Disabling hibernation..."
    powercfg /hibernate off # don't change
    Write-Host "Always-ON Success..." -ForegroundColor Cyan

    # Configure Windows native memory compression
    Enable-MMAgent -MemoryCompression # don't change

    # Configure Windows Page File (Swap)
    Write-Host "Configuring Windows Page File Swap..."
    $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
    $totalRAM = [Math]::Round($computerSystem.TotalPhysicalMemory / 1GB)
    $pageFileSize = [Math]::Max(4, [Math]::Min(16, $totalRAM))  # Between 4GB and 16GB
    Write-Host "Swap Activation Success..." -ForegroundColor Cyan

    $pageFile = Get-WmiObject -Class Win32_PageFileSetting
    if ($pageFile) {
        $pageFile.InitialSize = ($pageFileSize * 2048)
        $pageFile.MaximumSize = ($pageFileSize * 2048)
        $pageFile.Put()
    }

    # Configure Visual Effects for Performance
    Write-Host "Configuring Windows Visual Effects..."
    $path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    try {
        if (!(Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Set-ItemProperty -Path $path -Name "VisualFXSetting" -Value 2 -Type DWord -Force
    }
    catch {
        Write-Host "Unable to set visual effects. Please configure manually through System Properties." -ForegroundColor Yellow
    }
    Write-Host "Reduce Windows Visual Effects Success..." -ForegroundColor Cyan

    # Run optimization functions
    Clean-JunkFiles

    Write-Host "Starting C drive Optimization..."
    if ($OptimizeCDrive) {
        Optimize-CDrive
    } else {
        Write-Host "Skipping C drive Optimization..." -ForegroundColor Yellow
    }
    Add-PerformanceOptimizations

    # Configure RAM management
    Write-Host "Configuring additional RAM management..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1
    Write-Host "RAM Management Activation Success..." -ForegroundColor Cyan

    # Configure network adapter power settings
    Write-Host "Configuring network adapter power settings..."
    $adapters = Get-NetAdapter
    foreach ($adapter in $adapters) {
        try {
            $adapterRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\$($adapter.DeviceID)"
            if (Test-Path $adapterRegPath) {
                Set-ItemProperty -Path $adapterRegPath -Name "PnPCapabilities" -Value 24 -Type DWord -Force
                Write-Host "Network adapter $($adapter.Name) configured to stay on during sleep" -ForegroundColor Cyan
            }
        } catch {
            Write-Host "Unable to configure network adapter $($adapter.Name)" -ForegroundColor Yellow
        }
    }

    # Configure Graphics Settings for AMD Radeon
    Write-Host "Optimizing Graphics settings..."
    $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (!(Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    Set-ItemProperty -Path $regPath -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $regPath -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

    # Configure AMD specific settings
    $amdKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
    if (Test-Path $amdKeyPath) {
        Write-Host "Configuring AMD Radeon settings..."
        try {
            Set-ItemProperty -Path $amdKeyPath -Name "EnableUlps" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $amdKeyPath -Name "PP_SclkDeepSleepDisable" -Value 1 -Type DWord -Force
        }
        catch {
            Write-Host "Unable to modify AMD settings. Some settings may require manual configuration." -ForegroundColor Yellow
        }
    }

    # Apply all changes
    powercfg /setactive SCHEME_CURRENT

    Write-Host "`nOptimization complete! Please restart your computer for all changes to take effect." -ForegroundColor Green

} catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
}
