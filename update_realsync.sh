#!/bin/sh

# =============================================================================
#        LuCI App for realsync - Update Script
# =============================================================================
#  Run this script from the root of the repository on your OpenWrt device.
#  Usage: ./update_realsync.sh
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

# Check if realsync is installed
check_installed() {
    if [ ! -f /etc/init.d/realsync ]; then
        echo_error "realsync is not installed. Please run install_realsync.sh first."
        exit 1
    fi
}

# Backup current configuration
backup_config() {
    echo_info "Backing up current configuration..."
    if [ -f /etc/config/realsync ]; then
        cp /etc/config/realsync /etc/config/realsync.backup.$(date +%Y%m%d_%H%M%S)
        echo_ok "Configuration backed up to /etc/config/realsync.backup.$(date +%Y%m%d_%H%M%S)"
    else
        echo_warn "No existing configuration found to backup."
    fi
}

# Stop the service before update
stop_service() {
    echo_info "Stopping realsync service..."
    if [ -f /etc/init.d/realsync ]; then
        /etc/init.d/realsync stop
        echo_ok "Service stopped."
    else
        echo_warn "Service script not found, skipping stop."
    fi
}

# Update application files
update_files() {
    echo_info "Updating application files..."
    
    # Update LuCI files
    if [ -d ./usr/lib/lua/luci ]; then
        cp -r ./usr/lib/lua/luci/* /usr/lib/lua/luci/
        if [ $? -eq 0 ]; then
            echo_ok "LuCI files updated."
        else
            echo_error "Failed to update LuCI files."
            return 1
        fi
    fi
    
    # Update scripts and binaries
    if [ -d ./usr/bin ]; then
        cp -r ./usr/bin/* /usr/bin/
        if [ $? -eq 0 ]; then
            echo_ok "Scripts updated."
        else
            echo_error "Failed to update scripts."
            return 1
        fi
    fi
    
    # Update init.d scripts
    if [ -d ./etc/init.d ]; then
        cp -r ./etc/init.d/* /etc/init.d/
        if [ $? -eq 0 ]; then
            echo_ok "Init.d scripts updated."
        else
            echo_error "Failed to update init.d scripts."
            return 1
        fi
    fi
    
    # Update ACL files
    if [ -d ./usr/share/rpcd ]; then
        cp -r ./usr/share/rpcd/* /usr/share/rpcd/
        if [ $? -eq 0 ]; then
            echo_ok "ACL files updated."
        else
            echo_error "Failed to update ACL files."
            return 1
        fi
    fi
    
    return 0
}

# Set permissions
set_permissions() {
    echo_info "Setting executable permissions..."
    chmod +x /etc/init.d/realsync
    chmod +x /usr/bin/realsync.sh
    echo_ok "Permissions set."
}

# Clean LuCI cache
clean_cache() {
    echo_info "Cleaning LuCI cache..."
    rm -f /tmp/luci-indexcache
    echo_ok "LuCI cache cleared."
}

# Restart uhttpd for LuCI interface
restart_uhttpd() {
    echo_info "Restarting uhttpd service for LuCI interface..."
    if [ -f /etc/init.d/uhttpd ]; then
        /etc/init.d/uhttpd restart
        echo_ok "uhttpd service restarted."
    else
        echo_warn "uhttpd service not found, LuCI interface may not display properly."
    fi
}

# Start the service after update
start_service() {
    echo_info "Starting realsync service..."
    if [ -f /etc/init.d/realsync ]; then
        /etc/init.d/realsync start
        echo_ok "Service started."
    else
        echo_error "Service script not found, cannot start service."
        return 1
    fi
}

# Main update function
update_app() {
    check_root
    check_installed
    
    echo_info "Starting update of LuCI App realsync..."
    
    # Backup configuration
    backup_config
    
    # Stop service
    stop_service
    
    # Update files
    if update_files; then
        echo_ok "All files updated successfully."
    else
        echo_error "Update failed. Please check the errors above."
        exit 1
    fi
    
    # Set permissions
    set_permissions
    
    # Clean cache
    clean_cache
    
    # Restart uhttpd
    restart_uhttpd
    
    # Start service
    start_service
    
    echo_info "=================================================================="
    echo_ok "Update complete!"
    echo_info "Your configuration has been preserved."
    echo_info "Please navigate to 服务 -> realsync 在 LuCI 进行配置。"
    echo_info "=================================================================="
    exit 0
}

# Show help
show_help() {
    echo_info "LuCI App realsync Update Script"
    echo_info "Usage: ./update_realsync.sh [options]"
    echo_info ""
    echo_info "Options:"
    echo_info "  -h, --help     Show this help message"
    echo_info "  -f, --force    Force update even if not installed"
    echo_info ""
    echo_info "This script will:"
    echo_info "  1. Backup your current configuration"
    echo_info "  2. Stop the realsync service"
    echo_info "  3. Update all application files (except config)"
    echo_info "  4. Restart the service"
    echo_info "  5. Restart uhttpd for LuCI interface"
}

# Main logic
case "$1" in
    -h|--help)
        show_help
        exit 0
        ;;
    -f|--force)
        # Skip installation check for force update
        check_root
        echo_warn "Force update mode - skipping installation check"
        update_app
        ;;
    "")
        update_app
        ;;
    *)
        echo_error "Invalid option: $1"
        show_help
        exit 1
        ;;
esac 