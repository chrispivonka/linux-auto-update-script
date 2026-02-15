#!/bin/bash

resolve_home_dir() {
    local user="$1"
    local home_dir=""

    if command -v getent &> /dev/null; then
        home_dir=$(getent passwd "$user" | cut -d: -f6)
    else
        home_dir=$(awk -F: -v u="$user" '$1==u {print $6}' /etc/passwd)
    fi

    echo "$home_dir"
}

RUN_USER="${SUDO_USER:-${LOGNAME:-$(id -un)}}"
HOME_DIR="${HOME:-$(resolve_home_dir "$RUN_USER")}"

if [ -z "$HOME_DIR" ]; then
    HOME_DIR="/root"
fi

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
UPDATE_SCRIPT="$REPO_DIR/update_script.sh"
LOG_DIR="${LOG_DIR:-"$HOME_DIR/SystemUpdates"}"
REBOOT_FLAG="$LOG_DIR/reboot_in_progress"
LOG_FILE="$LOG_DIR/unified_updates_$(date +%Y-%m-%d).log"

# Create log directory
mkdir -p "$LOG_DIR"

# Only act if the reboot flag exists
if [ -f "$REBOOT_FLAG" ]; then
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
