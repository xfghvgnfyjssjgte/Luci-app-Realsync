#!/bin/sh

# Color codes for output
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m'

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

install_app() {
    check_root
    echo_info "Starting installation of LuCI App realsync..."

    echo_info "Checking for required packages..."

    check_and_install_pkg() {
        local pkg_name="$1"
        local cmd_name="$2"
        local alt_pkg_name="$3"
        
        if ! command -v "$cmd_name" >/dev/null 2>&1; then
            echo_warn "Command '$cmd_name' not found. '$pkg_name' is required."
            read -p "Do you want to try and install it now via opkg? (y/n): " choice
            case "$choice" in
                y|Y )
                    echo_info "Running 'opkg update'"
                    opkg update
                    
                    echo_info "Attempting to install '$pkg_name'"
                    if opkg install "$pkg_name"; then
                        if command -v "$cmd_name" >/dev/null 2>&1; then
                            echo_ok "Successfully installed '$pkg_name'"
                            return 0
                        else
                            for path in /usr/bin /bin /usr/sbin /sbin; do
                                if [ -x "$path/$cmd_name" ]; then
                                    echo_ok "Found '$cmd_name' in $path"
                                    return 0
                                fi
                            done
                            export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
                            if command -v "$cmd_name" >/dev/null 2>&1; then
                                echo_ok "Successfully installed '$pkg_name' (after PATH refresh)"
                                return 0
                            fi
                        fi
                    fi
                    
                    if [ -n "$alt_pkg_name" ]; then
                        echo_info "Primary package failed, trying alternative '$alt_pkg_name'"
                        if opkg install "$alt_pkg_name"; then
                            if command -v "$cmd_name" >/dev/null 2>&1; then
                                echo_ok "Successfully installed '$alt_pkg_name'"
                                return 0
                            else
                                for path in /usr/bin /bin /usr/sbin /sbin; do
                                    if [ -x "$path/$cmd_name" ]; then
                                        echo_ok "Found '$cmd_name' in $path"
                                        return 0
                                    fi
                                done
                                export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
                                if command -v "$cmd_name" >/dev/null 2>&1; then
                                    echo_ok "Successfully installed '$alt_pkg_name' (after PATH refresh)"
                                    return 0
                                fi
                            fi
                        fi
                    fi
                    
                    echo_error "Failed to install '$pkg_name'"
                    if [ -n "$alt_pkg_name" ]; then
                        echo_info "You can try installing manually with:"
                        echo_info "  opkg install $pkg_name"
                        echo_info "  or"
                        echo_info "  opkg install $alt_pkg_name"
                    else
                        echo_info "You can try installing manually with:"
                        echo_info "  opkg install $pkg_name"
                    fi
                    
                    if [ "$cmd_name" = "inotifywait" ]; then
                        echo_info "For inotifywait, you might also try:"
                        echo_info "  opkg install inotify-tools"
                        echo_info "  or check if the package provides the command:"
                        echo_info "  opkg files libinotifytools"
                        
                        echo_info "Checking if inotifywait exists in the installed package..."
                        if opkg files libinotifytools | grep -q inotifywait; then
                            echo_info "Package contains inotifywait, checking for symlinks..."
                            for path in /usr/bin /bin /usr/sbin /sbin; do
                                if [ -f "$path/inotifywait" ]; then
                                    echo_ok "Found inotifywait in $path"
                                    return 0
                                fi
                            done
                        fi
                    fi
                    
                    echo_error "Please install it manually and run this script again."
                    exit 1
                    ;;
                * ) echo_error "Installation aborted."; exit 1;;
            esac
        else
            echo_ok "Package for '$cmd_name' is already installed."
        fi
    }

    check_and_install_pkg "rsync" "rsync"
    check_and_install_pkg "inotifywait" "inotifywait"

    echo_info "Copying application files..."

    cp -r ./usr/lib/lua/luci/* /usr/lib/lua/luci/
    if [ $? -ne 0 ]; then echo_error "Failed to copy LuCI files."; exit 1; fi
    echo_ok "LuCI files copied."

    cp -r ./usr/bin/* /usr/bin/
    if [ $? -ne 0 ]; then echo_error "Failed to copy scripts to /usr/bin/."; exit 1; fi
    echo_ok "Scripts copied."

    cp -r ./etc/init.d/* /etc/init.d/
    if [ $? -ne 0 ]; then echo_error "Failed to copy init.d scripts."; exit 1; fi
    echo_ok "Init.d scripts copied."

    cp -r ./etc/config/* /etc/config/
    if [ $? -ne 0 ]; then echo_error "Failed to copy config templates."; exit 1; fi
    echo_ok "Config templates copied."

    cp -r ./usr/share/rpcd/* /usr/share/rpcd/
    if [ $? -ne 0 ]; then echo_error "Failed to copy ACL files."; exit 1; fi
    echo_ok "ACL files copied."

    echo_info "Setting executable permissions..."
    chmod +x /etc/init.d/realsync
    chmod +x /usr/bin/realsync.sh
    echo_ok "Permissions set."

    echo_info "Cleaning LuCI cache..."
    rm -f /tmp/luci-indexcache
    echo_ok "LuCI cache cleared."

    echo_info "Restarting uhttpd service for LuCI interface..."
    if [ -f /etc/init.d/uhttpd ]; then
        /etc/init.d/uhttpd restart
        /etc/init.d/rpcd restart
        echo_ok "uhttpd service restarted."
    else
        echo_warn "uhttpd service not found, LuCI interface may not display properly."
    fi

    echo_info "=================================================================="
    echo_ok "Installation complete!"
    echo_info "Please navigate to 服务 -> realsync 在 LuCI 进行配置。"
    echo_info "如需立即启动服务，请手动执行：/etc/init.d/realsync restart"
    echo_info "=================================================================="
    exit 0
}

uninstall_app() {
    check_root
    echo_info "Starting uninstallation of LuCI App realsync..."

    echo_info "Stopping and disabling the realsync service..."
    if [ -f /etc/init.d/realsync ]; then
        /etc/init.d/realsync stop
        /etc/init.d/realsync disable
        echo_ok "Service stopped and disabled."
    else
        echo_warn "Service script not found, skipping."
    fi

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

    echo_info "Cleaning LuCI cache..."
    rm -f /tmp/luci-indexcache
    echo_ok "LuCI cache cleared."

    echo_info "=================================================================="
    echo_ok "Uninstallation complete!"
    echo_info "=================================================================="
}

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