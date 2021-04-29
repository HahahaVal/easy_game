local Skynet     = require "znet"
local Service = require "service"

local service

local function get_service()
    if not service then
        local addr = Skynet.queryservice("hall")
        service = Service.new(addr, "lua")
    end
    return service
end

local M = {}

function M.leave_game(...)
    get_service():send("leave_game", ...)
end

return M