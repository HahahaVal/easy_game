local Log = require "log_api"
local Skynet = require "znet"

local M = {}

function M.hello(role,client_time)
    Log.info("hello roleid:%d, client_time:%d",role.roleid,client_time)
    local now = Skynet.now()
    return {server_time = now}
end

return M
