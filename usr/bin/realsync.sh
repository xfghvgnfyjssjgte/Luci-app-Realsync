#!/bin/sh

. /lib/functions.sh

TASK_SECTION="$1"
CONFIG_FILE="/etc/config/realsync"
LOG_FILE="/var/log/realsync.log"
LOG_LEVEL="info" # 可通过 UCI 配置覆盖
MAX_LOG_SIZE=10485760 # 10MB
PID_DIR="/var/run/realsync"

config_load realsync

config_get enabled "$TASK_SECTION" enabled
config_get task_name "$TASK_SECTION" task_name
config_get source_dir "$TASK_SECTION" source_dir
config_get dest_dir "$TASK_SECTION" dest_dir
config_get rsync_options "$TASK_SECTION" rsync_options
config_get delete_files "$TASK_SECTION" delete_files
config_get delay_seconds "$TASK_SECTION" delay_seconds

log() {
    local level="$1"
    shift
    local msg="$*"
    [ "$level" = "debug" ] && [ "$LOG_LEVEL" != "debug" ] && return
    echo "[$(date '+%F %T')] [$level] [${task_name:-$TASK_SECTION}] $msg" >> "$LOG_FILE"
    log_rotate
}

log_rotate() {
    [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $MAX_LOG_SIZE ] && {
        mv "$LOG_FILE" "$LOG_FILE.1"
        touch "$LOG_FILE"
    }
}

clear_log() {
    ：> "$LOG_FILE"
    log info "日志已被清空"
}

if [ "$enabled" != "1" ]; then
    log "任务 $task_name 未启用，退出"
    exit 0
fi

if [ ! -d "$source_dir" ]; then
    log "错误: 源目录 $source_dir 不存在"
    exit 1
fi

mkdir -p "$dest_dir" 2>/dev/null
mkdir -p "$PID_DIR"

log info "启动 inotifywait 监控: $source_dir -> $dest_dir"

# 读取 delete_files 配置
config_get delete_files "$TASK_SECTION" delete_files

inotifywait -mrq -e modify,create,delete "$source_dir" | while read event; do
    log info "检测到文件变动: $event"
    log debug "准备执行 rsync 同步: $source_dir -> $dest_dir"
    RSYNC_OPTS="-av"
    [ "$delete_files" = "1" ] && RSYNC_OPTS="$RSYNC_OPTS --delete"
    rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
    rsync_ret=$?
    if [ $rsync_ret -eq 0 ]; then
        log info "同步完成: $source_dir -> $dest_dir"
        log debug "rsync 输出: $rsync_output"
    else
        log info "同步失败: $source_dir -> $dest_dir"
        log debug "rsync 错误输出: $rsync_output"
    fi
done

log info "任务xxx启动"
log debug "详细调试信息"
log info "任务xxx同步完成"
log info "任务xxx停止"

case "$1" in
    clearlog)
        clear_log
        exit 0
        ;;
    reload)
        reload_tasks
        exit 0
        ;;
    # ... 其他命令 ...
esac

start_task() {
    local task_id="$1"
    # 读取任务配置
    config_load realsync
    config_get source_dir "$task_id" source_dir
    config_get dest_dir "$task_id" dest_dir

    # 检查目录是否存在
    if [ ! -d "$source_dir" ]; then
        log info "任务 $task_id 启动失败：源目录 $source_dir 不存在"
        return 1
    fi
    if [ ! -d "$dest_dir" ]; then
        log info "任务 $task_id 启动失败：目标目录 $dest_dir 不存在"
        return 1
    fi

    # 启动任务命令（示例，需替换为实际任务启动命令）
    /usr/bin/realsync_task --id "$task_id" &
    echo $! > "$PID_DIR/$task_id.pid"
    log info "任务 $task_id 启动，PID: $(cat $PID_DIR/$task_id.pid)"
}

stop_task() {
    local task_id="$1"
    local pid_file="$PID_DIR/$task_id.pid"
    if [ -f "$pid_file" ]; then
        kill $(cat "$pid_file") 2>/dev/null
        rm -f "$pid_file"
        log info "任务 $task_id 已停止"
    fi
}

reload_tasks() {
    config_load realsync
    config_foreach handle_task task
}

handle_task() {
    local section="$1"
    config_get enabled "$section" enabled
    config_get task_id "$section" task_id
    [ -z "$task_id" ] && task_id="$section"
    if [ "$enabled" = "1" ]; then
        # 检查进程是否已存在，未启动则启动
        local pid_file="$PID_DIR/$task_id.pid"
        if [ ! -f "$pid_file" ] || ! kill -0 $(cat "$pid_file") 2>/dev/null; then
            start_task "$task_id"
        fi
    else
        stop_task "$task_id"
    fi
    config_get delete_files "$section" delete_files
}

reload() {
    /usr/bin/realsync.sh reload
}
