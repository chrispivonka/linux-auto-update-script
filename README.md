# Linux Auto-Update Script

![License: MIT](https://img.shields.io/badge/License-MIT-blue)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue)
![Shell: Bash](https://img.shields.io/badge/Shell-Bash-green)
[![CI](https://github.com/chrispivonka/linux-auto-update-script/actions/workflows/ci.yml/badge.svg)](https://github.com/chrispivonka/linux-auto-update-script/actions/workflows/ci.yml)
[![Docs](https://github.com/chrispivonka/linux-auto-update-script/actions/workflows/docs.yml/badge.svg)](https://github.com/chrispivonka/linux-auto-update-script/actions/workflows/docs.yml)
[![Release](https://github.com/chrispivonka/linux-auto-update-script/actions/workflows/release.yml/badge.svg)](https://github.com/chrispivonka/linux-auto-update-script/actions/workflows/release.yml)

A reliable, automated system to keep Ubuntu/Debian packages and Homebrew apps up to date. This script handles the entire lifecycle of an update, including automated reboots and post-reboot verification cycles.

## 🚀 Features

*   **Unified Updates**: Runs `apt update/upgrade` and `brew update/upgrade` in one pass.
*   **Intelligent Reboot Cycle**: Detects if a reboot is required, restarts the system, and verifies updates again upon booting.
*   **Infinite Loop Protection**: Safeguard built-in to prevent more than 5 consecutive reboots.
*   **Clean Logging**: Daily log rotation stored in `~/SystemUpdates` with automatic cleanup of logs older than 30 days.
*   **Docker Testable**: Includes a Dockerfile to simulate and test the update/reboot logic safely.

---

## 📂 Project Structure

*   `update_script.sh`: The main engine that performs updates and checks for reboot requirements.
*   `bootstrap_updates.sh`: The "gatekeeper" script that runs on system boot to resume a pending update cycle.
*   `Dockerfile`: Environment for testing the scripts without touching your host system.

---

## 🛠️ Setup Instructions

### 1. Permissions
Ensure both scripts are executable:
```bash
chmod +x ~/GitHub/linux-auto-update-script/*.sh
```

### 2. Configure Automation (Crontab)
To enable the daily check and the boot-time resumption, you must add the scripts to your system's root crontab. This allows apt to run without manual password entry.

  1. Open the crontab editor:
  ```bash
  sudo crontab -e
  ```
  2. Add these two lines to the bottom (replace with your actual Linux username):
  ```bash
    # 1. Resume update cycle on system boot if a reboot was just performed
    @reboot /bin/bash /home/chris/GitHub/linux-auto-update-script/bootstrap_updates.sh

    # 2. Start the primary daily update check at 4:00 AM
    0 4 * * * /bin/bash /home/chris/GitHub/linux-auto-update-script/update_script.sh
  ```

### 3. 🧪 Testing with Docker
You can verify the logic—including the reboot flag handoff—using Docker. Since containers cannot "reboot" hardware, we use a Docker Restart Policy to simulate the cycle.
  1. Build the image:
  ```bash
  docker build -t auto-updater .
  ```
  2. Run the test container:
  ```bash
    docker run -it --name update-test \
    --restart always \
    -v $(pwd):/home/testuser/GitHub/linux-auto-update-script \
    auto-updater
  ```
  3. Simulate a Reboot Requirement:
    a. While the container is running, open a separate terminal and run:
    ```bash
    docker exec -u root update-test touch /var/run/reboot-required
    ```
The container will detect the file, exit (simulating a reboot), and Docker will instantly restart it, triggering bootstrap_updates.sh to resume the cycle.

### 4. 📝 Log Management
All activity is recorded in your home directory for easy auditing:
  - Daily Logs: ~/SystemUpdates/unified_updates_YYYY-MM-DD.log
  - Reboot Records: If a reboot is triggered, the specific packages responsible are saved to `~/SystemUpdates/reboot_trigger_HH-MM.txt`.
  - The script automatically purges log files older than 30 days to save disk space.
