Roblox-System-Inspector
Roblox-System-Inspector is a powerful, all-in-one PowerShell script designed to collect comprehensive system diagnostics with minimal user effort. It runs as Administrator to extract key system details and logs everything into neatly organized files, perfect for troubleshooting and performance auditing in Roblox gaming environments or general Windows systems.

Features
Admin elevation: Automatically restarts the script with administrator privileges if needed.

BAM (Background Activity Moderator) registry extraction: Collects detailed user activity data from Windows registry.

Network usage stats: Reports data sent/received on all network adapters, including Wi-Fi.

Common folder snapshots: Lists contents and metadata from key system folders like Temp, Prefetch, Recent, Event Logs, and more.

PowerShell command history: Extracts last 50 commands from PSReadLine history.

Event Viewer filtering: Gathers recent System Errors and Application warnings for quick issue identification.

Task Scheduler logs: Enumerates scheduled tasks for further system insights.

Automated tool downloads: Fetches external utilities like PathsParser and System Informer to enhance diagnostics.

Comprehensive logging: All outputs are saved in timestamped log files inside Documents\RobloxPCCheckLogs.

Usage
Download or clone the repository.

Run the script as Administrator (the script auto-elevates if needed).

The script will collect and log system info step-by-step.

Check the generated logs in Documents\RobloxPCCheckLogs for detailed diagnostics.

Requirements
Windows 10 or higher

PowerShell 5.1 or later

Internet connection for downloading external tools

Why Use Roblox-System-Inspector?
Designed with Roblox users and system admins in mind, this script provides a fast, automated way to audit PC health, identify potential issues, and gather relevant system data — all with zero manual configuration. It’s perfect for support teams, gamers, and anyone wanting a deep Windows system overview.
