# PfSense Scripts

## 1. DHCP Lease Monitor Script

### Overview
This script monitors DHCP leases using the Kea DHCP lease file(s), detects new leases, and sends notifications via Telegram. It ensures that no duplicate entries are processed and maintains a record of all known leases.

### Features
- Extracts IP, MAC address, and Hostname from DHCP lease files.
- Deduplicates entries to avoid redundant notifications.
- Sends Telegram notifications when new leases are detected.
- Formats messages in a structured way.
- Runs continuously in the background.
- Initializes by sending all existing leases on startup.

### Requirements
- **Telegram Bot API Token** (Create one via [@BotFather](https://t.me/BotFather)).
- Shell environment with `awk`, `grep`, `tail`, and `comm` utilities.

### Running the Script
- To run in the background:
  ```sh
  /dhcp4_monitor.sh &
  ```
- To check if it's running:
  ```sh
  ps aux | grep dhcp4_monitor.sh
  ```
- To stop the script:
  ```sh
  kill $(pgrep -f dhcp4_monitor.sh)
  ```

### Setting Up the Script to Run on pfSense Startup Using pfSense's Cron Package (GUI)

#### 1. Install Cron Package (if not installed)
- Go to **System → Package Manager → Available Packages**
- Search for **"Cron"** and install it.

#### 2. Add a Cron Job
- Go to **Services → Cron**
- Click **"Add"**
- Set:
  - **Minute**: `@reboot`
  - **Command**: `/custom/dhcp_monitor.sh &`
- Click **Save & Apply**.

This will execute your script at every reboot.

