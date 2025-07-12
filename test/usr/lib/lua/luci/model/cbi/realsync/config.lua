local m, s, o
local fs = require "nixio.fs"

m = Map("realsync", "realsync 配置管理", "管理数据同步任务的配置")

s = m:section(TypedSection, "globals", "全局设置")
s.anonymous = true
s.addremove = false

o = s:option(ListValue, "log_level", "日志级别")
o:value("debug", "调试")
o:value("info", "信息")
o:value("warn", "警告")
o:value("error", "错误")
o.default = "info"

s = m:section(TypedSection, "task", "同步任务")
s.anonymous = false
s.addremove = true
s.template = "cbi/tblsection"

o = s:option(Flag, "enabled", "启用")
o.default = 1

o = s:option(Value, "task_name", "任务名称")
o.rmempty = false

o = s:option(Value, "source_dir", "源目录")
o.datatype = "directory"
o.rmempty = false
function o.validate(self, value, section)
    local fs = require "nixio.fs"
    local logf = io.open("/tmp/luci_realsync_debug.log", "a+")
    if logf then
        logf:write(os.date("%F %T "), "source_dir 校验: ", value, "\n")
        if not fs.stat(value, "type") then
            logf:write(os.date("%F %T "), "目录不存在: ", value, "\n")
            logf:close()
            return nil, "目录不存在: " .. value
        end
        logf:write(os.date("%F %T "), "目录存在: ", value, "\n")
        logf:close()
    end
    return value
end

o = s:option(Value, "dest_dir", "目标目录")
o.datatype = "directory"
o.rmempty = false
function o.validate(self, value, section)
    local fs = require "nixio.fs"
    local logf = io.open("/tmp/luci_realsync_debug.log", "a+")
    if logf then
        logf:write(os.date("%F %T "), "dest_dir 校验: ", value, "\n")
        if not fs.stat(value, "type") then
            logf:write(os.date("%F %T "), "目录不存在: ", value, "\n")
            logf:close()
            return nil, "目录不存在: " .. value
        end
        logf:write(os.date("%F %T "), "目录存在: ", value, "\n")
        logf:close()
    end
    return value
end

o = s:option(Value, "delay_seconds", "延迟秒数")
o.datatype = "uinteger"
o.default = "5"

o = s:option(Flag, "delete_files", "同步删除源文件")
o.default = 0

function m.on_after_commit(self)
    local old = nixio.fs.readfile("/etc/config/realsync")
    os.execute("uci commit realsync")
    os.execute("sync")
    for i=1, 50 do
        os.execute("sleep 0.1")
        local now = nixio.fs.readfile("/etc/config/realsync")
        if now ~= old then break end
    end
    os.execute("uci reload_config")  -- 新增，强制刷新UCI类型缓存
    os.execute("sleep 1")
    os.execute("(sleep 2; /etc/init.d/realsync restart) &")
end

return m
