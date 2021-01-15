local Sys        = require "sys"
local ServiceObj = require "service"
local Skynet = require "znet"

local service

local M = {}

function M.register(catalog, cb)
    Sys.atexit(cb)
    local ok = service:call("register", Skynet.self(), catalog)
    assert(ok, catalog)
    return ok
end

function M.shutdown()
    service:send("shutdown")
end

Skynet.init(function()
	local addr = Skynet.queryservice(true, "monitor")
    service = ServiceObj.new(addr, "lua")
end, "monitor_api")

return M