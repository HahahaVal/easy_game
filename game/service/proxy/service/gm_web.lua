local Monitor = require "monitor_api"

local M = {}

function M.hello(now)
    print("hello: ", now)
    return true
end

function M.shutdown(now)
    Monitor.shutdown()
end

return M