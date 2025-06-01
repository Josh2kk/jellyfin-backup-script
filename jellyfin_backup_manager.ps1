# Author: Josh2kk
# Github : https://github.com/josh2kk/
# Tool : jellyfin_backup_manager.ps1
# Description: Backup and restore script for Jellyfin on Windows

param(
    [switch]$BackupOnly
)

Add-Type -AssemblyName System.Windows.Forms

# === CONFIGURATION ===
# Detect Jellyfin installation directory based on privilege
$ProgramDataPath = "$env:ProgramData\Jellyfin"
$LocalAppDataPath1 = Join-Path $env:LOCALAPPDATA "Jellyfin"
$LocalAppDataPath2 = Join-Path $env:LOCALAPPDATA "jellyfin"

if (Test-Path $ProgramDataPath) {
    $JellyfinDataPath = $ProgramDataPath
} elseif (Test-Path $LocalAppDataPath1) {
    $JellyfinDataPath = $LocalAppDataPath1
} elseif (Test-Path $LocalAppDataPath2) {
    $JellyfinDataPath = $LocalAppDataPath2
} else {
    Write-Host "Jellyfin data folder not found in expected locations."
    Write-Host "Please check if Jellyfin is installed and run this script as the same user running Jellyfin."
    exit 1
}

$DefaultBackupFolder = "$PSScriptRoot\Backups"
$TaskName = "JellyfinAutoBackup"

# === HEADER DISPLAY ===
Write-Host "============================================"
Write-Host "# Author: Josh2kk"
Write-Host "# Github : https://github.com/josh2kk/"
Write-Host "# Tool : jellyfin_backup_manager.ps1"
Write-Host "# Description: Backup and restore script for Jellyfin on Windows"
Write-Host "============================================`n"

function Select-FolderDialog {
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Select Backup Destination Folder"
    $folderBrowser.ShowNewFolderButton = $true
    if ($folderBrowser.ShowDialog() -eq "OK") {
        return $folderBrowser.SelectedPath
    }
    return $null
}

function Stop-Jellyfin {
    Write-Host "Attempting to stop Jellyfin..."
    
    # Check if Jellyfin is running as a service
    if (Get-Service -Name "jellyfin" -ErrorAction SilentlyContinue) {
        Stop-Service -Name "jellyfin" -Force
        Write-Host "Jellyfin service stopped."
    } else {
        # If Jellyfin is running as a process, stop it
        $proc = Get-Process jellyfin -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Stop-Process -Force
            Write-Host "Jellyfin user process killed."
        } else {
            Write-Host "Jellyfin is not currently running."
        }
    }
    Start-Sleep -Seconds 3
}

function Start-Jellyfin {
    # Try starting the service first
    if (Get-Service -Name "jellyfin" -ErrorAction SilentlyContinue) {
        Start-Service -Name "jellyfin"
        Write-Host "Jellyfin service started."
    } else {
        # Otherwise, try starting it as a process (for user installs)
        $jellyfinPath = Join-Path $env:LOCALAPPDATA "Jellyfin\jellyfin.exe"
        if (Test-Path $jellyfinPath) {
            Start-Process -FilePath $jellyfinPath
            Write-Host "Jellyfin process started."
        } else {
            Write-Host "Jellyfin executable not found. Please start it manually."
        }
    }
}

function Create-Backup {
    Write-Host "`nStarting backup..."
    Stop-Jellyfin

    $choice = Read-Host "Choose backup location: [1] Script directory [2] Choose manually"
    if ($choice -eq '1') {
        $backupDir = $DefaultBackupFolder
    } elseif ($choice -eq '2') {
        $backupDir = Select-FolderDialog
        if (-not $backupDir) {
            Write-Host "No folder selected. Aborting."
            return
        }
    } else {
        Write-Host "Invalid choice."
        return
    }

    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir | Out-Null
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFile = Join-Path $backupDir "JellyfinBackup_$timestamp.zip"

    try {
        Write-Host "Creating backup: $backupFile"
        Compress-Archive -Path "$JellyfinDataPath\*" -DestinationPath $backupFile -Force
        Write-Host "Backup created successfully!"
    } catch {
        Write-Host "Backup failed: $($_.Exception.Message)"
    }

    Start-Jellyfin
}

function Restore-Backup {
    Write-Host "`nRestore from Backup"
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "ZIP files (*.zip)|*.zip"
    $dialog.Title = "Select a Jellyfin Backup File"
    if ($dialog.ShowDialog() -eq "OK") {
        $zipPath = $dialog.FileName
        Write-Host "Restoring backup from: $zipPath"

        Stop-Jellyfin

        try {
            Remove-Item -Path "$JellyfinDataPath\*" -Recurse -Force
            Expand-Archive -Path $zipPath -DestinationPath $JellyfinDataPath -Force
            Write-Host "Restore completed successfully."
        } catch {
            Write-Host "Restore failed: $($_.Exception.Message)"
        }

        Start-Jellyfin
    } else {
        Write-Host "Restore canceled by user."
    }
}

function Schedule-Backup {
    Write-Host "`nSchedule Automatic Backup"
    $freq = Read-Host "Choose backup frequency: [d]aily, [w]eekly, [m]onthly, [y]early"
    $intervalMap = @{
        'd' = 'DAILY'
        'w' = 'WEEKLY'
        'm' = 'MONTHLY'
        'y' = 'ONCE'
    }

    if (-not $intervalMap.ContainsKey($freq)) {
        Write-Host "Invalid frequency."
        return
    }

    $scheduleType = $intervalMap[$freq]
    $scriptPath = $MyInvocation.MyCommand.Definition

    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask `
        -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -BackupOnly") `
        -Trigger (New-ScheduledTaskTrigger -$scheduleType -At 3am) `
        -TaskName $TaskName -Description "Jellyfin auto-backup" `
        -User "$env:UserName" -RunLevel Highest

    Write-Host "Scheduled $scheduleType backups at 3:00 AM."
}

# === MAIN ENTRY ===
if ($BackupOnly) {
    Create-Backup
    exit
}

while ($true) {
    Write-Host "`nJellyfin Backup Manager"
    Write-Host "1. Backup Jellyfin"
    Write-Host "2. Restore from Backup"
    Write-Host "3. Schedule Automatic Backups"
    Write-Host "4. Exit"
    $input = Read-Host "Select an option"

    switch ($input) {
        '1' { Create-Backup }
        '2' { Restore-Backup }
        '3' { Schedule-Backup }
        '4' { Write-Host "Exiting..."; exit }
        default { Write-Host "Invalid option. Try again." }
    }
}
