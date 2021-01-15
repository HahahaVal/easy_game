local Skynet = require "skynet"
local Env = require "global"

local M = {}

function M.leave_game(uid)
    Env.users:kick(uid)
end

return M