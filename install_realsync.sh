#!/bin/sh

# =============================================================================
#        LuCI App for realsync - Installation/Uninstallation Script
# =============================================================================
#  Run this script from the root of the repository on your OpenWrt device.
#  Usage: ./install_realsync.sh [install|uninstall]
# =============================================================================

# Color codes for output
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m' # No Color

echo_info() { echo -e "${C_BLUE}[INFO]${C_NC} $1"; }
echo_ok() { echo -e "${C_GREEN}[OK]${C_NC} $1"; }
echo_warn() { echo -e "${C_YELLOW}[WARN]${C_NC} $1"; }
echo_error() { echo -e "${C_RED}[ERROR]${C_NC} $1"; }

# Ensure running as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo_error "This script must be run as root. Please use 'sudo' or log in as root."
        exit 1
    fi
}

# --- Installation Function ---
install_app() {
    check_root
    echo_info "Starting installation of LuCI App realsync..."

    # --- Dependency Check ---
    echo_info "Checking for required packages..."

    check_and_install_pkg() {
        local pkg_name="$1"
        local cmd_name="$2"
        if ! command -v "$cmd_name" >/dev/null 2>&1; then
            echo_warn "Command '$cmd_name' not found. '$pkg_name' is required."
            read -p "Do you want to try and install it now via opkg? (y/n): " choice
            case "$choice" in
                y|Y )
                    echo_info "Running 'opkg update'"
                    opkg update
                    echo_info "Attempting to install '$pkg_name'"
                    opkg install "$pkg_name"
                    if ! command -v "$cmd_name" >/dev/null 2>&1; then
                        echo_error "Failed to install '$pkg_name'. Please install it manually."
                        exit 1
                    fi
                    ;;
                * ) echo_error "Installation aborted."; exit 1;;
            esac
        else
            echo_ok "Package for '$cmd_name' is already installed."
        fi
    }

    check_and_install_pkg "rsync" "rsync"
    check_and_install_pkg "inotify-tools" "inotifywait"

    # --- File Installation ---
    echo_info "Copying application files..."

    # Copy LuCI files
    rsync -a ./usr/lib/lua/luci/ /usr/lib/lua/luci/
    if [ $? -ne 0 ]; then echo_error "Failed to copy LuCI files."; exit 1; fi
    echo_ok "LuCI files copied."

    # Copy scripts and binaries
    rsync -a ./usr/bin/ /usr/bin/
    if [ $? -ne 0 ]; then echo_error "Failed to copy scripts to /usr/bin/."; exit 1; fi
    echo_ok "Scripts copied."

    # Copy init.d scripts
    rsync -a ./etc/init.d/ /etc/init.d/
    if [ $? -ne 0 ]; then echo_error "Failed to copy init.d scripts."; exit 1; fi
    echo_ok "Init.d scripts copied."

    # Copy config templates
    rsync -a ./etc/config/ /etc/config/
    if [ $? -ne 0 ]; then echo_error "Failed to copy config templates."; exit 1; fi
    echo_ok "Config templates copied."

    # Copy ACL files
    rsync -a ./usr/share/rpcd/ /usr/share/rpcd/
    if [ $? -ne 0 ]; then echo_error "Failed to copy ACL files."; exit 1; fi
    echo_ok "ACL files copied."

    # --- Set Permissions ---
    echo_info "Setting executable permissions..."
    chmod +x /etc/init.d/realsync
    chmod +x /usr/bin/realsync.sh
    echo_ok "Permissions set."

    # --- Clean LuCI Cache ---
    echo_info "Cleaning LuCI cache..."
    rm -f /tmp/luci-indexcache
    echo_ok "LuCI cache cleared."

    # Enable and start the service
    echo_info "Enabling and starting the realsync service..."
    /etc/init.d/realsync enable
    /etc/init.d/realsync restart

    echo_info "=================================================================="
    echo_ok "Installation complete!"
    echo_info "Please navigate to 服务 -> realsync 在 LuCI 进行配置。"
    echo_info "=================================================================="
}

# --- Uninstallation Function ---
uninstall_app() {
    check_root
    echo_info "Starting uninstallation of LuCI App realsync..."

    # --- Stop and Disable Service ---
    echo_info "Stopping and disabling the realsync service..."
    if [ -f /etc/init.d/realsync ]; then
        /etc/init.d/realsync stop
        /etc/init.d/realsync disable
        echo_ok "Service stopped and disabled."
    else
        echo_warn "Service script not found, skipping."
    fi

    # --- Remove Files ---
    echo_info "Removing application files..."

    rm -f /usr/lib/lua/luci/controller/realsync.lua
    rm -rf /usr/lib/lua/luci/model/cbi/realsync
    rm -rf /usr/lib/lua/luci/view/realsync
    rm -f /usr/lib/lua/luci/po/zh-cn/realsync.po
    rm -f /etc/init.d/realsync
    rm -f /usr/bin/realsync.sh
    rm -f /etc/config/realsync
    rm -f /usr/share/rpcd/acl.d/luci-app-realsync.json

    echo_ok "Application files removed."

    # --- Clean Cache ---
    echo_info "Cleaning LuCI cache..."
    rm -f /tmp/luci-indexcache
    echo_ok "LuCI cache cleared."

    echo_info "=================================================================="
    echo_ok "Uninstallation complete!"
    echo_info "=================================================================="
}

# --- Main Logic ---
if [ -n "$1" ]; then
    case "$1" in
        install)
            install_app
            ;;
        uninstall)
            uninstall_app
            ;;
        *)
            echo_error "Invalid argument: $1. Usage: ./install_realsync.sh [install|uninstall]"
            exit 1
            ;;
    esac
else
    # --- Main Menu (Interactive) ---
    while true; do
        echo_info "\nLuCI App realsync Management Menu"
        echo_info "-----------------------------------"
        echo_info "1. Install realsync"
        echo_info "2. Uninstall realsync"
        echo_info "3. Exit"
        echo_info "-----------------------------------"
        read -p "Enter your choice [1-3]: " choice

        case "$choice" in
            1) install_app; break;;
            2) uninstall_app; break;;
            3) echo_info "Exiting. Goodbye!"; exit 0;;
            * ) echo_warn "Invalid choice. Please enter 1, 2, or 3.";;
        esac
    done
fi 