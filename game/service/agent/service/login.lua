local HallApi = require "hall_api"
local Skynet = require "znet"

local M = {}

function M.leave_game(role)
    local now = Skynet.time()
    role:set_last_login_time(now)
    local uid = role:get_uid()
    HallApi.leave_game(uid)
end


return M