#!/bin/sh

# realsync 升级脚本
# 用于更新已安装的 realsync 应用到最新版本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 超时函数
timeout_cmd() {
    local timeout="$1"
    shift
    local cmd="$@"
    
    # 使用timeout命令（如果可用）
    if command -v timeout >/dev/null 2>&1; then
        timeout "$timeout" $cmd
    else
        # 备用方案：使用perl实现超时
        perl -e "
            eval {
                local \$SIG{ALRM} = sub { die \"timeout\" };
                alarm $timeout;
                system(@ARGV);
                alarm 0;
            };
            if (\$@) {
                exit 1;
            }
        " $cmd
    fi
}

# 检查是否以root权限运行
check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 备份配置
backup_config() {
    log_info "备份当前配置..."
    local backup_file="/etc/config/realsync.backup.$(date +%Y%m%d_%H%M%S)"
    if [ -f "/etc/config/realsync" ]; then
        cp "/etc/config/realsync" "$backup_file"
        log_success "配置已备份到 $backup_file"
    else
        log_warning "配置文件不存在，跳过备份"
    fi
}

# 停止服务（带超时）
stop_service() {
    log_info "停止 realsync 服务..."
    
    # 设置超时时间（秒）
    local timeout=30
    
    # 尝试停止服务
    if timeout_cmd "$timeout" /etc/init.d/realsync stop; then
        log_success "服务已停止"
    else
        log_warning "服务停止超时，尝试强制停止..."
        
        # 强制停止所有相关进程
        if command -v killall >/dev/null 2>&1; then
            killall -9 realsync.sh 2>/dev/null || true
        fi
        
        if command -v pkill >/dev/null 2>&1; then
            pkill -9 -f "realsync.sh" 2>/dev/null || true
        fi
        
        # 清理PID文件
        rm -f /var/run/realsync/*.pid 2>/dev/null || true
        
        log_success "强制停止完成"
    fi
    
    # 等待一下确保进程完全退出
    sleep 2
}

# 更新文件
update_files() {
    log_info "更新应用文件..."
    
    # 创建必要的目录
    mkdir -p /usr/bin
    mkdir -p /usr/lib/lua/luci/controller
    mkdir -p /usr/lib/lua/luci/model/cbi/realsync
    mkdir -p /usr/lib/lua/luci/view/realsync
    mkdir -p /usr/share/rpcd/acl.d
    mkdir -p /etc/init.d
    
    # 复制文件（不覆盖配置文件）
    if [ -f "usr/bin/realsync.sh" ]; then
        cp usr/bin/realsync.sh /usr/bin/
        chmod +x /usr/bin/realsync.sh
    fi
    
    if [ -f "etc/init.d/realsync" ]; then
        cp etc/init.d/realsync /etc/init.d/
        chmod +x /etc/init.d/realsync
    fi
    
    if [ -d "usr/lib/lua/luci" ]; then
        cp -r usr/lib/lua/luci/* /usr/lib/lua/luci/
    fi
    
    if [ -f "usr/share/rpcd/acl.d/luci-app-realsync.json" ]; then
        cp usr/share/rpcd/acl.d/luci-app-realsync.json /usr/share/rpcd/acl.d/
    fi
    
    log_success "文件更新完成"
}

# 重启服务
restart_service() {
    log_info "重启 realsync 服务..."
    
    # 设置超时时间（秒）
    local timeout=30
    
    if timeout_cmd "$timeout" /etc/init.d/realsync start; then
        log_success "服务已启动"
    else
        log_warning "服务启动超时，但可能仍在后台运行"
    fi
}

# 重启uhttpd
restart_uhttpd() {
    log_info "重启 uhttpd 服务..."
    
    # 设置超时时间（秒）
    local timeout=30
    
    if timeout_cmd "$timeout" /etc/init.d/uhttpd restart; then
        log_success "uhttpd 已重启"
    else
        log_warning "uhttpd 重启超时，但可能仍在运行"
    fi
}

# 主函数
main() {
    log_info "开始升级 LuCI App realsync..."
    
    # 检查root权限
    check_root
    
    # 备份配置
    backup_config
    
    # 停止服务
    stop_service
    
    # 更新文件
    update_files
    
    # 重启服务
    restart_service
    
    # 重启uhttpd
    restart_uhttpd
    
    log_success "升级完成！"
    log_info "请登录 LuCI 界面检查服务状态"
    log_info "配置文件已备份，如需恢复请查看备份文件"
}

# 执行主函数
main "$@" 