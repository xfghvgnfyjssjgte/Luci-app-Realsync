#!/bin/sh

# 包含 OpenWrt 的函数库
. /lib/functions.sh

# 第一个参数是任务的 section 名
TASK_SECTION="$1"
LOG_FILE="/var/log/realsync.log"
MAX_LOG_SIZE=10485760 # 10MB

# 检查任务名是否为空
if [ -z "$TASK_SECTION" ]; then
    echo "错误：未提供任务名称。" >&2
    exit 1
fi

# 日志函数
log() {
    local level="$1"
    shift
    local msg="$*"
    # procd 会处理时间戳，但我们为了日志格式统一，依然自己加
    echo "[$(date '+%F %T')] [$level] [$TASK_SECTION] $msg" >> "$LOG_FILE"
	# 检查日志文件大小并执行轮转
    [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -ge $MAX_LOG_SIZE ] && {
        mv "$LOG_FILE" "$LOG_FILE.1"
        touch "$LOG_FILE"
    }
}

# --- 开始执行任务 ---

log "info" "任务进程启动。"

# 加载 realsync 配置文件
config_load realsync

# 读取配置项
config_get enabled "$TASK_SECTION" enabled
config_get source_dir "$TASK_SECTION" source_dir
config_get dest_dir "$TASK_SECTION" dest_dir
config_get delete_files "$TASK_SECTION" delete_files

# 如果任务在配置中被禁用，则记录日志并退出
if [ "$enabled" != "1" ]; then
    log "info" "任务在配置中被禁用，正常退出。"
    exit 0
fi

# 检查源目录是否存在
if [ ! -d "$source_dir" ]; then
    log "error" "源目录 '$source_dir' 不存在，任务无法启动。"
    exit 1
fi

# 确保目标目录存在
mkdir -p "$dest_dir" 2>/dev/null

# --- 执行首次同步 ---
log "info" "执行首次全量同步: $source_dir -> $dest_dir"
RSYNC_OPTS="-av"
[ "$delete_files" = "1" ] && RSYNC_OPTS="$RSYNC_OPTS --delete"

rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/"
if [ $? -eq 0 ]; then
    log "info" "首次同步成功。"
else
    log "warn" "首次同步可能存在问题，请检查 rsync 输出。"
fi

# --- 启动循环监控 ---
log "info" "启动 inotifywait 持续监控目录: $source_dir"

# -m: monitor, 持续监控
# -q: quiet, 只输出事件信息
# -e ...: 指定监控的事件类型
inotifywait -m -q -r -e modify,create,delete,move "$source_dir" | while read path event file; do
    log "info" "检测到变更: $path$file ($event)，准备同步。"
    
    # 执行 rsync 同步
    rsync_output=$(rsync $RSYNC_OPTS "$source_dir/" "$dest_dir/" 2>&1)
    rsync_ret=$?
    
    if [ $rsync_ret -eq 0 ]; then
        log "info" "同步完成。"
    else
        log "error" "同步失败！rsync 返回码: $rsync_ret. 错误信息: $rsync_output"
    fi
done

log "warn" "inotifywait 循环意外退出，任务进程结束。procd 将在稍后重启此任务。"

exit 0