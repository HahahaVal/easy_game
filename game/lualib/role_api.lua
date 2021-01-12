local Skynet     = require "znet"
local Service = require "service"

local service

local M = {}

function M.get(...)
    local data = service:call("get", ...)
    if not data then
        return nil
    end
    return data
end

function M.update(uid, role)
    return service:call("update", uid, role)
end

function M.add(obj)
    return service:call("add", obj)
end


Skynet.init(function()
	local db_addr = Skynet.queryservice(true, "role_db")
    service = Service.new(db_addr, "lua")
end, "role_api")

return M