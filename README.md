# realsync Data Sync LuCI App

## Project Introduction

**realsync** is a real-time data synchronization and auto-backup tool for OpenWrt, featuring a modern LuCI web interface. It supports multi-task management, scheduled sync, log viewing, permission control, and is suitable for routers, NAS, edge gateways, and more.

---

## Pain Points Solved by This Project

1. **Lack of user-friendly data sync solutions for OpenWrt/embedded devices**
   - Traditional tools like rsync and inotifywait are powerful, but lack an all-in-one, visual management interface on OpenWrt routers, NAS, etc.
   - Users have to write scripts and cron jobs manually, which is error-prone and hard to maintain.
2. **Difficult to manage multiple sync tasks**
   - Multi-directory and multi-target sync needs are common, but native solutions make it hard to batch configure, enable/disable, or monitor each task.
3. **Lack of real-time status and log feedback**
   - Users cannot intuitively see the running status, failure reasons, or sync history, making troubleshooting difficult.
4. **Permission and security management is inconvenient**
   - Traditional scripts are hard to integrate with OpenWrt's ACL system, posing security risks.
5. **Complex installation and dependency environment**
   - Traditional solutions have many dependencies and complex steps, making it hard for ordinary users to get started quickly.

---

## Advantages

- **LuCI Visual Management Interface**: Full web-based configuration, no command line required. Supports add/edit/delete tasks, enable/disable, status monitoring, log viewing—all in one place.
- **Multi-task Support and Flexible Configuration**: Any number of sync tasks, each with independent source/target, interval, delete options, etc. Suitable for multi-directory, multi-device scenarios.
- **Real-time Log and Status Feedback**: View task/service status and detailed logs in real time, with one-click log clear. Easy to spot and troubleshoot issues.
- **One-click Install/Uninstall Script, Simple Deployment**: Professional install/uninstall script, auto-detects dependencies, copies files, sets permissions, cleans cache. One-click uninstall for easy maintenance and upgrade.
- **Seamless Integration with OpenWrt ACL**: Secure permission control, suitable for multi-user environments.
- **Bilingual Support (Chinese/English), Internationalization Friendly**: Suitable for both domestic and international users and open source communities.

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

- Author: [望天追风や]
- Email: [xfghvgnfyjssjgte@gmail.com]

---

> This project is open source. Contributions are welcome!

