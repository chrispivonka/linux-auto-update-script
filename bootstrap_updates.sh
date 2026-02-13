#!/bin/bash

REPO_DIR="$HOME/GitHub/linux-auto-update-script"
UPDATE_SCRIPT="$REPO_DIR/update_script.sh"
LOG_DIR="$HOME/SystemUpdates"
REBOOT_FLAG="$LOG_DIR/reboot_in_progress"
LOG_FILE="$LOG_DIR/unified_updates_$(date +%Y-%m-%d).log"

# Only act if the reboot flag exists
if [ -f "$REBOOT_FLAG" ]; then
    mkdir -p "$LOG_DIR"
    echo "[$(date)] System rebooted; found flag. Resuming update cycle..." >> "$LOG_FILE"
    
    # Remove the flag immediately to prevent loop on crash
    rm "$REBOOT_FLAG"

    # Run the main script
    if [ -f "$UPDATE_SCRIPT" ]; then
        /bin/bash "$UPDATE_SCRIPT"
    else
        echo "[$(date)] ERROR: Update script not found at $UPDATE_SCRIPT" >> "$LOG_FILE"
    fi
fi
