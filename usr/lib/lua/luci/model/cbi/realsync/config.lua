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
function o.validate(self, value, section)
    if not value or tostring(value):match("^%s*$") then
        return nil, "任务名称不能为空"
    end
    -- 检查唯一性
    local uci = require "luci.model.uci".cursor()
    local found = false
    uci:foreach("realsync", "task", function(s)
        if s.task_name == value and s[".name"] ~= section then
            found = true
        end
    end)
    if found then
        return nil, "任务名称必须唯一，已存在同名任务"
    end
    return value
end

o = s:option(Value, "source_dir", "源目录")
o.datatype = "directory"
o.rmempty = false
function o.validate(self, value, section)
    local fs = require "nixio.fs"
    if not value or tostring(value):match("^%s*$") then
        return nil, "源目录不能为空"
    end
    if not fs.stat(value, "type") then
        return nil, "源目录不存在: " .. tostring(value or "")
    end
    return value
end

o = s:option(Value, "dest_dir", "目标目录")
o.datatype = "directory"
o.rmempty = false
function o.validate(self, value, section)
    local fs = require "nixio.fs"
    if not value or tostring(value):match("^%s*$") then
        return nil, "目标目录不能为空"
    end
    if not fs.stat(value, "type") then
        return nil, "目标目录不存在: " .. tostring(value or "")
    end
    return value
end

o = s:option(Value, "delay_seconds", "延迟秒数")
o.datatype = "uinteger"
o.default = "5"
function o.validate(self, value, section)
    if not value or tostring(value):match("^%s*$") then
        return nil, "延迟秒数不能为空"
    end
    if not tostring(value):match("^%d+$") then
        return nil, "延迟秒数必须为正整数"
    end
    return value
end

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
    os.execute("uci reload_config")
    os.execute("sleep 1")
    os.execute("(sleep 2; /etc/init.d/realsync restart) &")
end

return m
