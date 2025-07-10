# realsync Data Sync LuCI App

## Project Introduction

**realsync** is a real-time data synchronization and auto-backup tool for OpenWrt, featuring a modern LuCI web interface. It supports multi-task management, scheduled sync, log viewing, permission control, and is suitable for routers, NAS, edge gateways, and more.

---

## Features

- Multi-task data sync configuration
- Real-time/scheduled sync via rsync + inotifywait
- LuCI web UI for visual management, status monitoring, log viewing
- One-click log clear, force restart service
- Secure permission control (ACL)
- Multilingual UI (Chinese/English)

---

## Installation

1. Upload all project files to your OpenWrt device (recommended `/root` or `/tmp` directory).
2. Make the install script executable:
   ```sh
   git clone https://github.com/xfghvgnfyjssjgte/Luci-app-Realsync.git
   cd realsync
   chmod +x install_realsync.sh
   ```
3. Run the installer:
   ```sh
   ./install_realsync.sh install
   ```
4. The script will check/install dependencies, copy all files, set permissions, enable and start the service.
5. After installation, log in to LuCI and go to "Services" -> "realsync" to configure and manage.

---

## Usage

- Add/edit sync tasks in LuCI, set source/target directories, interval, etc.
- Enable/disable tasks anytime, view status and detailed logs.
- One-click log clear and force restart supported.
- Log file is at `/var/log/realsync.log`.

---

## FAQ

- **Q: No UI after install?**
  - Clear browser cache or restart uhttpd.
- **Q: Log not cleared?**
  - Check write permissions or restart service.
- **Q: Task not auto-started?**
  - Try "Force Restart" or check dependencies.

---

## Supported Platforms

- OpenWrt 19.07/21.02/22.03+
- Routers, x86, ARM, NAS, VM, etc.
- Requires rsync, inotify-tools

---

## Contact

- Author: [xfghvgnfyjssjgte]
- Email: [xfghvgnfyjssjgte@gmail.com]
- Issues: Please submit issues on GitHub

---

> This project is open source. Contributions are welcome! 
