# Run as Admin, gathers detailed system info, downloads tools, logs everything to a single file.

# === Elevate to admin if not already ===
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "Restarting script as administrator..."
    $args = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    Start-Process powershell -Verb RunAs -ArgumentList $args
    exit
}

# === Setup logging ===
$logFolder = Join-Path ([environment]::GetFolderPath('MyDocuments')) "RobloxPCCheckLogs"
if (-not (Test-Path $logFolder)) {
    New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
}
$logFile = Join-Path $logFolder ("RobloxPCCheck_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".txt")

function Write-Log {
    param([string]$text)
    Write-Host $text
    Add-Content -Path $logFile -Value $text
}

Write-Log "Starting RobloxPCCheck script at $(Get-Date)"
Write-Log ("=" * 80)

# === Create paths folder, empty paths.txt, download PathsParser and System Informer ===
$pathsFolder = Join-Path ([environment]::GetFolderPath('MyDocuments')) "paths"
if (-not (Test-Path $pathsFolder)) {
    New-Item -ItemType Directory -Path $pathsFolder -Force | Out-Null
    Write-Log "Created folder: $pathsFolder"
} else {
    Write-Log "Folder already exists: $pathsFolder"
}

$pathsTxt = Join-Path $pathsFolder "paths.txt"
if (-not (Test-Path $pathsTxt)) {
    New-Item -ItemType File -Path $pathsTxt -Force | Out-Null
    Write-Log "Created empty paths.txt"
} else {
    Write-Log "paths.txt already exists"
}

$pathsParserUrl = "https://github.com/spokwn/PathsParser/releases/download/v1.2/PathsParser.exe"
$pathsParserExe = Join-Path $pathsFolder "PathsParser.exe"
if (-not (Test-Path $pathsParserExe)) {
    Write-Log "Downloading PathsParser.exe..."
    try {
        Invoke-WebRequest -Uri $pathsParserUrl -OutFile $pathsParserExe -UseBasicParsing
        Write-Log "Downloaded PathsParser.exe"
    } catch {
        Write-Log "Failed to download PathsParser.exe: $_"
    }
} else {
    Write-Log "PathsParser.exe already exists."
}

$systemInformerUrl = "https://sourceforge.net/projects/systeminformer/files/systeminformer-3.2.25011-release-setup.exe/download"
$systemInformerExe = Join-Path $pathsFolder "systeminformer-3.2.25011-release-setup.exe"
if (-not (Test-Path $systemInformerExe)) {
    Write-Log "Downloading System Informer Canary Setup..."
    try {
        Invoke-WebRequest -Uri $systemInformerUrl -OutFile $systemInformerExe -UseBasicParsing
        Write-Log "Downloaded System Informer Setup"
    } catch {
        Write-Log "Failed to download System Informer Setup: $_"
    }
} else {
    Write-Log "System Informer Setup already exists."
}

# === BAM script ===
Write-Log "`nInvoking BAM script..."
try {
    Invoke-Expression (Invoke-RestMethod "https://raw.githubusercontent.com/PureIntent/ScreenShare/main/RedLotusBam.ps1")
    Write-Log "BAM script invoked successfully."
} catch {
    Write-Log "Failed to invoke BAM script: $_"
}

# === Extract BAM registry keys ===
$bamPaths = @(
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings\S-1-5-18",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\UserSettings\S-1-5-18",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings\S-1-5-19",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\UserSettings\S-1-5-19",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings\S-1-5-21-556654287-3429067180-2521233121-1006",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\UserSettings\S-1-5-21-556654287-3429067180-2521233121-1006",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings\S-1-5-21-556654287-3429067180-2521233121-1007",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\UserSettings\S-1-5-21-556654287-3429067180-2521233121-1007",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings\S-1-5-21-556654287-3429067180-2521233121-1015",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\UserSettings\S-1-5-21-556654287-3429067180-2521233121-1015",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\UserSettings\S-1-5-90-0-1",
    "HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\UserSettings\S-1-5-90-0-1"
)

Write-Log "`nExtracting BAM registry keys..."
foreach ($bamPath in $bamPaths) {
    Write-Log "Extracting $bamPath"
    try {
        $props = Get-ItemProperty -Path $bamPath -ErrorAction SilentlyContinue
        if ($props) {
            foreach ($prop in $props.PSObject.Properties) {
                Write-Log "  $($prop.Name) = $($prop.Value)"
            }
        } else {
            Write-Log "  (No properties or path not found)"
        }
    } catch {
        Write-Log "  Failed to read: $_"
    }
}

# === Network adapter data usage (including per WiFi if available) ===
Write-Log "`nGetting network adapter data usage statistics..."
try {
    $netStats = Get-NetAdapterStatistics
    foreach ($stat in $netStats) {
        $receivedMB = [math]::Round($stat.ReceivedBytes / 1MB, 2)
        $sentMB = [math]::Round($stat.SentBytes / 1MB, 2)
        Write-Log "Adapter: $($stat.Name) - Received: $receivedMB MB, Sent: $sentMB MB"
    }
} catch {
    Write-Log "Failed to get network statistics: $_"
}

# === Wi-Fi Data Usage (per interface) ===
Write-Log "`nGetting Wi-Fi data usage per interface..."
try {
    $wifiUsage = Get-NetAdapter | Where-Object {$_.InterfaceDescription -match 'Wi-Fi|Wireless'}
    foreach ($wifi in $wifiUsage) {
        $stats = Get-NetAdapterStatistics -Name $wifi.Name
        $receivedMB = [math]::Round($stats.ReceivedBytes / 1MB, 2)
        $sentMB = [math]::Round($stats.SentBytes / 1MB, 2)
        Write-Log "Wi-Fi Adapter: $($wifi.Name) - Received: $receivedMB MB, Sent: $sentMB MB"
    }
} catch {
    Write-Log "Failed to get Wi-Fi data usage: $_"
}

# === Common folders contents ===
Write-Log "`nGathering contents of common recent directories..."
$recentPaths = @(
    $env:TEMP,
    $env:APPDATA,
    $env:LOCALAPPDATA,
    "$env:WINDIR\Prefetch",
    "$env:USERPROFILE\Recent",
    "$env:SystemRoot\System32\winevt\Logs"
)
foreach ($path in $recentPaths) {
    if (Test-Path $path) {
        Write-Log "`nContents of ${path}:"
        try {
            # Use -Force to include hidden/system files, and avoid Format-Table which doesn't output well to logs
            $items = Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | 
                     Select-Object Name, LastWriteTime, Length, Attributes
            if ($items) {
                foreach ($item in $items) {
                    Write-Log "  $($item.Name) | LastWrite: $($item.LastWriteTime) | Size: $($item.Length) bytes | Attr: $($item.Attributes)"
                }
            } else {
                Write-Log "  (No items found)"
            }
        } catch {
            Write-Log "Failed to list contents of ${path}: $_"
        }
    } else {
        Write-Log "Path not found: $path"
    }
}


# === PowerShell PSReadLine history ===
Write-Log "`nExtracting PowerShell PSReadLine console history..."
$psHistoryPath = Join-Path $env:APPDATA "Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
if (Test-Path $psHistoryPath) {
    try {
        $history = Get-Content $psHistoryPath -ErrorAction SilentlyContinue
        Write-Log "Last 50 PowerShell commands from ConsoleHost_history.txt:"
        $history | Select-Object -Last 50 | ForEach-Object { Write-Log "  $_" }
    } catch {
        Write-Log "Failed to read PowerShell history: $_"
    }
} else {
    Write-Log "PowerShell PSReadLine history file not found."
}

# === Event Viewer logs (System Errors & Application popups) ===
Write-Log "`nFiltering Event Viewer logs (System Errors and Application Popups)..."
try {
    # System Errors (Level 2 = Error)
    $systemErrors = Get-WinEvent -LogName System -MaxEvents 200 | Where-Object { $_.LevelDisplayName -eq "Error" }
    Write-Log "System Errors (last 200):"
    foreach ($event in $systemErrors) {
        Write-Log "`nEvent ID: $($event.Id) at $($event.TimeCreated)"
        Write-Log $event.Message
        Write-Log ("-" * 40)
    }
    # Application popups: filter events with popup/error/fail/warning words from Application log (last 200)
    $appEvents = Get-WinEvent -LogName Application -MaxEvents 200 | Where-Object {
        ($_.Message -match "popup|error|fail|warning") -or $_.LevelDisplayName -eq "Error"
    }
    Write-Log "`nApplication Events (popups/errors/warnings):"
    foreach ($event in $appEvents) {
        Write-Log "`nEvent ID: $($event.Id) at $($event.TimeCreated)"
        Write-Log $event.Message
        Write-Log ("-" * 40)
    }
} catch {
    Write-Log "Failed to get event logs: $_"
}

# === Task Scheduler Logs ===
Write-Log "`nExtracting Task Scheduler logs..."
try {
    $taskPaths = @(
        "$env:SystemRoot\System32\Tasks",
        "$env:SystemRoot\System32\Tasks\Microsoft"
    )
    foreach ($taskPath in $taskPaths) {
        if (Test-Path $taskPath) {
            Write-Log "`nTasks in folder: $taskPath"
            $tasks = Get-ChildItem -Path $taskPath -Recurse -ErrorAction SilentlyContinue
            foreach ($task in $tasks) {
                Write-Log "Task: $($task.FullName)"
		Write-Log ("-" * 40)

            }
        } else {
            Write-Log "Task folder not found: $taskPath"
        }
    }
} catch {
    Write-Log "Failed to extract Task Scheduler logs: $_"
}

Write-Log "`nScript completed at $(Get-Date)"