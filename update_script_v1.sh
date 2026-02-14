#!/bin/bash

# Best Practice: Stop if an undefined variable is used
set -u

# 1. Setup Logging Directory and File
LOG_DIR="$HOME/SystemUpdates"
mkdir -p "$LOG_DIR"

# Defines log file with a date suffix
LOG_FILE="$LOG_DIR/unified_updates_$(date +%Y-%m-%d).log"

# 2. Redirect all output to the log file
exec > >(tee -a "$LOG_FILE") 2>&1
echo "--- Update Started: $(date) ---"

# 3. Update System Packages (APT)
echo "Step 3: Updating system packages..."
if ! command -v sudo &> /dev/null; then
    echo "Error: sudo is required for system updates."
    exit 1
fi
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq --with-new-pkgs
sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove -y

# 4. Update Homebrew (Brew)
BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"

echo "Step 4: Updating Homebrew..."
if [ -f "$BREW_PATH" ]; then
    # Ensures brew runs as the original user even under sudo/cron
    CURRENT_USER=${SUDO_USER:-$USER}
    sudo -u "$CURRENT_USER" "$BREW_PATH" update
    sudo -u "$CURRENT_USER" "$BREW_PATH" upgrade
    sudo -u "$CURRENT_USER" "$BREW_PATH" cleanup
else
    echo "Homebrew not found at $BREW_PATH, skipping."
fi

# 5. Cleanup: Delete logs older than 30 days
echo "Step 5: Cleaning up old logs..."
find "$LOG_DIR" -name "unified_updates_*.log" -type f -mtime +30 -delete

# 6. Check for Reboot and Log to SystemUpdates
REBOOT_FILE="/var/run/reboot-required"
echo "Step 6: Check if a reboot is required to finish installing updates."
if [ -f "$REBOOT_FILE" ]; then
    echo "System requires a restart to apply updates."
    
    # Save a record of the specific packages that triggered the reboot
    if [ -f "$REBOOT_FILE.pkgs" ]; then
        cp "$REBOOT_FILE.pkgs" "$LOG_DIR/reboot_trigger_$(date +%Y-%m-%d).txt"
        echo "Packages requiring reboot saved to $LOG_DIR"
    fi

    echo "Initiating automatic reboot in 1 minute..."
    echo "--- Update Finished: $(date) ---"
    sudo shutdown -r +1 "Automatic update complete. Rebooting to apply changes."
else
    echo "No reboot required."
    echo "--- Update Finished: $(date) ---"
fi
