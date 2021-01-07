local Skynet = require "znet"

local mt = {}
mt.__index = mt

function mt:send(...)
    Skynet.send(self.service, self.proto, ...)
end

function mt:call(...)
    return Skynet.call(self.service, self.proto, ...)
end

local M = {}
function M.new(service, proto)
    local obj = {}
    obj.service = service
    obj.proto   = proto
    return setmetatable(obj, mt)
end

return M

