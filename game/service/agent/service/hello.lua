local Log = require "log_api"
local Date = require "date"

local M = {}

function M.hello(role,client_time)
    local now = tostring(Date.time())
    Log.info("hello roleid:%d, client_time:%d, server_time:%s",role:get_roleid(),client_time,now)
    return {server_time = now}
end

return M
