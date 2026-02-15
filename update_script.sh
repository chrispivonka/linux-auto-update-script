#!/bin/bash

# Best Practice: Stop if an undefined variable is used
set -u

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

resolve_brew_user() {
    local brew_path="$1"
    local owner=""

    if command -v stat &> /dev/null; then
        owner=$(stat -c %U "$brew_path" 2>/dev/null || true)
    fi

    if [ -n "$owner" ] && [ "$owner" != "root" ]; then
        echo "$owner"
        return
    fi

    echo "$RUN_USER"
}

# 1. Setup Paths
RUN_USER="${SUDO_USER:-${LOGNAME:-$(id -un)}}"
HOME_DIR="${HOME:-$(resolve_home_dir "$RUN_USER")}"

if [ -z "$HOME_DIR" ]; then
    HOME_DIR="/root"
fi

LOG_DIR="${LOG_DIR:-"$HOME_DIR/SystemUpdates"}"
REBOOT_FLAG="$LOG_DIR/reboot_in_progress"
mkdir -p "$LOG_DIR"

# Daily Log File
LOG_FILE="$LOG_DIR/unified_updates_$(date +%Y-%m-%d).log"

# Redirect output (Append mode)
exec > >(tee -a "$LOG_FILE") 2>&1
echo "--- Update Cycle Started: $(date) ---"

# 2. Update System Packages (APT)
echo "Step 1: Updating system packages..."
if ! command -v sudo &> /dev/null; then
    echo "Error: sudo is required for system updates."
    exit 1
fi
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -yq --with-new-pkgs
sudo apt-get autoremove -y

# 3. Update Homebrew (Brew)
BREW_PATH="${BREW_PATH:-$(command -v brew 2>/dev/null || echo /home/linuxbrew/.linuxbrew/bin/brew)}"
echo "Step 2: Updating Homebrew..."
if [ -f "$BREW_PATH" ]; then
    BREW_USER="$(resolve_brew_user "$BREW_PATH")"
    sudo -H -u "$BREW_USER" "$BREW_PATH" update
    sudo -H -u "$BREW_USER" "$BREW_PATH" upgrade
    sudo -H -u "$BREW_USER" "$BREW_PATH" cleanup
else
    echo "Homebrew not found, skipping."
fi

# 4. Cleanup old logs (keep last 30 days)
find "$LOG_DIR" -name "unified_updates_*.log" -type f -mtime +30 -delete

# 5. Infinite Reboot Loop Safeguard
LOOP_FILE="/tmp/update_reboot_count"
count=$(cat "$LOOP_FILE" 2>/dev/null || echo 0)
if [ "$count" -ge 5 ]; then
    echo "CRITICAL: Reboot limit reached (5). Breaking cycle."
    rm -f "$LOOP_FILE" "$REBOOT_FLAG"
    exit 1
fi

# 6. Check if Reboot is Required
REBOOT_FILE="/var/run/reboot-required"
echo "Step 3: Check if a reboot is required to finish installing updates."
if [ -f "$REBOOT_FILE" ]; then
    echo "--- REBOOT REQUIRED ---"
    touch "$REBOOT_FLAG"
    echo $((count+1)) > "$LOOP_FILE"
    
    [ -f "$REBOOT_FILE.pkgs" ] && cp "$REBOOT_FILE.pkgs" "$LOG_DIR/reboot_trigger_$(date +%H-%M).txt"

    echo "Initiating Reboot (Cycle #$((count+1)))..."
    # Attempt real reboot; if it fails (like in Docker), exit 0 to trigger Docker Restart
    sudo shutdown -r now || exit 0
else
    echo "No reboot required. System is fully up to date."
    rm -f "$LOOP_FILE" "$REBOOT_FLAG"
fi

echo "--- Update Cycle Finished: $(date) ---"
