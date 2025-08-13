module("luci.controller.realsync", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/realsync") then
		return
	end

	local page
	
	page = entry({"admin", "services", "realsync"}, alias("admin", "services", "realsync", "config"), _("realsync 数据同步"), 50)
	page.dependent = true
	page.acl_depends = { "luci-app-realsync" }
	
	entry({"admin", "services", "realsync", "config"}, cbi("realsync/config"), _("配置信息"), 10).leaf = true
	entry({"admin", "services", "realsync", "status"}, cbi("realsync/status"), _("状态信息"), 20).leaf = true
	
	entry({"admin", "services", "realsync", "get_status"}, call("action_get_status")).leaf = true
	entry({"admin", "services", "realsync", "restart_service"}, call("action_restart_service")).leaf = true
	entry({"admin", "services", "realsync", "get_log"}, call("action_get_log")).leaf = true
	entry({"admin", "services", "realsync", "clear_log"}, call("action_clear_log")).leaf = true
	entry({"admin", "services", "realsync", "get_task_list"}, call("action_get_task_list")).leaf = true
	entry({"admin", "services", "realsync", "get_task_log"}, call("action_get_task_log")).leaf = true
	entry({"admin", "services", "realsync", "clear_task_log"}, call("action_clear_task_log")).leaf = true
end

local function is_running()
	return luci.sys.call("ps | grep -v grep | grep realsync >/dev/null") == 0
end

local function get_service_status()
	if is_running() then
		return "运行中"
	else
		return "未启动"
	end
end

function action_get_status()
    local uci = require "luci.model.uci".cursor()
    local tasks = {}
    uci:foreach("realsync", "task", function(s)
        local t = {
            name = s.task_name or s['.name'],
            section = s['.name'],
            enable = (s.enabled == "1"),
            status = "未知"
        }
        local handle = io.popen("ps | grep '[r]ealsync.sh " .. s['.name'] .. "'")
        local output = handle:read("*a")
        handle:close()
        if s.enabled == "1" then
            if output and #output > 0 then
                t.status = "运行中"
            else
                t.status = "未启动"
            end
        else
            t.status = "未启用"
        end
        table.insert(tasks, t)
    end)
    luci.http.prepare_content("application/json")
    luci.http.write_json({status="运行中", tasks=tasks})
end

function action_restart_service()
	luci.sys.exec("export PATH=/usr/sbin:/usr/bin:/sbin:/bin:$PATH; /etc/init.d/realsync restart")
	luci.http.prepare_content("application/json")
	luci.http.write_json({success = true, message = "服务重启命令已执行"})
end

function action_get_log()
	local log_content = ""
	if nixio.fs.access("/var/log/realsync.log") then
		log_content = luci.sys.exec("tail -n 100 /var/log/realsync.log 2>/dev/null")
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({log = log_content})
end

function action_clear_log()
    local success = false
    
    if luci.sys.call("echo '' > /var/log/realsync.log") == 0 then
        success = true
    end
    
    if not success and luci.sys.call("truncate -s 0 /var/log/realsync.log") == 0 then
        success = true
    end
    
    if not success then
        local f = io.open("/var/log/realsync.log", "w")
        if f then
            f:write("")
            f:close()
            success = true
        end
    end
    
    luci.http.prepare_content("application/json")
    if success then
        luci.http.write_json({success = true, message = "日志已清空"})
    else
        luci.http.write_json({success = false, message = "清空日志失败，请检查文件权限"})
    end
end

function action_get_task_list()
    local uci = require "luci.model.uci".cursor()
    local tasks = {}
    uci:foreach("realsync", "task", function(s)
        local t = {
            section = s['.name'],
            name = s.task_name or s['.name'],
            enabled = (s.enabled == "1"),
            source_dir = s.source_dir or "",
            dest_dir = s.dest_dir or "",
            has_log = nixio.fs.access("/var/log/realsync/" .. s['.name'] .. ".log"),
            status = "未知"
        }
        -- 检查进程状态
        local handle = io.popen("ps | grep '[r]ealsync.sh " .. s['.name'] .. "'")
        local output = handle:read("*a")
        handle:close()
        if s.enabled == "1" then
            if output and #output > 0 then
                t.status = "运行中"
            else
                t.status = "未启动"
            end
        else
            t.status = "未启用"
        end
        table.insert(tasks, t)
    end)
    luci.http.prepare_content("application/json")
    luci.http.write_json({tasks = tasks})
end

function action_get_task_log()
    local task_section = luci.http.formvalue("task")
    local lines = tonumber(luci.http.formvalue("lines")) or 100
    
    if not task_section then
        luci.http.prepare_content("application/json")
        luci.http.write_json({error = "未指定任务名称"})
        return
    end
    
    local log_file = "/var/log/realsync/" .. task_section .. ".log"
    local log_content = ""
    
    if nixio.fs.access(log_file) then
        log_content = luci.sys.exec("tail -n " .. lines .. " " .. log_file .. " 2>/dev/null")
    else
        log_content = "日志文件不存在"
    end
    
    luci.http.prepare_content("application/json")
    luci.http.write_json({log = log_content, task = task_section})
end

function action_clear_task_log()
    local task_section = luci.http.formvalue("task")
    
    if not task_section then
        luci.http.prepare_content("application/json")
        luci.http.write_json({success = false, message = "未指定任务名称"})
        return
    end
    
    local log_file = "/var/log/realsync/" .. task_section .. ".log"
    local success = false
    
    if luci.sys.call("echo '' > " .. log_file) == 0 then
        success = true
    elseif luci.sys.call("truncate -s 0 " .. log_file) == 0 then
        success = true
    else
        local f = io.open(log_file, "w")
        if f then
            f:write("")
            f:close()
            success = true
        end
    end
    
    luci.http.prepare_content("application/json")
    if success then
        luci.http.write_json({success = true, message = "任务日志已清空"})
    else
        luci.http.write_json({success = false, message = "清空任务日志失败"})
    end
end 