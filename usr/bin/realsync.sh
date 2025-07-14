#!/bin/sh

. /lib/functions.sh

TASK_SECTION="$1"
LOG_FILE="/var/log/realsync.log"
MAX_LOG_SIZE=10485760

if [ -z "$TASK_SECTION" ]; then
    echo "错误：未提供任务名称。" >&2
    exit 1
fi

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp=$(date '+%F %T')
    
    case "$level" in
        "info")
            echo "[$timestamp] [INFO] [$TASK_SECTION] $msg" >> "$LOG_FILE"
            ;;
        "success")
            echo "[$timestamp] [SUCCESS] [$TASK_SECTION] $msg" >> "$LOG_FILE"
            ;;
        "warn")
            echo "[$timestamp] [WARN] [$TASK_SECTION] $msg" >> "$LOG_FILE"
            ;;
        "error")
            echo "[$timestamp] [ERROR] [$TASK_SECTION] $msg" >> "$LOG_FILE"
            ;;
    esac
    
    [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $MAX_LOG_SIZE ] && {
        mv "$LOG_FILE" "$LOG_FILE.1"
        touch "$LOG_FILE"
        log "info" "日志文件已轮转"
    }
}


config_load realsync

config_get enabled "$TASK_SECTION" enabled
config_get source_dir "$TASK_SECTION" source_dir
config_get dest_dir "$TASK_SECTION" dest_dir
config_get delete_files "$TASK_SECTION" delete_files
config_get task_name "$TASK_SECTION" task_name

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


RSYNC_OPTS="-av"
[ "$delete_files" = "1" ] && RSYNC_OPTS="$RSYNC_OPTS --delete"

rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
rsync_ret=$?

if [ $rsync_ret -eq 0 ]; then
    log "success" "重启后首次同步完成: $source_dir → $dest_dir"
else
    log "error" "重启后首次同步失败 (返回码: $rsync_ret)"

fi

log "info" "启动实时监控: $source_dir → $dest_dir (监控事件: 文件修改、创建、删除、移动)"

inotifywait -m -q -r -e modify,create,delete,move "$source_dir" | while read path event file; do
    local file_path="${path}${file}"
    
    case "$event" in
        "MODIFY")
            log "info" "检测到文件修改: $file_path"
            ;;
        "CREATE")
            log "info" "检测到文件创建: $file_path"
            ;;
        "DELETE")
            log "info" "检测到文件删除: $file_path"
            ;;
        "MOVED_FROM")
            log "info" "检测到文件移动: $file_path (移出)"
            ;;
        "MOVED_TO")
            log "info" "检测到文件移动: $file_path (移入)"
            ;;
        *)
            log "info" "检测到文件变更: $file_path ($event)"
            ;;
    esac
    
    
    rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
    rsync_ret=$?
    
    if [ $rsync_ret -eq 0 ]; then
        log "success" "同步完成: $source_dir → $dest_dir"
    else
        log "error" "同步失败 (返回码: $rsync_ret)"
        log "error" "错误详情: $rsync_output"
    fi
done

log "warn" "监控进程意外退出,如果强制重启仍无法拉起任务，请重启路由器"


exit 0