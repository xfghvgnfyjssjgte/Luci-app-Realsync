local m, s

m = Map("realsync", "realsync 状态信息", "查看服务运行状态和日志信息")
m.pageaction = false

s = m:section(SimpleSection, "状态信息")
s.template = "realsync/status"

return m
