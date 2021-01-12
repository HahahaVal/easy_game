local Monitor = require "monitor_api"
local Log = require "log_api"

local M = {}

function M.hello(now)
    Log.info("hello:%d", now)
    return true
end

function M.shutdown(now)
    Monitor.shutdown()
end

return M