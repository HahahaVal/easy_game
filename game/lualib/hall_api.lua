local Skynet     = require "znet"
local Service = require "service"

local service

local M = {}

function M.leave_game(...)
    service:send("leave_game", ...)
end

Skynet.init(function()
	local addr = Skynet.queryservice("hall")
    service = Service.new(addr, "lua")
end, "hall_api")

return M