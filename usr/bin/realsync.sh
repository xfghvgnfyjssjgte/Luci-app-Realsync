#!/bin/sh

. /lib/functions.sh

<<<<<<< HEAD
# --- 脚本初始化与参数读取 ---
=======
>>>>>>> 92e6aa9255938f03da2b9210dee8914cf9609341
TASK_SECTION="$1"
LOG_DIR="/var/log/realsync"
LOG_FILE="$LOG_DIR/${TASK_SECTION}.log"
MAX_LOG_SIZE=10485760

if [ -z "$TASK_SECTION" ]; then
    echo "错误：未提供任务名称。" >&2
    exit 1
fi

<<<<<<< HEAD
=======
# 确保日志目录存在
>>>>>>> 92e6aa9255938f03da2b9210dee8914cf9609341
mkdir -p "$LOG_DIR" 2>/dev/null

config_load realsync
config_get enabled "$TASK_SECTION" enabled
config_get source_dir "$TASK_SECTION" source_dir
config_get dest_dir "$TASK_SECTION" dest_dir
config_get delete_files "$TASK_SECTION" delete_files
config_get task_name "$TASK_SECTION" task_name
<<<<<<< HEAD
config_get delay_seconds "$TASK_SECTION" delay_seconds

# --- 日志记录函数定义 ---
log() {
    local level="$1"; shift; local msg="$*"; local timestamp=$(date '+%F %T')
    local tag_name="${task_name:-$TASK_SECTION}"
    echo "[$timestamp] [$level] [$tag_name] $msg" >> "$LOG_FILE"
    [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $MAX_LOG_SIZE ] && {
        mv "$LOG_FILE" "$LOG_FILE.1"; touch "$LOG_FILE"; log "INFO" "日志文件已轮转"
    }
}

# --- 任务执行前的预检查 ---
if [ "$enabled" != "1" ]; then
    log "INFO" "任务在配置中被禁用，正常退出"; exit 0
fi
if [ ! -d "$source_dir" ]; then
    log "ERROR" "源目录不存在: $source_dir"; exit 1
fi
if [ ! -r "$source_dir" ]; then
    log "ERROR" "源目录无读取权限: $source_dir"; exit 1
fi
mkdir -p "$dest_dir" 2>/dev/null
if [ ! -w "$dest_dir" ]; then
    log "ERROR" "目标目录无写入权限: $dest_dir"; exit 1
fi

# --- 同步逻辑 ---
=======

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp=$(date '+%F %T')
    local tag_name="${task_name:-$TASK_SECTION}"
    case "$level" in
        "info")
            echo "[$timestamp] [INFO] [$tag_name] $msg" >> "$LOG_FILE"
            ;;
        "success")
            echo "[$timestamp] [SUCCESS] [$tag_name] $msg" >> "$LOG_FILE"
            ;;
        "warn")
            echo "[$timestamp] [WARN] [$tag_name] $msg" >> "$LOG_FILE"
            ;;
        "error")
            echo "[$timestamp] [ERROR] [$tag_name] $msg" >> "$LOG_FILE"
            ;;
    esac
    [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $MAX_LOG_SIZE ] && {
        mv "$LOG_FILE" "$LOG_FILE.1"
        touch "$LOG_FILE"
        log "info" "日志文件已轮转"
    }
}

if [ "$enabled" != "1" ]; then
    log "info" "任务在配置中被禁用，正常退出"
    exit 0
fi

if [ ! -d "$source_dir" ]; then
    log "error" "源目录不存在: $source_dir"
    exit 1
fi

if [ ! -r "$source_dir" ]; then
    log "error" "源目录无读取权限: $source_dir"
    exit 1
fi

mkdir -p "$dest_dir" 2>/dev/null
if [ ! -w "$dest_dir" ]; then
    log "error" "目标目录无写入权限: $dest_dir"
    exit 1
fi

>>>>>>> 92e6aa9255938f03da2b9210dee8914cf9609341
RSYNC_OPTS="-av"
[ "$delete_files" = "1" ] && RSYNC_OPTS="$RSYNC_OPTS --delete"

# 首次同步
<<<<<<< HEAD
log "INFO" "开始执行首次全量同步"
log "INFO" "同步方向: $source_dir → $dest_dir"
rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
rsync_ret=$?
if [ $rsync_ret -eq 0 ]; then
    log "SUCCESS" "重启后首次同步完成: $source_dir → $dest_dir"
else
    log "ERROR" "重启后首次同步失败 (返回码: $rsync_ret)"
    log "ERROR" "错误详情: $rsync_output"
fi

# 根据 delay_seconds 的值选择同步模式
if [ -n "$delay_seconds" ] && [ "$delay_seconds" -gt 0 ]; then
    
    # --- 定时同步模式 ---
    if [ "$delete_files" = "1" ]; then
        log "INFO" "启动定时同步模式，周期: ${delay_seconds}秒，同步删除: 是"
    else
        log "INFO" "启动定时同步模式，周期: ${delay_seconds}秒，同步删除: 否"
=======
log "info" "开始执行首次全量同步"
log "info" "同步方向: $source_dir → $dest_dir"
rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
rsync_ret=$?
if [ $rsync_ret -eq 0 ]; then
    log "success" "重启后首次同步完成: $source_dir → $dest_dir"
else
    log "error" "重启后首次同步失败 (返回码: $rsync_ret)"
    log "error" "错误详情: $rsync_output"
fi

if [ "$delete_files" = "1" ]; then
    log "info" "启动实时监控: $source_dir → $dest_dir (监控事件: 文件修改、创建、删除、移动)"
else
    log "info" "启动实时监控: $source_dir → $dest_dir (监控事件: 文件修改、创建、移动)"
fi

inotifywait -m -q -r -e modify,create,delete,move "$source_dir" | while read path event file; do
    file_path="${path}${file}"
    dest_file_path="${dest_dir}/${file}"  # 目标文件路径
    case "$event" in
        "MODIFY")
            log "info" "检测到源文件修改: $file_path"
            ;;
        "CREATE")
            log "info" "检测到源文件创建: $file_path"
            ;;
        "DELETE")
            log "info" "检测到源文件删除: $file_path"
            ;;
        "MOVED_FROM")
            log "info" "检测到源文件移动(移出): $file_path"
            ;;
        "MOVED_TO")
            log "info" "检测到源文件移动(移入): $file_path"
            ;;
        *)
            log "info" "检测到源文件变更($event): $file_path"
            ;;
    esac
    rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
    rsync_ret=$?
    if [ $rsync_ret -eq 0 ]; then
        log "success" "目标文件同步完成: $file_path → $dest_file_path"
    else
        log "error" "目标文件同步失败: $file_path → $dest_file_path (返回码: $rsync_ret)"
        log "error" "错误详情: $rsync_output"
>>>>>>> 92e6aa9255938f03da2b9210dee8914cf9609341
    fi
    
    while true; do
        sleep "$delay_seconds"
        log "INFO" "定时时间到达，开始执行同步"
        rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
        rsync_ret=$?
        if [ $rsync_ret -eq 0 ]; then
            log "SUCCESS" "定时同步完成"
        else
            log "ERROR" "定时同步失败 (返回码: $rsync_ret)"
            log "ERROR" "错误详情: $rsync_output"
        fi
    done

<<<<<<< HEAD
else
    
    # --- 实时同步模式 ---
    if [ "$delete_files" = "1" ]; then
        log "INFO" "启动实时监控模式，同步删除: 是"
    else
        log "INFO" "启动实时监控模式，同步删除: 否"
    fi
=======
log "warn" "监控进程意外退出,如果强制重启仍无法拉起任务，请重启路由器"
>>>>>>> 92e6aa9255938f03da2b9210dee8914cf9609341

    inotifywait -m -q -r -e modify,create,delete,move "$source_dir" | while read path event file; do
        log "INFO" "检测到变更($event): ${path}${file}"
        rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
        rsync_ret=$?
        if [ $rsync_ret -eq 0 ]; then
            log "SUCCESS" "文件同步完成"
        else
            log "ERROR" "文件同步失败 (返回码: $rsync_ret)"
            log "ERROR" "错误详情: $rsync_output"
        fi
    done
fi

log "WARN" "监控进程意外退出"
exit 0