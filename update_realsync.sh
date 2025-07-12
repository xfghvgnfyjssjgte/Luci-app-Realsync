#!/bin/sh

# realsync 升级脚本 - 简化版
# 只复制文件并重启服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}[ERROR]${NC} 此脚本需要root权限运行"
        exit 1
    fi
}

# 复制文件
copy_files() {
    log_info "复制应用文件..."
    
    # 复制脚本文件
    if [ -f "usr/bin/realsync.sh" ]; then
        cp usr/bin/realsync.sh /usr/bin/
        chmod +x /usr/bin/realsync.sh
    fi
    
    # 复制init.d脚本
    if [ -f "etc/init.d/realsync" ]; then
        cp etc/init.d/realsync /etc/init.d/
        chmod +x /etc/init.d/realsync
    fi
    
    # 复制LuCI文件
    if [ -d "usr/lib/lua/luci" ]; then
        cp -r usr/lib/lua/luci/* /usr/lib/lua/luci/
    fi
    
    # 复制ACL文件
    if [ -f "usr/share/rpcd/acl.d/luci-app-realsync.json" ]; then
        cp usr/share/rpcd/acl.d/luci-app-realsync.json /usr/share/rpcd/acl.d/
    fi
    
    log_success "文件复制完成"
}

# 重启服务
restart_service() {
    log_info "重启 realsync 服务..."
    /etc/init.d/realsync restart
    log_success "服务已重启"
}

# 重启uhttpd
restart_uhttpd() {
    log_info "重启 uhttpd 服务..."
    /etc/init.d/uhttpd restart
    log_success "uhttpd 已重启"
}

# 主函数
main() {
    log_info "开始升级 realsync..."
    
    check_root
    copy_files
    restart_service
    restart_uhttpd
    
    log_success "升级完成！"
}

main "$@" 