local Skynet = require "znet"
local ServiceObj = require "service"

local log = {}
local service

local LOG_LEVEL = {
    DEBUG   = 1,
    INFO    = 2, 
    ERROR   = 3, 
}

local OUT_PUT_LEVEL = LOG_LEVEL.DEBUG

local LOG_LEVEL_DESC = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "ERROR",
}

local function _format(fmt, ...)
    local ok, str = pcall(string.format, fmt, ...)
    if ok then
        return str
    else
        return "error format : " .. fmt
    end
end

local function send_log(level, ...)
    if level < OUT_PUT_LEVEL then
        return
    end

    local str
    if select("#", ...) == 1 then
        str = tostring(...)
    else
        str = _format(...)
    end
    --根据函数信息表得到调用栈
    local info = debug.getinfo(3)
	if info then
		str = string.format("[%s:%d] %s", info.short_src, info.currentline, str)
    end
    
    service:send("logging", LOG_LEVEL_DESC[level], str)
end

function log.debug(fmt, ...)
    send_log(LOG_LEVEL.DEBUG, fmt, ...)
end

function log.info(fmt, ...)
    send_log(LOG_LEVEL.INFO, fmt, ...)
end

function log.error(fmt, ...)
    send_log(LOG_LEVEL.ERROR, fmt, ...)
end


Skynet.init(function()
	local addr = Skynet.queryservice("logger")
    service = ServiceObj.new(addr, "lua")
end, "logger")


return log